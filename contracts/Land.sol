// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155Tradable.sol";

contract Land is ERC1155Tradable {
    constructor(address _proxyRegistryAddress) ERC1155Tradable("Land", "LAND", "https://api/land/{id}", _proxyRegistryAddress) {}

    function contractURI() public pure returns (string memory) {
        return "https://api/contract/opensea-erc1155";
    }
}