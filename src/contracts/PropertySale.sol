// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IPropertySale.sol";
import "../libraries/PropertyValidation.sol";
import "../libraries/GasOptimizer.sol";

/**
 * @title PropertySale
 * @dev Contrato RWA imobiliário final com T-Rex Pattern
 */
contract PropertySale is 
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuard,
    IPropertySale
{
    using PropertyValidation for *;
    using GasOptimizer for *;
    
    uint256 private _nextPropertyId;
    uint256 public totalVolume;
    uint256 public transactionCount;
    
    mapping(uint256 => Property) private _properties;
    mapping(address => uint256[]) private _ownerProperties;
    mapping(uint256 => Offer[]) private _propertyOffers;
    mapping(uint256 => string) private _tokenURIs;
    
    uint256[50] private __gap;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address initialOwner) public initializer {
        __ERC721_init("RWA Real Estate", "RWARE");
        __Ownable_init(initialOwner);
        // ReentrancyGuard doesn't require initialization for upgradeable contracts
        
        _nextPropertyId = 0;
        totalVolume = 0;
        transactionCount = 0;
    }
    
    function listProperty(
        string calldata location,
        uint256 price,
        string calldata uri
    ) 
        external 
        override 
        onlyOwner 
        nonReentrant 
        returns (uint256 propertyId) 
    {
        PropertyValidation.validatePrice(price);
        PropertyValidation.validateLocation(location);
        
        bytes32 locationHash = GasOptimizer.optimizedLocationHash(location);
        
        _nextPropertyId++;
        propertyId = _nextPropertyId;
        
        _safeMint(msg.sender, propertyId);
        _tokenURIs[propertyId] = uri;
        
        _properties[propertyId] = Property({
            price: uint96(price),
            listedAt: uint64(block.timestamp),
            soldAt: 0,
            owner: msg.sender,
            forSale: true,
            location: location,
            locationHash: locationHash
        });
        
        _ownerProperties[msg.sender].push(propertyId);
        
        emit PropertyListed(propertyId, msg.sender, price, location, locationHash);
        return propertyId;
    }
    
    function relistProperty(uint256 propertyId, uint256 newPrice) 
        external 
        override 
        nonReentrant 
    {
        PropertyValidation.validatePropertyId(propertyId);
        PropertyValidation.validatePrice(newPrice);
        Property storage property = _properties[propertyId];
        
        require(ownerOf(propertyId) == msg.sender, "RWA: Not property owner");
        
        property.price = uint96(newPrice);
        property.forSale = true;
        property.listedAt = uint64(block.timestamp);
        
        emit PropertyListed(propertyId, msg.sender, newPrice, property.location, property.locationHash);
        emit PropertyStatusChanged(propertyId, true);
    }

    function delistProperty(uint256 propertyId)
        external
        override
        nonReentrant
    {
        PropertyValidation.validatePropertyId(propertyId);
        Property storage property = _properties[propertyId];

        require(ownerOf(propertyId) == msg.sender, "RWA: Not property owner");
        require(property.forSale, "RWA: Property not for sale");

        property.forSale = false;

        emit PropertyStatusChanged(propertyId, false);
    }

    function updatePropertyPrice(uint256 propertyId, uint256 newPrice)
        external
        override
        nonReentrant
    {
        PropertyValidation.validatePropertyId(propertyId);
        PropertyValidation.validatePrice(newPrice);
        Property storage property = _properties[propertyId];

        require(ownerOf(propertyId) == msg.sender, "RWA: Not property owner");

        property.price = uint96(newPrice);

        emit PropertyPriceUpdated(propertyId, newPrice);
    }
    
    function buyProperty(uint256 propertyId) 
        external 
        payable 
        override 
        nonReentrant
    {
        PropertyValidation.validatePropertyId(propertyId);
        Property storage property = _properties[propertyId];
        
        require(property.forSale, "RWA: Property not for sale");
        require(msg.value >= property.price, "RWA: Insufficient payment");
        require(msg.sender != property.owner, "RWA: Cannot buy own property");
        
        address seller = property.owner;
        uint256 purchasePrice = property.price;
        
        // Efeito antes da interação (CEI Pattern)
        property.owner = msg.sender;
        property.forSale = false;
        property.soldAt = uint64(block.timestamp);
        
        totalVolume += purchasePrice;
        transactionCount++;
        
        _transfer(seller, msg.sender, propertyId);
        _processPayment(seller, purchasePrice);
        
        emit PropertySold(propertyId, seller, msg.sender, purchasePrice, 0);
    }
    
    function makeOffer(uint256 propertyId) 
        external 
        payable 
        override 
        nonReentrant
    {
        PropertyValidation.validatePropertyId(propertyId);
        Property storage property = _properties[propertyId];
        
        require(property.forSale, "RWA: Property not for sale");
        require(msg.sender != property.owner, "RWA: Owner cannot offer");
        PropertyValidation.validateOffer(msg.value, property.price);
        
        _propertyOffers[propertyId].push(Offer({
            buyer: msg.sender,
            amount: uint96(msg.value),
            timestamp: uint64(block.timestamp),
            active: true
        }));
        
        emit OfferMade(propertyId, msg.sender, msg.value);
    }
    
    function acceptOffer(uint256 propertyId, uint256 offerIndex) 
        external 
        override 
        nonReentrant
    {
        PropertyValidation.validatePropertyId(propertyId);
        require(ownerOf(propertyId) == msg.sender, "RWA: Not property owner");
        Property storage property = _properties[propertyId];
        Offer storage offer = _propertyOffers[propertyId][offerIndex];
        
        require(property.forSale, "RWA: Property not for sale");
        require(offer.active, "RWA: Offer not active");
        
        address buyerAddr = offer.buyer;
        uint256 amount = offer.amount;
        
        // Efeito antes da interação
        property.owner = buyerAddr;
        property.forSale = false;
        property.soldAt = uint64(block.timestamp);
        offer.active = false;
        
        totalVolume += amount;
        transactionCount++;
        
        _transfer(msg.sender, buyerAddr, propertyId);
        _processPayment(msg.sender, amount);
        
        emit PropertySold(propertyId, msg.sender, buyerAddr, amount, 0);
    }

    function withdrawOffer(uint256 propertyId, uint256 offerIndex) 
        external 
        override 
        nonReentrant 
    {
        PropertyValidation.validatePropertyId(propertyId);
        Offer storage offer = _propertyOffers[propertyId][offerIndex];
        
        require(offer.buyer == msg.sender, "RWA: Not your offer");
        require(offer.active, "RWA: Offer not active");
        
        uint256 amount = offer.amount;
        offer.active = false;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "RWA: Withdrawal failed");
        
        emit OfferWithdrawn(propertyId, msg.sender, amount);
    }

    function refundOffer(uint256 propertyId, uint256 offerIndex)
        external
        override
        nonReentrant
    {
        PropertyValidation.validatePropertyId(propertyId);
        Offer storage offer = _propertyOffers[propertyId][offerIndex];

        require(ownerOf(propertyId) == msg.sender, "RWA: Not property owner");
        require(offer.active, "RWA: Offer not active");

        address buyer = offer.buyer;
        uint256 amount = offer.amount;
        offer.active = false;

        (bool success, ) = buyer.call{value: amount}("");
        require(success, "RWA: Refund failed");

        emit OfferWithdrawn(propertyId, buyer, amount);
    }
    
    function _processPayment(address recipient, uint256 amount) private {
        // Envio para o vendedor
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "RWA: Payment failed");
        
        // Reembolso de excesso (se houver)
        if (msg.value > amount) {
            uint256 excess = msg.value - amount;
            (bool refundSuccess, ) = msg.sender.call{value: excess}("");
            require(refundSuccess, "RWA: Refund failed");
        }
    }
    
    function getOwnerProperties(address owner) external view override returns (uint256[] memory) {
        return _ownerProperties[owner];
    }
    
    function getPropertyOffers(uint256 propertyId) external view override returns (Offer[] memory) {
        return _propertyOffers[propertyId];
    }
    
    function getPropertyDetails(uint256 propertyId)
        external
        view
        override
        returns (
            address owner,
            uint256 price,
            bool forSale,
            uint256 listedAt,
            uint256 soldAt,
            string memory location,
            bytes32 locationHash
        )
    {
        PropertyValidation.validatePropertyId(propertyId);
        Property memory property = _properties[propertyId];
        return (
            property.owner,
            property.price,
            property.forSale,
            property.listedAt,
            property.soldAt,
            property.location,
            property.locationHash
        );
    }
    
    function estimateGasForTransaction(uint256 propertyId, uint256 offerAmount) external view override returns (uint256) {
        return GasOptimizer.estimateTransactionGas(propertyId, offerAmount);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory uri = _tokenURIs[tokenId];
        return bytes(uri).length > 0 ? uri : "";
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
