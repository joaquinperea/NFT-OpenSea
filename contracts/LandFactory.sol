// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IFactoryERC1155.sol";
import "./Land.sol";
import "./LandLootBox.sol";

contract LandFactory is FactoryERC1155, Ownable, ReentrancyGuard {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    address public lootBoxNftAddress;
    string public baseURI = "https://api";

    /*
     * Enforce the existence of only 1000 OpenSea lands.
     */
    uint256 LAND_SUPPLY = 1000;

    /*
     * Three different options for minting Lands.
     */
    uint256 NUM_OPTIONS = 3;
    uint256 SINGLE_LAND_OPTION = 0;
    uint256 MULTIPLE_LAND_OPTION = 1;
    uint256 LOOTBOX_OPTION = 2;
    uint256 NUM_LANDS_IN_MULTIPLE_LAND_OPTION = 4;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        lootBoxNftAddress = address(
            new LandLootBox(_proxyRegistryAddress, address(this))
        );

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Land Item Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "LF";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender() ||
                _msgSender() == lootBoxNftAddress
        );
        require(canMint(_optionId));

        Land openSeaLand = Land(nftAddress);
        if (_optionId == SINGLE_LAND_OPTION) {
            openSeaLand.mintTo(_toAddress);
        } else if (_optionId == MULTIPLE_LAND_OPTION) {
            for (
                uint256 i = 0;
                i < NUM_LANDS_IN_MULTIPLE_LAND_OPTION;
                i++
            ) {
                openSeaLand.mintTo(_toAddress);
            }
        } else if (_optionId == LOOTBOX_OPTION) {
            LandLootBox openSeaLandLootBox = LandLootBox(
                lootBoxNftAddress
            );
            openSeaLandLootBox.mintTo(_toAddress);
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        Land openSeaLand = Land(nftAddress);
        uint256 landSupply = openSeaLand.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_LAND_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_LAND_OPTION) {
            numItemsAllocated = NUM_LANDS_IN_MULTIPLE_LAND_OPTION;
        } else if (_optionId == LOOTBOX_OPTION) {
            LandLootBox openSeaLandLootBox = LandLootBox(
                lootBoxNftAddress
            );
            numItemsAllocated = openSeaLandLootBox.itemsPerLootbox();
        }
        return landSupply < (LAND_SUPPLY - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256) public view returns (address _owner) {
        return owner();
    }
}