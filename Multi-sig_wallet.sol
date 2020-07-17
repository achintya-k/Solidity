pragma solidity ^0.5.0;

contract MultisigWallet {
    
    address[] public owners; //the array of addresses of the owners
    mapping(address => bool) public isOwner; //mapping to check if one is a valid owner
    uint public numConfirmationsRequired; //number of confirmations needed to validate a transaction as decided by the owners
    
    //events for logging transactions to the blockchain
    event Deposit(address sender, uint amount, uint balance);
    event SubmitTransaction(address sender, address _to, uint value, bytes data, uint txIndex);
    event ConfirmTransaction(address sender, uint txIndex);
    event ExecuteTransaction(address sender, uint txIndex);
    event RevokeConfirmation(address sender, uint txIndex);
    
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
        mapping(address => bool) isConfirmed;
    }
    
    Transaction[] public transactions;
    
    constructor(address[] memory _owners, uint _numConfirmationsRequired) public {
        require(_owners.length > 0, "number of owners has to be a positive number");
        require(_numConfirmationsRequired>0 && _numConfirmationsRequired <= _owners.length, "invalid number of confirmations");
        
        for (uint i=0; i<_owners.length; i++){
            address owner = _owners[i];
            require(!isOwner[owner], "owner isn't unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }
    
    function () payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    // modifiers to check on various conditions
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "only owners can access this");
        _;
    }
    
    modifier txExists(uint _txIndex) { 
        require(_txIndex < transactions.length, "invalid transaction index");
        _;
    }
    
    modifier NotExecuted(uint _txIndex) { 
        require(!transactions[_txIndex].executed, "transaction already executed");
        _;
    }
    
    modifier NotConfirmed(uint _txIndex) {
        require(!transactions[_txIndex].isConfirmed[msg.sender], "transaction already confirmed");
        _;
    }
    
    //function for appending/submitting/proposing a transaction to the owners 
    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner() {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));
        emit SubmitTransaction(msg.sender, _to, _value, _data, txIndex);
    }
    
    //function for owners to confirm transactions
    function confirmTransaction(uint txIndex) public onlyOwner() txExists(txIndex) NotExecuted(txIndex) NotConfirmed(txIndex) {
        Transaction storage transaction = transactions[txIndex];
        
        transaction.isConfirmed[msg.sender] = true;
        transaction.numConfirmations += 1;
        emit ConfirmTransaction(msg.sender, txIndex);
    }
    
    //function to execute a transaction 
    function executeTransaction(uint txIndex) public onlyOwner() txExists(txIndex) NotExecuted(txIndex) {
        Transaction storage transaction = transactions[txIndex];
        
        (bool success, ) = transaction.to.call.value(transaction.value)(transaction.data);
        require(success, "tx couldn't be executed");
        transaction.executed = true;
        emit ExecuteTransaction(msg.sender, txIndex);
    }
    
    //function to revoke a confirmed transaction if the owners reach a consensus
    function revokeConfirmation(uint txIndex) public onlyOwner() txExists(txIndex) NotExecuted(txIndex) {
        Transaction storage transaction = transactions[txIndex];
        require(transaction.isConfirmed[msg.sender], "transaction not yet confirmed");
        
        transaction.isConfirmed[msg.sender] = false;
        transaction.numConfirmations -= 1;
        emit RevokeConfirmation(msg.sender, txIndex);
    }
}