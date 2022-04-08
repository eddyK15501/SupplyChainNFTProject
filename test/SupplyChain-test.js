const chai = require('chai');
const { utils } = require('ethers');
const { ethers } = require('hardhat');
const { solidity } = require('ethereum-waffle');
const { abi } = require('../artifacts/contracts/Item.sol/Item.json');

chai.use(solidity);
const { expect } = chai;

let itemManager;
let itemAddress1;
let item1;

beforeEach(async () => {
  [account0, account1, account2, account3] = await ethers.getSigners();

  const ItemManager = await ethers.getContractFactory("ItemManager");
  itemManager = await ItemManager.deploy();
  await itemManager.deployed();

  console.log("ItemManager contract deployed to: ", itemManager.address);

  await itemManager.connect(account0).createItem('lamp', utils.parseEther('0.1'));

  itemAddress1 = (await itemManager.items(0))._item;
  console.log("New Item contract address: ", itemAddress1);

  item1 = await new ethers.Contract(itemAddress1, abi, account0);   //create an item contract for testing convenience

  expect(await item1.index()).to.eq(0);
  expect(await item1.priceInWei()).to.eq(utils.parseEther('0.1'));
});

describe("createItem", () => {
  it('can create a new item', async () => {
    expect((await itemManager.items(0))._item).to.eq(itemAddress1);
    expect((await itemManager.items(0))._identifier).to.eq('lamp');
    expect((await itemManager.items(0))._itemPrice).to.eq(utils.parseEther('0.1'));
  });

  it('emits an event when creating an item', async () => {
    expect(await itemManager.connect(account0).createItem('painting', utils.parseEther('0.8')))
      .to.emit(itemManager, "SupplyChainStep")
      .withArgs(1, 0, (await itemManager.items(1))._item);
  });

  it('increments the index count', async () => {
    await itemManager.connect(account1).createItem('painting', utils.parseEther('0.8'));
    expect(await itemManager.itemIndex()).to.eq(2);
  });

  it('mints an NFT token to the creator of the item', async () => {
    expect(await item1.ownerOf(1)).to.eq(account0.address);
  });

  it('name of the NFT token is correct', async () => {
    expect(await item1.name()).to.eq('newItem');
  });

  it('symbol of the NFT token is correct', async () => {
    expect(await item1.symbol()).to.eq('ITEM');
  });

  it('balance of token creator is correct', async () => {
    expect(await item1.balanceOf(account0.address)).to.eq(1);
  });
});

describe("triggerPayment", () => {
  it('cannot call the triggerPayment function from within the ItemManager contract', async () => {
    await expect(itemManager.connect(account1).triggerPayment(0))
        .to.be.revertedWith("You must call this function from the Item Contract");
  });

  it('you must pay the correct amount for the item', async () => {
      const transaction = account1.sendTransaction({
        to: item1.address,
        value: utils.parseEther('0.05')
    });
      await expect(transaction).to.be.revertedWith("Please pay the correct amount");

      const transaction2 = account1.sendTransaction({
        to: item1.address,
        value: utils.parseEther('0.5')
    });
      await expect(transaction2).to.be.revertedWith("Please pay the correct amount");
  });

  it('can emit an event after paying for the item', async () => {
      const transaction = account1.sendTransaction({
        to: item1.address,
        value: utils.parseEther('0.1')
    });
      expect(transaction)
      .to.emit(itemManager, "SupplyChainStep")
      .withArgs(0, 1, (await itemManager.items(0))._item);
  });
});
