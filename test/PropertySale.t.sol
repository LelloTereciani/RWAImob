// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/contracts/PropertySale.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract PropertySaleTest is Test {
    PropertySale public propertySale;
    address public owner = address(0x1);
    address public buyer = address(0x2);

    function setUp() public {
        vm.startPrank(owner);
        
        PropertySale implementation = new PropertySale();
        ProxyAdmin proxyAdmin = new ProxyAdmin(owner);
        
        bytes memory initData = abi.encodeWithSelector(
            PropertySale.initialize.selector,
            owner
        );
        
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );
        
        propertySale = PropertySale(address(proxy));
        vm.stopPrank();
    }

    function testListProperty() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Apartamento Legal", 1 ether, "ipfs://uri");
        assertEq(id, 1);
        
        (address pOwner, uint256 price, bool forSale, , , , ) = propertySale.getPropertyDetails(1);
        assertEq(pOwner, owner);
        assertEq(price, 1 ether);
        assertTrue(forSale);
    }

    function testBuyProperty() public {
        vm.prank(owner);
        propertySale.listProperty("Apartamento Legal", 1 ether, "ipfs://uri");

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        propertySale.buyProperty{value: 1 ether}(1);

        (address pOwner, , bool forSale, , , , ) = propertySale.getPropertyDetails(1);
        assertEq(pOwner, buyer);
        assertFalse(forSale);
    }
}
