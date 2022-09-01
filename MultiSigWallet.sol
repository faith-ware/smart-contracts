// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract MultiSigWallet {

    event SubmitEvent(uint indexed txId);
    event DepositEvent(address indexed sender, uint amount);
    event ApproveEvent(uint indexed txId);
    event RevokeEvent(address indexed owner, uint indexed txId);
    event ExecuteEvent(address indexed owner, uint txId);

    address[] public owners;
    uint requiredSig;

    struct Transaction {
        address to;
        uint amount;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(address => bool) isOwner;
    mapping(uint => mapping(address => bool)) approved;

    modifier onlyOwner {
        require(isOwner[msg.sender], "You are not an owner");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!(approved[_txId][msg.sender]), "transaction already approved");
        _;
    }

    modifier isApproved(uint _txId) {
        require(checkApproval(_txId) >= requiredSig, "Transaction not approved");
        _;
    }

    modifier notExeuted(uint _txId) {
        require(!(transactions[_txId].executed), "Transaction executed");
        _;
    }

    constructor(address[] memory _owners, uint _requiredSig) {
        require(_requiredSig >= 2, "Required signature must be more than 1");
        for (uint singleOwner; singleOwner < _owners.length; singleOwner++) {
            address owner = _owners[singleOwner];
            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredSig = _requiredSig;
    }

    // function to create a new transaction
    function submitTransaction(address _to, uint _amount) public onlyOwner {
        transactions.push(Transaction({
            to : _to,
            amount : _amount,
            executed : false
        }));

        emit SubmitEvent(transactions.length - 1);
    }

    // function to approve a new transaction
    function approveTransaction(uint _txId) public onlyOwner notApproved(_txId) notExeuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit ApproveEvent(_txId);
    }

     // function to approve a new transaction
    function revokeApproval(uint _txId) public onlyOwner notExeuted(_txId) {
        require(approved[_txId][msg.sender], "transaction not approved");
        approved[_txId][msg.sender] = false;
        emit RevokeEvent(msg.sender, _txId);
    }

    // check if a particular trasaction has been approved
    function checkApproval(uint _txId) private view onlyOwner returns(uint approvalNum) {
        for(uint i; i < owners.length; i++) {
            if(approved[_txId][owners[i]]) {
                approvalNum += 1;
            }
        }

        return approvalNum;
    }

    // function to execute a transaction
    function executeTransaction(uint _txId) public onlyOwner isApproved(_txId) notExeuted(_txId) {
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.amount}("");
        require(success, "transaction failed");
        emit ExecuteEvent(msg.sender, _txId);
    }

    receive() external payable {
        emit DepositEvent(msg.sender, msg.value);
    }

}