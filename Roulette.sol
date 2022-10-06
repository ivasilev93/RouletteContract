//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./safemath.sol";
import "./PriceConverter.sol";

error NotOwner();
error NotAllowed();
error BetTooLarge();

contract Roulette {
    address private constant rngAddress = 0xf6e4f7d98fb36adf03f7cc90f7a90b0fc2da2f69;
    using PriceConverter for uint256;
    using SafeMath for uint256;
    
    uint8 private constant STRAIGHT_UP_BET_MULTIPLIER = 35; // stored on contract's bytecode, not on storage
    uint8 private constant RED_BALCK_BET_MULTIPLIER = 2; // stored on contract's bytecode, not on storage
    address public immutable i_owner; // stored on contract's bytecode, not on storage
    uint256 contractBalance;

    event RedBlackEvent(
        string betColor,
        string rolledColor,
        uint256 betAmount,
        uint256 wonAmount,
        address indexed _to
    );
    event StraightUpEvent(
        uint8 betNumber,
        uint8 rolledNumber,
        uint256 betAmount,
        uint256 wonAmount,
        address indexed _to
    );

    enum Color {
        Red,
        Black,
        Green
    }

    mapping(uint8 => Color) private slots;
    mapping(Color => string) private colors;

    constructor() {
        i_owner = msg.sender;
        slots[0] = Color.Green;
        slots[1] = Color.Red;
        slots[2] = Color.Black;
        slots[3] = Color.Red;
        slots[4] = Color.Black;
        slots[5] = Color.Red;
        slots[6] = Color.Black;
        slots[7] = Color.Red;
        slots[8] = Color.Black;
        slots[9] = Color.Red;
        slots[10] = Color.Black;
        slots[11] = Color.Black;
        slots[12] = Color.Red;
        slots[13] = Color.Black;
        slots[14] = Color.Red;
        slots[15] = Color.Black;
        slots[16] = Color.Red;
        slots[17] = Color.Black;
        slots[18] = Color.Red;
        slots[19] = Color.Red;
        slots[20] = Color.Black;
        slots[21] = Color.Red;
        slots[22] = Color.Black;
        slots[23] = Color.Red;
        slots[24] = Color.Black;
        slots[25] = Color.Red;
        slots[26] = Color.Black;
        slots[27] = Color.Red;
        slots[28] = Color.Black;
        slots[29] = Color.Black;
        slots[30] = Color.Red;
        slots[31] = Color.Black;
        slots[32] = Color.Red;
        slots[33] = Color.Black;
        slots[34] = Color.Red;
        slots[35] = Color.Black;
        slots[36] = Color.Red;

        colors[Color.Red] = "RED";
        colors[Color.Black] = "BLACK";
        colors[Color.Green] = "GREEN";
    }

    function maxRedBlackBetInWEI() public view returns(uint256) {
        return (address(this).balance / RED_BALCK_BET_MULTIPLIER);
    }

    function maxStraightUpBetInWEI() public view returns(uint256) {
        return (address(this).balance / STRAIGHT_UP_BET_MULTIPLIER);
    }

    
    function fund() external payable onlyOwner {
        contractBalance += msg.value;
    }

    function withdraw() public onlyOwner {

        //transfer - (2300 gas, throws error) - throws error if transaction fails somehow
        //payable(msg.sender).transfer(address(this).balance);

        //send - (2300 gas, returns bool)
       // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require (sendSuccess, "Send failed"); // this is mandatory with send to revert transaction

        //call - forward all gas or set get, returns bool
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        contractBalance -= address(this).balance;
    }

    function placeRedBlackBet(string calldata _color) external payable {
        uint256 betValue = msg.value;
        if (betValue < (contractBalance / RED_BALCK_BET_MULTIPLIER)) { revert BetTooLarge(); }

        bytes32 colorInputHash = keccak256(abi.encodePacked(_color));
        bytes32 colorRedHash = keccak256(abi.encodePacked("RED"));
        bytes32 colorBlackHash = keccak256(abi.encodePacked("BLACK"));
        require(
            colorInputHash == colorRedHash || colorInputHash == colorBlackHash
        );

        Color color;
        if (colorInputHash == colorRedHash) {
            color = Color.Red;
        } else {
            color = Color.Black;
        }

        (Color winningColor, ) = roll();

        uint256 wonAmount = 0;

        if (winningColor == color) {
            wonAmount = betValue.mul(RED_BALCK_BET_MULTIPLIER);
            // send won amount
            (bool sent, ) = msg.sender.call{value: wonAmount}(
                ""
            );
            require(sent, "Failed to pay prize in Ether");
        }        
        else {
            contractBalance += msg.value;
        }

        emit RedBlackEvent(
            _color,
            colors[winningColor],
            betValue,
            wonAmount,
            msg.sender
        );
    }

    function placeStraightUpBet(uint8 number) external payable {
        uint256 betValue = msg.value;
        require(number >= 0 && number < 37);        
        if (betValue < (contractBalance / STRAIGHT_UP_BET_MULTIPLIER)) { revert BetTooLarge(); }
        (, uint8 winningNumber) = roll();
        uint256 wonAmount = 0;
        if (winningNumber == number) {
            wonAmount = betValue.mul(STRAIGHT_UP_BET_MULTIPLIER);
            // send won amount
            (bool sent, ) = msg.sender.call{value: wonAmount}(
                ""
            );
            require(sent, "Failed to pay prize in Ether");
        }
        else {
            //put amount in account

        }

        emit StraightUpEvent(
            number,
            winningNumber,
            betValue,
            wonAmount,
            msg.sender
        );
    }

    function roll() private view returns (Color _color, uint8 _winningNumber) {
        //uint8 number = random 0 do 37;
        uint8 winningNumber = 7; // to be replaced with chainling call
        Color color = slots[winningNumber];

        return (color, winningNumber);
    }

    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) { revert NotOwner(); } // in solidity ^0.8.4 saves gas, cuz string is not emited
        _;
    }

    //in solidity eth can be sent without calling functions directly...
    //this functions gets called when contract is called without function spicified.. A contract can have at most one receive function.
    receive() external payable {
        //we can route here to other functions 
        revert NotAllowed();
    }

    //called when caller have specfied wrong function name somehow (usually via low leverl interactions?)
    fallback() external payable {
        //we can route here to other functions 
        revert NotAllowed();
    }
}
