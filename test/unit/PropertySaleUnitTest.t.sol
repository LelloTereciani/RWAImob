// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/contracts/PropertySale.sol";
import "../../src/interfaces/IPropertySale.sol";

contract PropertySaleUnitTest is Test {
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
    }

    function testInitialization() public {
        assertEq(propertySale.owner(), owner);
        assertEq(propertySale.totalVolume(), 0);
        assertEq(propertySale.transactionCount(), 0);
    }

    // --- Listing Tests ---

    function testListPropertySuccess() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");
        assertEq(id, 1);
        
        (address propertyOwner, uint256 price, bool forSale, , , ) = propertySale.getPropertyDetails(id);
        assertEq(propertyOwner, owner);
        assertEq(price, 1 ether);
        assertTrue(forSale);
    }

    function testListPropertyUnauthorized() public {
        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", buyer));
        propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");
    }

    function testListPropertyInvalidPriceTooLow() public {
        vm.prank(owner);
        vm.expectRevert("RWA: Price too low");
        propertySale.listProperty("Sao Paulo - SP", 0.0001 ether, "ipfs://test");
    }

    function testListPropertyInvalidPriceTooHigh() public {
        vm.prank(owner);
        vm.expectRevert("RWA: Price too high");
        propertySale.listProperty("Sao Paulo - SP", 100001 ether, "ipfs://test");
    }

    function testListPropertyInvalidLocationTooShort() public {
        vm.prank(owner);
        vm.expectRevert("RWA: Location too short");
        propertySale.listProperty("SP", 1 ether, "ipfs://test");
    }

    // --- Buying Tests ---

    function testBuyPropertySuccess() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        propertySale.buyProperty{value: 1 ether}(id);

        (address propertyOwner, , bool forSale, , uint256 soldAt, ) = propertySale.getPropertyDetails(id);
        assertEq(propertyOwner, buyer);
        assertFalse(forSale);
        assertTrue(soldAt > 0);
        assertEq(owner.balance, 1 ether);
        assertEq(propertySale.totalVolume(), 1 ether);
        assertEq(propertySale.transactionCount(), 1);
    }

    function testBuyPropertyWithRefund() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 2 ether);
        uint256 initialBuyerBalance = buyer.balance;
        
        vm.prank(buyer);
        propertySale.buyProperty{value: 1.5 ether}(id);

        assertEq(owner.balance, 1 ether);
        assertEq(buyer.balance, initialBuyerBalance - 1 ether);
    }

    function testBuyPropertyInsufficientPayment() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        vm.expectRevert("RWA: Insufficient payment");
        propertySale.buyProperty{value: 0.5 ether}(id);
    }

    function testBuyPropertyNotForSale() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        propertySale.buyProperty{value: 1 ether}(id);

        address secondBuyer = address(3);
        vm.deal(secondBuyer, 2 ether);
        vm.prank(secondBuyer);
        vm.expectRevert("RWA: Property not for sale");
        propertySale.buyProperty{value: 1 ether}(id);
    }

    function testBuyOwnProperty() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(owner, 2 ether);
        vm.prank(owner);
        vm.expectRevert("RWA: Cannot buy own property");
        propertySale.buyProperty{value: 1 ether}(id);
    }

    // --- Offer Tests ---

    function testMakeOfferSuccess() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        propertySale.makeOffer{value: 1 ether}(id);

        IPropertySale.Offer[] memory offers = propertySale.getPropertyOffers(id);
        assertEq(offers.length, 1);
        assertEq(offers[0].buyer, buyer);
        assertEq(offers[0].amount, 1 ether);
        assertTrue(offers[0].active);
    }

    function testMakeOfferBelowPrice() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        vm.expectRevert("RWA: Offer below minimum price");
        propertySale.makeOffer{value: 0.5 ether}(id);
    }

    function testAcceptOfferSuccess() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1.2 ether);
        vm.prank(buyer);
        propertySale.makeOffer{value: 1.2 ether}(id);

        vm.prank(owner);
        propertySale.acceptOffer(id, 0);

        (address propertyOwner, , bool forSale, , , ) = propertySale.getPropertyDetails(id);
        assertEq(propertyOwner, buyer);
        assertFalse(forSale);
        assertEq(owner.balance, 1.2 ether);
    }

    function testAcceptOfferUnauthorized() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        propertySale.makeOffer{value: 1 ether}(id);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", buyer));
        propertySale.acceptOffer(id, 0);
    }

    // --- Withdrawal Tests ---

    function testWithdrawOfferSuccess() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        propertySale.makeOffer{value: 1 ether}(id);

        uint256 balanceBefore = buyer.balance;
        vm.prank(buyer);
        propertySale.withdrawOffer(id, 0);

        assertEq(buyer.balance, balanceBefore + 1 ether);
        IPropertySale.Offer[] memory offers = propertySale.getPropertyOffers(id);
        assertFalse(offers[0].active);
    }

    function testWithdrawOfferUnauthorized() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        propertySale.makeOffer{value: 1 ether}(id);

        address other = address(99);
        vm.prank(other);
        vm.expectRevert("RWA: Not your offer");
        propertySale.withdrawOffer(id, 0);
    }

    function testWithdrawOfferAlreadyInactive() public {
        vm.prank(owner);
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, "ipfs://test");

        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        propertySale.makeOffer{value: 1 ether}(id);

        vm.prank(owner);
        propertySale.acceptOffer(id, 0);

        vm.prank(buyer);
        vm.expectRevert("RWA: Offer not active");
        propertySale.withdrawOffer(id, 0);
    }

    // --- Utility/View Tests ---

    function testTokenURI() public {
        vm.prank(owner);
        string memory uri = "ipfs://unique-uri";
        uint256 id = propertySale.listProperty("Sao Paulo - SP", 1 ether, uri);
        
        assertEq(propertySale.tokenURI(id), uri);
    }

    function testGetOwnerProperties() public {
        vm.startPrank(owner);
        propertySale.listProperty("Location 1", 1 ether, "uri1");
        propertySale.listProperty("Location 2", 1 ether, "uri2");
        vm.stopPrank();

        uint256[] memory ids = propertySale.getOwnerProperties(owner);
        assertEq(ids.length, 2);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
    }
}
