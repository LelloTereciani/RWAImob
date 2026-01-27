// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PropertyValidation
 * @dev Biblioteca de validações para contratos RWA imobiliários
 * @notice Contém funções para validações de segurança
 */
library PropertyValidation {
    
    // Constantes de validação
    uint256 public constant MIN_PRICE = 0.001 ether; // Preço mínimo
    uint256 public constant MAX_PRICE = 100000 ether; // Preço máximo
    uint256 public constant MIN_LOCATION_LENGTH = 5; // Localização mínima
    uint256 public constant MAX_LOCATION_LENGTH = 100; // Localização máxima
    
    /**
     * @dev Valida preço do imóvel
     * @param price Preço em wei
     */
    function validatePrice(uint256 price) internal pure {
        require(price >= MIN_PRICE, "RWA: Price too low");
        require(price <= MAX_PRICE, "RWA: Price too high");
    }
    
    /**
     * @dev Valida localização do imóvel
     * @param location String da localização
     */
    function validateLocation(string memory location) internal pure {
        bytes memory locationBytes = bytes(location);
        require(locationBytes.length >= MIN_LOCATION_LENGTH, "RWA: Location too short");
        require(locationBytes.length <= MAX_LOCATION_LENGTH, "RWA: Location too long");
        
        // Verificar se não está vazio
        require(locationBytes.length > 0, "RWA: Location cannot be empty");
    }
    
    /**
     * @dev Valida endereço Ethereum
     * @param addr Endereço a validar
     */
    function validateAddress(address addr) internal view {
        require(addr != address(0), "RWA: Invalid address");
        require(addr != address(this), "RWA: Cannot use contract address");
    }
    
    /**
     * @dev Valida ID de propriedade
     * @param propertyId ID da propriedade
     */
    function validatePropertyId(uint256 propertyId) internal pure {
        require(propertyId > 0, "RWA: Invalid property ID");
    }
    
    /**
     * @dev Valida valor de oferta
     * @param offerAmount Valor da oferta
     */
    function validateOffer(uint256 offerAmount, uint256 /* minPrice */) internal pure {
        require(offerAmount > 0, "RWA: Offer must have value");
        // Permitimos ofertas menores que o preço para negociação
    }
}
