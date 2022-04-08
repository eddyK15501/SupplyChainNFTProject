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

  item1 = await new ethers.Contract(itemAddress1, abi, account0);

  expect(await item1.index()).to.eq(0);
  expect(await item1.priceInWei()).to.eq(utils.parseEther('0.1'));
});

describe("ItemManager: createItem function", () => {
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
});