// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/contracts/PropertySale.sol";

/**
 * @title DeployPropertySale
 * @dev Script de deploy corrigido para OZ v5.0
 */
contract DeployPropertySale is Script {
    function run() external {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Iniciando deploy RWA Multichain");
        console.log("Deployer:", deployer);
        console.log("Rede:", vm.toString(block.chainid));
        console.log("Gas Price:", tx.gasprice);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployer);
        console.log("ProxyAdmin (T-Rex):", address(proxyAdmin));
        
        // 2. Deploy Implementation
        PropertySale implementation = new PropertySale();
        console.log("Implementation:", address(implementation));
        
        // 3. Calcular init data com owner
        bytes memory initData = abi.encodeWithSelector(
            PropertySale.initialize.selector,
            deployer
        );
        
        // 4. Deploy Transparent Proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );
        
        console.log("Proxy (T-Rex):", address(proxy));
        
        // 5. Instanciar contrato via proxy
        PropertySale propertySale = PropertySale(address(proxy));
        
        console.log("Contrato RWA pronto em:", address(propertySale));
        console.log("Owner:", propertySale.owner());
        console.log("T-Rex Pattern: IMPLEMENTADO");
        
        vm.stopBroadcast();
        
        // 6. Verificações
        console.log("");
        console.log("Verificacoes:");
        console.log("- ERC721 Support:", propertySale.supportsInterface(0x80ac58cd));
        console.log("- Ownable:", propertySale.owner() == deployer);
        
        console.log("");
        console.log("Estimativa de Gas:");
        uint256 estimate = propertySale.estimateGasForTransaction(1, 1 ether);
        console.log("- Gas estimado para listProperty:", estimate);
        
        console.log("");
        console.log("Deploy concluido com sucesso!");
        console.log("Proximos passos:");
        console.log("   1. Verificar contrato no explorer");
        console.log("   2. Executar testes: forge test");
        console.log("   3. Deploy frontend na Vercel");
    }
}
