//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Item.sol";

contract ItemManager {
    address itemCreator;

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

    function createItem(string memory _identifier, uint _itemPrice) public {
        itemCreator = msg.sender;
        Item item = new Item(this, _itemPrice, itemIndex, itemCreator);
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
        items[_itemIndex]._state = SupplyChainState.Paid;

        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }

    function triggerDelivery(uint _itemIndex) external {
        require(address(items[_itemIndex]._item) == msg.sender, "Only items are allowed to update themselves");
        require(items[_itemIndex]._state == SupplyChainState.Paid, "Cost of item has not been paid");
        items[_itemIndex]._state = SupplyChainState.Delivered;

        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }
}