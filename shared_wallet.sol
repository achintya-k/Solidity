pragma solidity ^0.5.0;

contract SharedWallet{
    
    address private _owner;
    mapping(address => bool) private _owners;
    
    event DepositAmount(address _from, uint amount);
    event WithdrawAmount(address _to, uint amount);
    event TransferAmount(address _from, address _to, uint amount);
    
    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    modifier validOwner() {
        require(msg.sender == _owner || _owners[msg.sender] == true);
        _;
    }
    
    function sharedWallet() public{
        _owner = msg.sender;
    }
    
    function addOwner(address newOwner) public isOwner{
        _owners[newOwner] = true;
    }
    
    function removeOwner(address existingOwner) public isOwner{
        _owners[existingOwner] = false;
    }
    
    function deposit(uint amount) public payable validOwner{
        emit DepositAmount(msg.sender, amount);
    }
    
    function withdraw(uint amount) public validOwner{
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
        emit WithdrawAmount(msg.sender, amount);
    }
    
    function transferTo(address payable reciever, uint amount) public validOwner{
        require(address(this).balance >= amount);
        reciever.transfer(amount);
        emit TransferAmount(msg.sender, reciever, amount);
    }
}