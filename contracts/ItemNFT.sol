//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ItemNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("newItem", "ITEM") {
    }

     function mintItem(address minter) public returns (uint256) {
        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        _mint(minter, newItemId);
        return newItemId;
    }
}