//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;


contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount);
      event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);
    event TransactionRevoked(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;
   
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 confirmations;
        bytes data;
    }
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }
    modifier notConfirmed(uint256 _txId) {
        require(!confirmed[_txId][msg.sender], "Transaction already confirmed");
        _;
    }
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number of confirmations");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address _to, uint256 _value) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            executed: false,
            confirmations: 0,
            data: "" 
        }));
      
        uint256 txId = transactions.length - 1;
        emit TransactionSubmitted(txId, _to, _value);
    }
    function confirmTransaction(uint256 _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
        notConfirmed(_txId) 
    {
        Transaction storage transaction = transactions[_txId];
        transaction.confirmations += 1;
        confirmed[_txId][msg.sender] = true;

        emit TransactionConfirmed(_txId, msg.sender);

       
       
    }
    function revokeConfirmation(uint256 _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(confirmed[_txId][msg.sender], "Transaction not confirmed");

        Transaction storage transaction = transactions[_txId];
        transaction.confirmations -= 1;
        confirmed[_txId][msg.sender] = false;

        emit TransactionRevoked(_txId, msg.sender);
    }
    function executeTransaction(uint256 _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        Transaction storage transaction = transactions[_txId];
        require(transaction.confirmations >= required, "Not enough confirmations");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "Transaction execution failed");

        emit TransactionExecuted(_txId);
    }
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
    function getTransaction(uint256 _txId) 
        public 
        view 
        returns (
            address to, 
            uint256 value, 
            bool executed, 
            bytes memory data,
            uint256 confirmations
        ) 
    {
        Transaction storage transaction = transactions[_txId];
        return (transaction.to, transaction.value, transaction.executed, transaction.data, transaction.confirmations);
    }
}
