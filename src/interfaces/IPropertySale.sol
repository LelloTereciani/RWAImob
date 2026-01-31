// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IPropertySale
 * @dev Interface para contrato RWA de venda de imóveis
 * @notice Define funções padrão para contratos imobiliários RWA
 */
interface IPropertySale {
    struct Property {
        uint96 price;
        uint64 listedAt;
        uint64 soldAt;
        address owner;
        bool forSale;
        bytes32 locationHash;
    }
    
    struct Offer {
        address buyer;
        uint96 amount;
        uint64 timestamp;
        bool active;
    }
    
    // Eventos
    event PropertyListed(uint256 indexed propertyId, address indexed seller, uint256 price, bytes32 locationHash);
    event PropertySold(uint256 indexed propertyId, address indexed seller, address indexed buyer, uint256 price, uint256 gasUsed);
    event OfferMade(uint256 indexed propertyId, address indexed buyer, uint256 amount);
    event OfferWithdrawn(uint256 indexed propertyId, address indexed buyer, uint256 amount);
    event PropertyStatusChanged(uint256 indexed propertyId, bool newStatus);
    event PropertyPriceUpdated(uint256 indexed propertyId, uint256 newPrice);
    
    // Funções principais
    function listProperty(string calldata location, uint256 price, string calldata tokenURI) external returns (uint256);
    function relistProperty(uint256 propertyId, uint256 newPrice) external;
    function delistProperty(uint256 propertyId) external;
    function updatePropertyPrice(uint256 propertyId, uint256 newPrice) external;
    function buyProperty(uint256 propertyId) external payable;
    function makeOffer(uint256 propertyId) external payable;
    function acceptOffer(uint256 propertyId, uint256 offerIndex) external;
    function withdrawOffer(uint256 propertyId, uint256 offerIndex) external;
    function refundOffer(uint256 propertyId, uint256 offerIndex) external;
    
    // Funções view
    function getPropertyDetails(uint256 propertyId) external view returns (address owner, uint256 price, bool forSale, uint256 listedAt, uint256 soldAt, bytes32 locationHash);
    function getOwnerProperties(address owner) external view returns (uint256[] memory);
    function getPropertyOffers(uint256 propertyId) external view returns (Offer[] memory);
    
    // Funções administrativas
    function estimateGasForTransaction(uint256 propertyId, uint256 offerAmount) external view returns (uint256);
}
