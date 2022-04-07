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
    address buyer;
     
    ItemManager parentContract;

    constructor(ItemManager _parentContract, uint _priceInWei, uint _index, address _seller) {
        parentContract = _parentContract;
        priceInWei = _priceInWei;
        index = _index;
        seller = _seller;
        
        mintItem(seller);
    }

    function payForItem(uint _amount) public payable {
        require(pricePaid == 0, "Item is paid already");
        require(_amount == priceInWei, "Only full payments allowed");
        pricePaid += _amount;

        (bool success,) = address(parentContract).call{value:_amount}(abi.encodeWithSignature("triggerPayment(uint256)", index, msg.sender));
        require(success, "The transaction wasn't successful...Canceling");

        buyer = msg.sender;
    }

    function deliverItem() public {
        ItemManagerInterface(address(parentContract)).triggerDelivery(index);
        safeTransferFrom(seller, buyer, index);
    }

    fallback() external {}
}
