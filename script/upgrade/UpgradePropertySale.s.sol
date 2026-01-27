// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/contracts/PropertySale.sol";

/**
 * @title UpgradePropertySale
 * @dev Script para fazer upgrade do contrato PropertySale
 */
contract UpgradePropertySale is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROPERTYSALE_ADDRESS");
        
        console.log("Iniciando upgrade do PropertySale");
        console.log("Proxy Address:", proxyAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy nova implementação
        PropertySale newImplementation = new PropertySale();
        console.log("Nova Implementation:", address(newImplementation));
        
        // 2. Obter ProxyAdmin
        // O ProxyAdmin foi deployado junto com o proxy
        // Precisamos do endereço dele
        address proxyAdminAddress = vm.envAddress("PROXY_ADMIN_ADDRESS");
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        
        // 3. Fazer upgrade usando upgradeAndCall()
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(proxyAddress),
            address(newImplementation),
            ""
        );
        
        console.log("Upgrade concluido com sucesso!");
        console.log("Proxy continua em:", proxyAddress);
        console.log("Nova implementacao:", address(newImplementation));
        
        vm.stopBroadcast();
        
        // 4. Verificações
        PropertySale propertySale = PropertySale(proxyAddress);
        console.log("");
        console.log("Verificacoes:");
        console.log("- Owner:", propertySale.owner());
        console.log("- Nome:", propertySale.name());
        console.log("- Simbolo:", propertySale.symbol());
    }
}
