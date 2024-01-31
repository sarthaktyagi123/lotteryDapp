//SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

contract Lottery{
    //State /Storage Variable
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    //Constructor runs when the cintract is deployed
    constructor(){
        owner= msg.sender;
        lotteryId = 0;
    }

    //Enter Function to enter in lottery
    function enter()public payable{
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    //Get Players
    function  getPlayers() public view returns(address payable[] memory){
        return players;
    }

    //Get Balance 
    function getbalance() public view returns(uint){
        return address(this).balance;
    }
     
    //Get Lottery Id
    function getLotteryId() public view returns(uint){
        return lotteryId;
    }
    
    //Get a random number (helper function for picking winner)
    function getRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(owner,block.timestamp)));
    }

    //Pick Winner
    function pickWinner() public onlyOwner{
        uint randomIndex =getRandomNumber()%players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]);
        //Current lottery done
        lotteryId++;
        //Clear the player array
        players =new address payable[](0);
    }
  
    function getWinners() public view returns(address[] memory){
        return winners;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner have control");
        _;
    }

}

// SPDX-License-Identifier: MIT
const Lottery = artifacts.require("Lottery");

contract("Lottery", (accounts) => {
  let lotteryInstance;

  // Deploy the Lottery contract before each test
  beforeEach(async () => {
    lotteryInstance = await Lottery.new(
      // Pass Chainlink VRF Coordinator, LINK token, keyHash, and fee parameters
    );
  });

  it("should allow participants to enter the lottery", async () => {
    await lotteryInstance.enter({ from: accounts[1], value: web3.utils.toWei("0.1", "ether") });
    const players = await lotteryInstance.getPlayers();
    assert.equal(players.length, 1, "Participant not added to the lottery");
  });

  it("should not allow participants with insufficient funds to enter", async () => {
    try {
      await lotteryInstance.enter({ from: accounts[1], value: web3.utils.toWei("0.09", "ether") });
      assert.fail("Transaction should have thrown an exception");
    } catch (error) {
      assert.include(
        error.message,
        "revert",
        "Transaction should be reverted due to insufficient funds"
      );
    }
  });

  it("should allow the owner to pick a winner", async () => {
    // Assuming at least one participant has entered
    await lotteryInstance.enter({ from: accounts[1], value: web3.utils.toWei("0.1", "ether") });
    
    const initialBalance = await web3.eth.getBalance(accounts[1]);

    // Note: Add Chainlink VRF mock or set up a specific randomness value for testing
    await lotteryInstance.pickWinner();

    const finalBalance = await web3.eth.getBalance(accounts[1]);
    const winners = await lotteryInstance.getWinners();

    assert.isAbove(finalBalance, initialBalance, "Winner should receive funds");
    assert.equal(winners.length, 1, "Winner not added to the list");
  });

  // Additional test cases can be added to cover other functions and scenarios

  // ...

});
