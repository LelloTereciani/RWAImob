// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/contracts/PropertySale.sol";
import "../../src/interfaces/IPropertySale.sol";

contract PropertySaleGasTest is Test {
    PropertySale propertySale;
    ProxyAdmin proxyAdmin;
    TransparentUpgradeableProxy proxy;
    address owner = address(1);
    address buyer = address(2);
    
    function setUp() public {
        PropertySale implementation = new PropertySale();
        proxyAdmin = new ProxyAdmin(owner);
        bytes memory initData = abi.encodeWithSelector(
            PropertySale.initialize.selector,
            owner
        );
        proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );
        propertySale = PropertySale(address(proxy));
        vm.deal(buyer, 100 ether);
    }

    function testGasListProperty() public {
        vm.prank(owner);
        uint256 startGas = gasleft();
        propertySale.listProperty("Sao Paulo - SP, Brazil", 1 ether, "ipfs://test-data-for-gas-measurement");
        uint256 gasUsed = startGas - gasleft();
        
        console.log("Gas used for listProperty:", gasUsed);
    }

    function testGasBuyProperty() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP, Brazil", 1 ether, "ipfs://test");

        vm.prank(buyer);
        uint256 startGas = gasleft();
        propertySale.buyProperty{value: 1 ether}(id);
        uint256 gasUsed = startGas - gasleft();

        uint256 estimate = propertySale.estimateGasForTransaction(id, 1 ether);
        
        console.log("Gas used for buyProperty:", gasUsed);
        console.log("Estimate from GasOptimizer:", estimate);
        
        // Ensure estimate is a reasonable upper bound or close enough
        // Note: gasleft() diff is slightly more than the actual call due to overhead, 
        // but it's a good measure.
        assertTrue(estimate >= gasUsed - 2000, "Estimate should be a reasonable upper bound");
    }

    function testGasMakeOffer() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP, Brazil", 1 ether, "ipfs://test");

        vm.prank(buyer);
        uint256 startGas = gasleft();
        propertySale.makeOffer{value: 1.1 ether}(id);
        uint256 gasUsed = startGas - gasleft();

        console.log("Gas used for makeOffer:", gasUsed);
    }

    function testGasAcceptOffer() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP, Brazil", 1 ether, "ipfs://test");

        vm.prank(buyer);
        propertySale.makeOffer{value: 1.1 ether}(id);

        vm.prank(owner);
        uint256 startGas = gasleft();
        propertySale.acceptOffer(id, 0);
        uint256 gasUsed = startGas - gasleft();

        console.log("Gas used for acceptOffer:", gasUsed);
    }
}
