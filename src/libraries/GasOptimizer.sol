// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title GasOptimizer
 * @dev Biblioteca para otimizações de gas em contratos RWA
 * @notice Técnicas avançadas de otimização de gas
 */
library GasOptimizer {
    
    // Constantes para otimização
    uint256 public constant BASE_GAS_COST = 21000; // Gas base por transação
    uint256 public constant ERC721_TRANSFER_GAS = 60000; // Gas aproximado para transfer ERC721
    uint256 public constant STORAGE_WRITE_GAS = 20000; // Gas por escrita storage
    uint256 public constant EVENT_LOG_GAS = 375; // Gas base por log
    
    /**
     * @dev Estima gas para transação de compra
     * @param offerAmount Valor da oferta
     * @return estimate Estimativa de gas
     */
    function estimateTransactionGas(uint256 /*propertyId*/, uint256 offerAmount) 
        internal 
        pure 
        returns (uint256 estimate) 
    {
        // Cálculo aproximado baseado em operações
        uint256 baseCost = BASE_GAS_COST;
        uint256 transferCost = ERC721_TRANSFER_GAS;
        uint256 storageCost = STORAGE_WRITE_GAS * 3; // 3 escritas storage
        uint256 eventCost = EVENT_LOG_GAS * 2; // 2 eventos
        
        // Ajuste baseado no valor (ETH transfer)
        uint256 valueAdjustment = offerAmount > 0 ? 9000 : 0; // Gas adicional para transfer de valor
        
        estimate = baseCost + transferCost + storageCost + eventCost + valueAdjustment;
    }
    
    /**
     * @dev Otimiza leitura de array usando cache
     * @param array Array a ser lido
     * @param index Índice desejado
     * @return value Valor otimizado
     */
    function safeArrayRead(uint256[] memory array, uint256 index) 
        internal 
        pure 
        returns (uint256 value) 
    {
        require(index < array.length, "RWA: Index out of bounds");
        value = array[index];
    }
    
    /**
     * @dev Otimiza escrita em mapping usando pattern de cache
     * @param map Mapping a ser escrito
     * @param key Chave
     * @param value Valor
     */
    function optimizedMappingWrite(
        mapping(uint256 => uint256) storage map, 
        uint256 key, 
        uint256 value
    ) internal {
        // Cache para reduzir leituras storage
        uint256 currentValue = map[key];
        if (currentValue != value) {
            map[key] = value;
        }
    }
    
    /**
     * @dev Calcula hash otimizado para localização
     * @param location String da localização
     * @return hash Hash keccak256 otimizado
     */
    function optimizedLocationHash(string memory location) 
        internal 
        pure 
        returns (bytes32 hash) 
    {
        hash = keccak256(abi.encodePacked(location));
    }
    
    /**
     * @dev Packing otimizado de dados para storage
     * @param price Preço (96 bits)
     * @param timestamp Timestamp (64 bits)
     * @return packed Dados compactados
     */
    function packPropertyData(uint96 price, uint64 timestamp) 
        internal 
        pure 
        returns (bytes32 packed) 
    {
        packed = bytes32(uint256(price)) | (bytes32(uint256(timestamp)) << 96);
    }
    
    /**
     * @dev Unpacking de dados compactados
     * @param packed Dados compactados
     * @return price Preço
     * @return timestamp Timestamp
     */
    function unpackPropertyData(bytes32 packed) 
        internal 
        pure 
        returns (uint96 price, uint64 timestamp) 
    {
        price = uint96(uint256(packed) & ((1 << 96) - 1));
        timestamp = uint64(uint256(packed) >> 96);
    }
}
