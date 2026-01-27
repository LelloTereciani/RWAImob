// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/contracts/PropertySale.sol";

contract PropertySaleV2Mock is PropertySale {
    string public version;
    uint256 public newField;

    function setVersion(string memory _version) external onlyOwner {
        version = _version;
    }

    function setNewField(uint256 _value) external {
        newField = _value;
    }

    function getV2Identifier() external pure returns (string memory) {
        return "RWA_V2_MOCK";
    }
}
