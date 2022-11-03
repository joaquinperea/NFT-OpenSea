// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC1155Tradable.sol";
import "./Land.sol";
import "./IFactoryERC1155.sol";

/**
 * @title LandLootBox
 *
 * LandLootBox - a tradeable loot box of Land and other stuff.
 */
contract LandLootBox is ERC1155Tradable, ReentrancyGuard {
    uint256 NUM_LANDS_PER_BOX = 3;
    uint256 OPTION_ID = 0;
    address factoryAddress;

    constructor(address _proxyRegistryAddress, address _factoryAddress)
        ERC1155Tradable("LandLootBox", "LOOTBOX", _proxyRegistryAddress)
    {
        factoryAddress = _factoryAddress;
    }

    function unpack(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == _msgSender());

        // Insert custom logic for configuring the item here.
        for (uint256 i = 0; i < NUM_LANDS_PER_BOX; i++) {
            // Mint the ERC1155 item(s).
            FactoryERC1155 factory = FactoryERC1155(factoryAddress);
            factory.mint(OPTION_ID, _msgSender());
        }
        

        // Burn the presale item.
        _burn(_tokenId);
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://creatures-api.opensea.io/api/box/";
    }

    function itemsPerLootbox() public view returns (uint256) {
        return NUM_LANDS_PER_BOX;
    }
}