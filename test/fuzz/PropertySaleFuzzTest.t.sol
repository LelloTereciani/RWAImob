// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/contracts/PropertySale.sol";
import "../../src/interfaces/IPropertySale.sol";
import "../../src/libraries/PropertyValidation.sol";

contract PropertySaleFuzzTest is Test {
    PropertySale propertySale;
    address owner = address(1);
    address buyer = address(2);
    
    function setUp() public {
        PropertySale implementation = new PropertySale();
        // Simplified setup for OZ v5 behavior already validated in upgrade tests
        proxy = new TransparentUpgradeableProxy(
            address(implementation),
            owner,
            abi.encodeWithSelector(PropertySale.initialize.selector, owner)
        );
        propertySale = PropertySale(address(proxy));
        vm.deal(buyer, 1000000 ether);
    }

    TransparentUpgradeableProxy proxy;

    function testFuzzListProperty(uint256 price, string memory location) public {
        // Bound price and location length to valid ranges
        price = bound(price, PropertyValidation.MIN_PRICE, PropertyValidation.MAX_PRICE);
        
        // Ensure location length is between 5 and 100
        bytes memory locBytes = bytes(location);
        vm.assume(locBytes.length >= 5 && locBytes.length <= 100);

        vm.prank(owner);
        uint256 id = propertySale.listProperty(location, price, "ipfs://fuzz");
        
        (address pOwner, uint256 pPrice, bool forSale, , , , ) = propertySale.getPropertyDetails(id);
        assertEq(pOwner, owner);
        assertEq(pPrice, price);
        assertTrue(forSale);
    }

    function testFuzzBuyProperty(uint256 listedPrice, uint256 paymentAmount) public {
        listedPrice = bound(listedPrice, PropertyValidation.MIN_PRICE, PropertyValidation.MAX_PRICE);
        paymentAmount = bound(paymentAmount, listedPrice, 1000000 ether);

        vm.prank(owner);
        uint256 id = propertySale.listProperty("Valid Location", listedPrice, "ipfs://fuzz");

        vm.prank(buyer);
        propertySale.buyProperty{value: paymentAmount}(id);

        (address pOwner, , bool forSale, , , , ) = propertySale.getPropertyDetails(id);
        assertEq(pOwner, buyer);
        assertFalse(forSale);
    }

    function testFuzzMakeOffer(uint256 listedPrice, uint256 offerAmount) public {
        listedPrice = bound(listedPrice, PropertyValidation.MIN_PRICE, PropertyValidation.MAX_PRICE);
        offerAmount = bound(offerAmount, listedPrice, 1000000 ether);

        vm.prank(owner);
        uint256 id = propertySale.listProperty("Valid Location", listedPrice, "ipfs://fuzz");

        vm.prank(buyer);
        propertySale.makeOffer{value: offerAmount}(id);

        IPropertySale.Offer[] memory offers = propertySale.getPropertyOffers(id);
        assertEq(offers.length, 1);
        assertEq(offers[0].amount, offerAmount);
        assertTrue(offers[0].active);
    }

    function testFuzzVolumeInvariant(uint256[3] memory prices) public {
        uint256 expectedVolume = 0;
        uint256[3] memory ids;

        vm.startPrank(owner);
        for(uint i=0; i<3; i++) {
            uint256 price = bound(prices[i], PropertyValidation.MIN_PRICE, PropertyValidation.MAX_PRICE);
            ids[i] = propertySale.listProperty("Valid Location", price, "ipfs://fuzz");
        }
        vm.stopPrank();

        for(uint i=0; i<3; i++) {
            uint256 price = bound(prices[i], PropertyValidation.MIN_PRICE, PropertyValidation.MAX_PRICE);
            address currentBuyer = address(uint160(100 + i));
            vm.deal(currentBuyer, price);
            
            vm.prank(currentBuyer);
            propertySale.buyProperty{value: price}(ids[i]);
            expectedVolume += price;
        }

        assertEq(propertySale.totalVolume(), expectedVolume, "Total volume invariant failed");
        assertEq(propertySale.transactionCount(), 3, "Transaction count invariant failed");
    }

    function testFuzzWithdrawOffer(uint256 listedPrice, uint256 offerAmount) public {
        listedPrice = bound(listedPrice, PropertyValidation.MIN_PRICE, PropertyValidation.MAX_PRICE);
        offerAmount = bound(offerAmount, listedPrice, 1000000 ether);

        vm.prank(owner);
        uint256 id = propertySale.listProperty("Valid Location", listedPrice, "ipfs://fuzz");

        vm.prank(buyer);
        propertySale.makeOffer{value: offerAmount}(id);

        uint256 balanceBefore = buyer.balance;
        
        vm.prank(buyer);
        propertySale.withdrawOffer(id, 0);

        assertEq(buyer.balance, balanceBefore + offerAmount, "Withdrawal refund amount mismatch");
        
        IPropertySale.Offer[] memory offers = propertySale.getPropertyOffers(id);
        assertFalse(offers[0].active, "Offer should be inactive after withdrawal");
    }
}
