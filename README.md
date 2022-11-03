# How to create an NFT project from scratch and publish it on OpenSea
In a Blockchain project there is a fundamental point and it is the development of what respects smart contracts that reflect business logic. In this particular case, we are going to talk about the development of non-fungible token smart contracts and their use in a particular blockchain.

Last year we have heard everywhere about NFTs, but what is an NFT? An NFT is a non-fungible token. Non-fungible means that it cannot be subdivided or replaced by another.

There are also fungible tokens, these can be replaced by another equal as long as the value they represent is the same. In the case of NFTs, this does not happen: we are interested in one in particular and there is no other token that can replace it and have the same meaning for us.

Let's suppose the following scenario: we want to launch for sale a collection of NFTs that represent an asset of our interest, lots or land on some platform (such as Decentraland or Sandbox) that we are developing. Clearly, we will go through the process of developing a FrontEnd that leaves us satisfied, some BackEnd microservices necessary to provide certain information, but we must also define and deploy smart contracts that represent our business logic.

That is why for this article, we will try to elucidate how to generate a collection of land NFTs to sell to the user. We first define the types of non-fungible tokens that we are going to release. In this case, we will deploy an NFT that represents the land to be sold and another NFT that is a chest or "lootbox" that, when opened, allows us to access new land.

## We must take into account that:
However, in the case of non-fungible tokens (NFT), the patterns to be used are the ERC 721 and ERC 1155 standards, defined by an organization dedicated to the generation and propagation of these mechanisms called “OpenZeppelin”. A brief description of these is:
* ERC 721: Basically, each ERC 721 token is unique and represents a single asset. Furthermore, it allows developers to create a new ecosystem of tokens on the Ethereum blockchain. The pattern aims to create tradable tokens. An example of an ERC 721 contract is that of OpenZeppelin, which allows developers to track items in their games.
* ERC 1155: When a person uses an ERC 1155 standard to code their contract, they are not considering their token as a 100% non-fungible asset, but rather working with a combination between the existence or not of that fungibility. In a single ERC 1155 contract, a developer can define a non-fungible token as a fungible. In addition, it uses mechanisms that allow GAS to be saved in each "mint" operation or minting of a new unit as well as a batch of units.

Most NFT contracts use the ERC 721 standard but there is a growing intention to use ERC 1155 for contracts. Since our project requires that each piece of land be an identifiable and unique unit of interest for the buyer, we will use the ERC 721 standard for this purpose, considering that using an ERC 1155 strategy would be wasting the additional features of the latter.

As a last consideration for our project, we want that once the contracts are deployed, they are available for purchase in the OpenSea marketplace. This leading platform in the exchange of non-fungible tokens will allow us to observe their characteristics and even acquire them through a cryptoactive exchange. OpenSea has a repository where a developer can access a model project of both ERC 721 and ERC 1155. We will make use of these facilities to speed up the development process but without losing sight of the details of its implementation.

So let's start with the development! The first thing we will do is clone the OpenSea repository in our preferred directory. To do this we will use the Git version control tool and execute:

```
git clone https://github.com/ProjectOpenSea/opensea-creatures.git
```

The next step would be to get all the necessary packages from the repository. To do this, we run yarn. If you don't have yarn installed, run:

```
npm install -g yarn
```

Finally:

```
yarn
```


Once we have the repository downloaded and the packages available, we look at its structure. The repository has the following files and directories:

* contracts: directory that contains the smart contracts of the project. This is where we will work on the business logic of the project and try to reflect it in ERC 721 contracts.
* migrations: contains scripts for a Truffle project's own migrations. Its execution is equivalent to deploying one or more contracts in the chosen Blockchain.
test: the code that is generated in this folder will be executed as a test of the contracts that we make.
* scripts: directory containing other scripts of interest to the project.
* .env: project environment file where we can define global environment variables to be consulted by the project.

If we consult the "contracts" directory, we see that OpenSea proposes the example of creature development for the ERC 721 standard and creatures with more developed characteristics for the ERC 1155 format. Due to the nature of our project, we will take the first ones as a reference and start to analyze its composition.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155Tradable.sol";

contract Land is ERC1155Tradable {
    constructor(address _proxyRegistryAddress) ERC1155Tradable("Land", "LAND", "https://api/land/{id}", _proxyRegistryAddress) {}

    function contractURI() public pure returns (string memory) {
        return "https://api/contract/opensea-erc1155";
    }
}
```

This is the coding of the "Land.sol" contract that represents the existence of an NFT called "Land" which reflects a piece of land or lot. We note that it inherits the characteristics of an ERC 721 “Tradable” contract. This standard created by OpenSea assumes that our non-fungible token has the characteristics of an asset that can be exchanged with another user of the network as a result of a negotiation. However, we will later observe that the monetary value that an NFT possesses is not configured in the contract but is managed in an "Off Chain" way (outside the Blockchain) by OpenSea and its platform. Therefore, we should not worry about defining any amount at this point.

The contract defines parameters in its constructor that have to do with its name, initials and an address required by OpenSea to display the contract called “proxyRegistryAddress”. Another fundamental characteristic, not only of this contract but of any NFT, is the existence of a tokenURI. This element allows us to access the characteristics of the NFT and consult it, generally, in the form of a JSON. When consulting this JSON, we will observe all the attributes of that asset and it is the information that the OpenSea platform uses to show the characteristics of the deployed NFT. For example, in the case of our NFT Land, we could reference the lot's own characteristics, such as its ID, soil characteristics, an associated image, among others, through the tokenURI. It is not the subject of this article to develop a BackEnd that can be accessed to consult this information, but you can find it at this link. For our current purpose, we use the Interplanetary File System (IPFS) to store the corresponding JSON so that we can target it from code.

Another NFT of interest for this project is a chest that allows the buyer, at a given moment, to open it and mint new land or lots. This contract is called "LandLootBox.sol" and has the following characteristics:

```
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
```

As we can see, it is an ERC 721 Tradable contract just like "Land" but it has certain particular characteristics: a number of lands that the chest contains, a method to "unpack" the chest and release new Land units and the need to destroy the chest. unit chest once it is opened by the owner. It then has a tokenURI just like any other NFT and query methods.

Once we define the NFT Land and LandLootBox, their general attributes and their tokenURIs, we turn our attention to the development of a “Factory” contract. A contract of this type is used to execute operations to generate units of the NFT from certain predefined options. For example, we may want a user to access a predefined number of lots in a single purchase or access a chest that they can then “unpack” to access their NFTs. In order to do this, it is necessary to develop a “Factory” contract that is in charge of dealing with these options. The "LandFactory.sol" contract allows us to manage three options for generating a new NFT:

1. The buyer wants a single piece of land or lot.
2. The buyer wishes to access four lots.
3. The buyer wants to access a chest and by opening it in the future, access three new lots.

The Factory contract not only allows you to "mint" each of these three options but, in the particular case of our project, it manages the tokenURIs associated with each option in a particular way. Certain methods and structures remain from the original OpenSea Factory contract that allow the platform to manage its operations.

At this point, we have developed all the necessary contracts to manage this sale of NFTs on OpenSea. It should be noted that there are other base contracts in the repository but they are not addressed in this article since they are inherited from the OpenSea base project and have not been modified.

The next step is to run the project migrations and deploy our contracts to a testnet like Rinkeby. This network is one of several Ethereum test blockchains where a developer can publish their contracts before releasing them to the mainnet. You have to make sure you have funds on the Rinkeby testnet, using a "Faucet" or fund generator like the one found here is possible to solve this problem.

Within the project, we generate an environment variable file called “.env” and add certain parameters to be able to deploy our contracts:

```
export ALCHEMY_KEY=""
export MNEMONIC=""
export OWNER_ADDRESS=""
export NFT_CONTRACT_ADDRESS=""
export FACTORY_CONTRACT_ADDRESS=""
export NETWORK="rinkeby"
```

* **INFURA_KEY / ALCHEMY_KEY**: This parameter represents our Infura or Alchemy key. To obtain it, we create an account on one of these two platforms, create a new project and copy the "kye" of the project to place it in the .env file. If we want to use Alchemy, change the variable name to ALCHEMY_KEY.
* **MNEMONIC**: Represents the security phrase of our Metamask wallet. To know this phrase, we must have created a wallet in Metamask and access the security phrase in its configuration.
* **OWNER_ADDRESS**: Address of our Metamask wallet with which we will deploy the contracts.
NFT_CONTRACT_ADDRESS and * **FACTORY_CONTRACT_ADDRESS**: They represent the addresses of the contracts after we have deployed them. Once we execute the migrations, we must complete these fields with the addresses obtained in the deploy.
* **DEPLOY_LANDS_SALE**: Its value is 0 because, in this way, the OpenSea project interprets that we are in the presence of simple ERC 721 contracts and we do not want to add additional features.
* **NETWORK**: Defines the network in which we deploy the contracts.

Once these parameters are defined, we execute:

```
yarn truffle deploy --network rinkeby
```

We note that at the end of this process, all contracts were deployed to the Rinkeby network and corresponding addresses. Now it's time to check out our items for sale at OpenSea, who automatically senses the deployment of a new ERC 721 contract and displays it on their platform. To do this, we access the OpenSea test platform (because we deploy our contracts in Rinkeby) and accessing with the same wallet that we use for the deploy we observe the deployed tokens.

The three options that our Factory contract offers (single unit, four units and a LootBox sale) are now accessible from OpenSea. We only have to access each of them and stipulate a sale value for each option. Do you remember that we talked about the real monetary value of each option not being something to be defined in the contracts but something “Off Chain” in OpenSea? Well, this is the time to do it. Accessing the "Sell" option of the item, we can define its value and now it can be purchased by other users of the platform. We can also observe the characteristics of each article thanks to the JSON to which the tokenURI corresponding to each asset points and that we define in the contracts.

**We have created an NFT project from scratch and are ready to sell it through OpenSea!**