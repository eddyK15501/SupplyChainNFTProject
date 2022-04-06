//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Item.sol";
import "./ItemNFT.sol";

contract ItemManager is ItemNFT {
    address buyer;
    address seller;

    enum SupplyChainState{Created, Paid, Delivered}

    struct S_Item {
        Item _item;
        string _identifier;
        uint _itemPrice;
        ItemManager.SupplyChainState _state;
    }

    mapping(uint => S_Item) public items;
    uint itemIndex;

    event SupplyChainStep(uint _itemIndex, uint _step, address _itemAddress);
    event DeliverToAddress(address _buyer);

    function createItem(string memory _identifier, uint _itemPrice) public {
        seller = msg.sender;
        Item item = new Item(this, _itemPrice, itemIndex, seller);
        items[itemIndex]._item = item;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = SupplyChainState.Created;
        emit SupplyChainStep(itemIndex, uint(items[itemIndex]._state), address(item));

        itemIndex++;
    }

    function triggerPayment(uint _itemIndex) public payable {
        Item item = items[_itemIndex]._item;
        require(address(item) == msg.sender, "Only items are allowed to update themselves");
        require(item.priceInWei() == msg.value, "Please pay the correct amount");
        require(items[_itemIndex]._state == SupplyChainState.Created, "Item is further along in the chain");
        buyer = msg.sender;
        items[_itemIndex]._state = SupplyChainState.Paid;

        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }

    function triggerDelivery(uint _itemIndex) public {
        require(items[_itemIndex]._state == SupplyChainState.Paid, "Cost of item has not been paid");
        safeTransferFrom(seller, buyer, _itemIndex);
        items[_itemIndex]._state = SupplyChainState.Delivered;

        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
        emit DeliverToAddress(buyer);
    }
}