// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**@title A NFT Market Place
 * @author Jay Makwana
 * @author Rajiv Isharni
 * @notice This contract is for creating a NFT Market Place contract
 * @dev This implements the OpenZeppelin's Counters, and the basic standard multi-token(ERC1155).
 */

contract market is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    mapping(uint256 => string) private _uris;
    mapping(address => uint256[]) mintArray;
    mapping(address => uint256[]) buy;
    mapping(uint256 => bytes32) ownerHash;
    mapping(uint256 => bytes32) userHash;

    constructor() public ERC1155("{id}") {
        _mint(msg.sender, 0, 1, "");
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable owner;
        uint256 price;
    }

    MarketItem[] Marketplace;
    MarketItem[] resellItem;

    function tokenID() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mint(
        uint256 amount,
        string memory _uri,
        uint256 price
    ) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId, amount, "");
        _uris[newTokenId] = _uri;
        createMarketItem(newTokenId, price, amount);
        _setApprovalForAll(msg.sender, address(this), true);
        mintArray[msg.sender].push(newTokenId);
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return (_uris[_tokenId]);
    }

    function createMarketItem(
        uint256 _tokenId,
        uint256 _price,
        uint256 amount
    ) private {
        require(amount > 0, "You have to mint altleast 1 NFT");
        Marketplace.push(
            MarketItem({tokenId: _tokenId, owner: payable(msg.sender), price: _price})
        );
        idToMarketItem[_tokenId] = MarketItem({
            tokenId: _tokenId,
            owner: payable(msg.sender),
            price: _price
        });
    }

    function getmarketPlace() public view returns (MarketItem[] memory) {
        return Marketplace;
    }

    function buyNFT(uint256 _tokenId, address _owner) public {
        require(balanceOf(_owner, _tokenId) > 0, "Owner is not owner of NFT");
        require(isApprovedForAll(_owner, address(this)), "Caller is not approved");
        _safeTransferFrom(_owner, msg.sender, _tokenId, 1, "");

        payable(_owner).transfer(idToMarketItem[_tokenId].price);
        buy[msg.sender].push(_tokenId);
    }

    function resell(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) public {
        require(balanceOf(msg.sender, _tokenId) >= _amount, "Owner doesnot own");
        createresellMarketItem(_tokenId, _price, _amount);
        safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        for (uint256 i = 0; i < buy[msg.sender].length; i++) {
            if (buy[msg.sender][i] == _tokenId) {
                delete buy[msg.sender][i];
                break;
            }
        }
    }

    function createresellMarketItem(
        uint256 _tokenId,
        uint256 _price,
        uint256 amount
    ) private {
        require(amount > 0, "You have to mint altleast 1 NFT");
        resellItem.push(MarketItem({tokenId: _tokenId, owner: payable(msg.sender), price: _price}));
    }

    function fetchMyBuyNft() public view returns (uint256[] memory) {
        return buy[msg.sender];
    }

    function GenerateOwnerHash(uint256 _tokenId, address _owner) private returns (bytes32) {
        ownerHash[_tokenId] = keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, _owner)
        );
    }

    function TokenDetails(uint256 _tokenId) public view returns (MarketItem memory) {
        return idToMarketItem[_tokenId];
    }
}
