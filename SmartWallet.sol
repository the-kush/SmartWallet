// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/* Requirements:

The wallet has one owner
The wallet should be able to receive funds, no matter what
It is possible for the owner to spend funds on any kind of address, no matter if its a so-called Externally Owned Account (EOA - with a private key), or a Contract Address.
It should be possible to allow certain people to spend up to a certain amount of funds.
It should be possible to set the owner to a different address by a minimum of 3 out of 5 guardians, in case funds are lost.

*/
contract Consumer {

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() public {} 
}

contract SmartWallet {

    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable nextOwner;
    uint guardianResetCount;
    uint public constant conformationFromGuardianForReset = 3;
    mapping(address =>mapping(address => bool)) nextOwnerGuardianVotedBool;
    constructor() {
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _guardBool) public {
        require(msg.sender == owner,"Aborting! You are not the guardian");
        guardians[_guardian] = _guardBool;
    }

    function proposeNewGuardian(address payable _newOwner) public {
        require(guardians[msg.sender], "Aborting! You are not the guardian of this wallet");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false,"Aborting! You have already voted");
        if(nextOwner != _newOwner){
            nextOwner = _newOwner;
            guardianResetCount = 0;
        }
        guardianResetCount++;

        if(guardianResetCount >= conformationFromGuardianForReset){
            owner = nextOwner;
            nextOwner = payable((0));
        }
    }

    function setAllowance(address _for, uint _amount) public {
        require(msg.sender == owner,"Aborting! You are not the owner");
        allowance[_for] = _amount;
        //isAllowedToSend[_for] = true;
        if(_amount > 0){
            isAllowedToSend[_for] = true;
        }else{
            isAllowedToSend[_for] = false;
        }
    }

    function denySending(address _addr) public {
        require(msg.sender == owner, "Aborting! You are not the owner");
        isAllowedToSend[_addr] = false;
    }

    function transfer(address payable _to, uint _amount, bytes memory payload) public returns(bytes memory) {
        if(msg.sender != owner){
            require(isAllowedToSend[msg.sender], "Aborting!! you are not allowed to transfer");
            require(allowance[msg.sender] >= _amount,"Aborting! Not enough funds");
            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory callData) = _to.call{value: _amount}(payload);
        require(success,"Aborting! Could not transfer the funds");
        return callData;
    }

    receive() external payable {}
}