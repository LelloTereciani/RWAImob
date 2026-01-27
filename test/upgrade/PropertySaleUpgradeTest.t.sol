// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/contracts/PropertySale.sol";
import "./PropertySaleV2Mock.sol";

contract PropertySaleUpgradeTest is Test {
    PropertySale propertySale;
    ProxyAdmin proxyAdmin;
    TransparentUpgradeableProxy proxy;
    address owner = address(1);
    address buyer = address(2);
    
    function setUp() public {
        PropertySale implementation = new PropertySale();
        bytes memory initData = abi.encodeWithSelector(
            PropertySale.initialize.selector,
            owner
        );
        proxy = new TransparentUpgradeableProxy(
            address(implementation),
            owner,
            initData
        );
        propertySale = PropertySale(address(proxy));

        vm.deal(buyer, 100 ether);
    }

    function testUpgradeStatePreservation() public {
        // 1. Setup initial state
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Initial Location", 1 ether, "ipfs://v1");
        
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        propertySale.buyProperty{value: 1 ether}(id);

        uint256 totalVolumePre = propertySale.totalVolume();
        uint256 transactionCountPre = propertySale.transactionCount();
        (address pOwner, , , , , ) = propertySale.getPropertyDetails(id);

        assertEq(totalVolumePre, 1 ether);
        assertEq(transactionCountPre, 1);
        assertEq(pOwner, buyer);

        // 2. Perform Upgrade
        PropertySaleV2Mock v2Implementation = new PropertySaleV2Mock();
        
        // In OZ v5, TransparentUpgradeableProxy deploys its own ProxyAdmin.
        // The admin address is stored in the ERC-1967 admin slot.
        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        address actualAdmin = address(uint160(uint256(vm.load(address(proxy), adminSlot))));
        ProxyAdmin deployedProxyAdmin = ProxyAdmin(actualAdmin);

        vm.prank(owner);
        deployedProxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)), 
            address(v2Implementation), 
            ""
        );

        // Re-wrap proxy with V2 ABI
        PropertySaleV2Mock propertySaleV2 = PropertySaleV2Mock(address(proxy));

        // 3. Verify State Preservation
        assertEq(propertySaleV2.totalVolume(), totalVolumePre, "Volume should be preserved");
        assertEq(propertySaleV2.transactionCount(), transactionCountPre, "Count should be preserved");
        
        (address pOwnerPost, , bool pForSalePost, , , ) = propertySaleV2.getPropertyDetails(id);
        assertEq(pOwnerPost, buyer, "Owner should be preserved");
        assertEq(pForSalePost, false, "Sold status should be preserved");

        // 4. Verify New Functionality
        vm.prank(owner);
        propertySaleV2.setVersion("2.0.0");
        assertEq(propertySaleV2.version(), "2.0.0");

        assertEq(propertySaleV2.getV2Identifier(), "RWA_V2_MOCK");
    }

    function testUpgradeUnauthorized() public {
        PropertySaleV2Mock v2Implementation = new PropertySaleV2Mock();
        
        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        address actualAdmin = address(uint160(uint256(vm.load(address(proxy), adminSlot))));
        ProxyAdmin deployedProxyAdmin = ProxyAdmin(actualAdmin);

        vm.prank(buyer); // Not the owner
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", buyer));
        deployedProxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)), 
            address(v2Implementation), 
            ""
        );
    }
}
