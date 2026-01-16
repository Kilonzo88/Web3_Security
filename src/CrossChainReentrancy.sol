// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Bridge contract (simplified)
interface IBridge {
    function sendMessage(uint256 chainId, address recipient, uint256 amount) external;
}

// Contract on Ethereum mainnet
contract EthereumVault {
    mapping(address => uint256) public balances;
    address public bridge;
    
    constructor(address _bridge) {
        bridge = _bridge;
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // VULNERABLE: Cross-chain withdrawal
    function withdrawCrossChain(uint256 amount, uint256 destinationChainId) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Send message to bridge BEFORE updating state
        IBridge(bridge).sendMessage(
            destinationChainId,
            msg.sender,
            amount
        );
        
        // State update happens too late!
        balances[msg.sender] -= amount;
    }
}

// Contract on Arbitrum/Optimism/Polygon
contract L2Receiver {
    address public bridge;
    mapping(address => uint256) public receivedFunds;
    
    constructor(address _bridge) {
        bridge = _bridge;
    }
    
    // Called by bridge when message arrives from L1
    function receiveFromL1(address recipient, uint256 amount) external {
        require(msg.sender == bridge, "Only bridge");
        receivedFunds[recipient] += amount;
        
        // Callback to recipient (potential reentrancy point)
        if (isContract(recipient)) {
            (bool success, ) = recipient.call(
                abi.encodeWithSignature("onCrossChainReceived(uint256)", amount)
            );
            require(success, "Callback failed");
        }
    }
    
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IEthereumVault {
    function deposit() external payable;
    function withdrawCrossChain(uint256 amount, uint256 chainId) external;
}

// Attacker contract on Ethereum
contract L1Attacker {
    IEthereumVault public vault;
    uint256 public attackCount;
    
    constructor(address _vault) {
        vault = IEthereumVault(_vault);
    }
    
    function depositAndAttack() external payable {
        vault.deposit{value: msg.value}();
        
        // Initiate multiple cross-chain withdrawals
        // before the first one completes and updates state
        vault.withdrawCrossChain(msg.value, 42161); // Arbitrum
        vault.withdrawCrossChain(msg.value, 10);    // Optimism
        vault.withdrawCrossChain(msg.value, 137);   // Polygon
        
        // All three withdrawals see the same balance!
    }
}

// Attacker contract on L2 (Arbitrum)
contract L2Attacker {
    address public l1Attacker;
    
    constructor(address _l1Attacker) {
        l1Attacker = _l1Attacker;
    }
    
    // Called by L2Receiver
    function onCrossChainReceived(uint256 amount) external {
        // Could trigger another cross-chain message back
        // or initiate new attack vector
    }
    
    function withdraw() external {
        payable(l1Attacker).transfer(address(this).balance);
    }
}

contract SecureEthereumVault {
    mapping(address => uint256) public balances;
    mapping(bytes32 => bool) public processedMessages;
    address public bridge;
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    constructor(address _bridge) {
        bridge = _bridge;
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // FIXED: Update state BEFORE cross-chain call
    function withdrawCrossChain(
        uint256 amount,
        uint256 destinationChainId,
        uint256 nonce
    ) external noReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Create unique message ID
        bytes32 messageId = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            destinationChainId,
            nonce
        ));
        require(!processedMessages[messageId], "Already processed");
        
        // Update state FIRST (CEI pattern)
        balances[msg.sender] -= amount;
        processedMessages[messageId] = true;
        
        // Then send cross-chain message
        IBridge(bridge).sendMessage(
            destinationChainId,
            msg.sender,
            amount
        );
    }
}
