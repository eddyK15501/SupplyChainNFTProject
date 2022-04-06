//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ItemManager.sol";
import "./ItemNFT.sol";

contract Item is ItemNFT {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;
    address public minter;
     
    ItemManager parentContract;

    constructor(ItemManager _parentContract, uint _priceInWei, uint _index, address _minter) {
        parentContract = _parentContract;
        priceInWei = _priceInWei;
        index = _index;
        minter = _minter;
        
        mintItem(minter);
    }

    receive() external payable {
        require(pricePaid == 0, "Item is paid already");
        require(msg.value == priceInWei, "Only full payments allowed");
        pricePaid += msg.value;

        (bool success,) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success, "The transaction wasn't successful...Canceling");
    }

    fallback() external {}
}
