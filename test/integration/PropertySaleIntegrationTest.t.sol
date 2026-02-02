// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/contracts/PropertySale.sol";
import "../../src/interfaces/IPropertySale.sol";

contract PropertySaleIntegrationTest is Test {
    PropertySale propertySale;
    ProxyAdmin proxyAdmin;
    TransparentUpgradeableProxy proxy;
    address owner = address(1);
    address buyerA = address(10);
    address buyerB = address(11);
    address buyerC = address(12);
    
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

        vm.deal(buyerA, 10 ether);
        vm.deal(buyerB, 10 ether);
        vm.deal(buyerC, 10 ether);
    }

    function testMarketplaceLifecycleAndFinancialIntegrity() public {
        // 1. Owner lists 3 properties
        vm.startPrank(owner);
        uint256 id1 = propertySale.listProperty("Rua A, 123", 1 ether, "ipfs://p1");
        uint256 id2 = propertySale.listProperty("Av B, 456", 2 ether, "ipfs://p2");
        uint256 id3 = propertySale.listProperty("Pca C, 789", 3 ether, "ipfs://p3");
        vm.stopPrank();

        // 2. Buyer A buys Property 1 directly
        vm.prank(buyerA);
        propertySale.buyProperty{value: 1 ether}(id1);

        // 3. Buyer B makes an offer on Property 2
        vm.prank(buyerB);
        propertySale.makeOffer{value: 2 ether}(id2);

        // 4. Buyer C makes a HIGHER offer on Property 2
        vm.prank(buyerC);
        propertySale.makeOffer{value: 2.5 ether}(id2);

        // 5. Owner accepts Buyer C's offer (index 1)
        vm.prank(owner);
        propertySale.acceptOffer(id2, 1);

        // --- Verificações de Propriedade ---
        (address owner1, , bool forSale1, , , , ) = propertySale.getPropertyDetails(id1);
        assertEq(owner1, buyerA, "Buyer A should own Property 1");
        assertFalse(forSale1, "Property 1 should be sold");

        (address owner2, , bool forSale2, , , , ) = propertySale.getPropertyDetails(id2);
        assertEq(owner2, buyerC, "Buyer C should own Property 2");
        assertFalse(forSale2, "Property 2 should be sold");

        (address owner3, , bool forSale3, , , , ) = propertySale.getPropertyDetails(id3);
        assertEq(owner3, owner, "Owner should still own Property 3");
        assertTrue(forSale3, "Property 3 should still be for sale");

        // --- Verificações Financeiras ---
        // Preço P1 (1 ETH) + Preço Oferta C para P2 (2.5 ETH) = 3.5 ETH
        assertEq(propertySale.totalVolume(), 3.5 ether, "Total volume should be 3.5 ether");
        assertEq(propertySale.transactionCount(), 2, "Transaction count should be 2");
        
        // O proprietário (vendedor) deve ter recebido 1 + 2.5 = 3.5 ETH
        assertEq(owner.balance, 3.5 ether, "Seller should have received all payments");

        // Buyer B fez oferta mas ela não foi aceita. 
        // Agora Buyer B retira a oferta para recuperar os fundos.
        uint256 balanceBeforeWithdraw = buyerB.balance;
        vm.prank(buyerB);
        propertySale.withdrawOffer(id2, 0);

        assertEq(buyerB.balance, balanceBeforeWithdraw + 2 ether, "Buyer B should have recovered funds");
        assertEq(address(propertySale).balance, 0, "Contract balance should be zero after withdrawal");
    }

    function testDoublePurchaseRevert() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Rua A, 123", 1 ether, "ipfs://p1");

        vm.prank(buyerA);
        propertySale.buyProperty{value: 1 ether}(id);

        vm.prank(buyerB);
        vm.expectRevert("RWA: Property not for sale");
        propertySale.buyProperty{value: 1 ether}(id);
    }
}
