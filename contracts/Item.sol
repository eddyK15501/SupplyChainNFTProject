//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ItemManager.sol";
import "./ItemNFT.sol";

interface ItemManagerInterface {
    function triggerDelivery(uint _itemIndex) external;
}

contract Item is ItemNFT {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;
    address public seller;
    address public buyer;
     
    ItemManager parentContract;

    event DeliverToAddress(address _buyer);

    constructor(ItemManager _parentContract, uint _priceInWei, uint _index, address _seller) {
        parentContract = _parentContract;
        priceInWei = _priceInWei;
        index = _index;
        seller = _seller;
        
        mintItem(seller);
    }

   receive() external payable {
        require(pricePaid == 0, "Item is paid already");
        require(msg.value == priceInWei, "Please pay the correct amount");
        pricePaid += msg.value;
        buyer = msg.sender;

        (bool success,) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success, "The transaction wasn't successful...Canceling");
    }

    function deliverItem() external {
        require(msg.sender == buyer, "You are not the buyer");
        ItemManagerInterface(address(parentContract)).triggerDelivery(index);

        _transfer(seller, buyer, index + 1);

        emit DeliverToAddress(buyer);
    }

    fallback() external {}

}
