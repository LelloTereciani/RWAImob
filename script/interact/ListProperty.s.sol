// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../../src/contracts/PropertySale.sol";

contract ListProperty is Script {
    function run() external {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address contractAddress = vm.envAddress("PROPERTYSALE_ADDRESS");
        
        string memory location = vm.envString("LOCATION");
        uint256 price = vm.envUint("PRICE"); // In Wei
        string memory uri = vm.envString("URI");

        vm.startBroadcast(deployerPrivateKey);

        PropertySale propertySale = PropertySale(contractAddress);
        uint256 newId = propertySale.listProperty(location, price, uri);
        
        console.log("Property Listed Successfully!");
        console.log("ID:", newId);
        console.log("Price:", price);
        console.log("Location:", location);

        vm.stopBroadcast();
    }
}
