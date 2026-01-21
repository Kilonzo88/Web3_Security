# Vulnerability: Weird ERC20 - Missing Return Value (USDT Case)
## Description
A significant number of early ERC20 tokens do not strictly follow the EIP-20 standard. The most notable example is USDT (Tether) on the Ethereum mainnet. While the standard dictates that functions like transfer, transferFrom, and approve should return a boolean (true on success), these tokens return nothing (void).

As of December 2025, this remains the case for USDT. The contract is immutable and contains billions in liquidity; migrating to a standard-compliant version would break thousands of existing integrations, so the "non-standard" behavior is now a permanent feature of the DeFi ecosystem.

## Technical Root Cause
The issue arises from a mismatch between the Interface used by a calling contract and the Implementation of the token contract.

The Standard (EIP-20): Expects returns (bool).

The USDT Implementation: Omitted the return statement in its 2017 deployment.

The EVM Conflict: When a Solidity contract (compiled with version 0.4.22 or higher) calls a function that specifies a return type, the compiler generates a check for RETURNDATASIZE. Since USDT returns 0 bytes instead of 32 bytes (a boolean), the check fails and the entire transaction reverts, even if the transfer actually succeeded.

## Affected Tokens
USDT (Tether): Missing return on transfer, transferFrom, and approve.

BNB: Missing return on transfer.

OMG: Missing return on multiple functions.

**Note** : There are many others and I will add them with time

##  Vulnerable Code Example
Using a standard interface will cause transactions to fail when interacting with USDT.

Solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20_Standard {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Vault {
    // This function will REVERT when 'token' is USDT
    function deposit(address token, uint256 amount) external {
        // EVM expects a bool return here, but USDT returns nothing.
        bool success = IERC20_Standard(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
    }
}

## Recommended Mitigation
Use a "Safe Wrapper" library like OpenZeppelin's SafeERC20. These libraries use low-level calls (.call()) which ignore the return data size and instead manually check if the call succeeded and if any returned data (if present) decodes to true.

Solidity

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SecureVault {
    using SafeERC20 for IERC20;

    function deposit(IERC20 token, uint256 amount) external {
        // safeTransferFrom handles the missing return value automatically
        token.safeTransferFrom(msg.sender, address(this), amount);
    }
}
## Further Research: The "Weird-ERC20" Repository
 On newer chains like Base or Hedera, the tokens are either "Bridged" assets (which use modern OpenZeppelin-based templates) or are managed by a protocol system (like Hedera Token Service) that enforces the standard interface. That means they return a bool in this newer chains. It's important to DYOR on the chain you're implementing on

On legacy chains like Ethereum L1, this vulnerability is part of a broader class of token behaviors known as "Weird ERC20s." For a complete list of tokens that break standard assumptions (including fee-on-transfer, rebasing, and approval race conditions), refer to the industry-standard repository:

🔗 Official Weird-ERC20 GitHub Repository



## Key Takeaway 
When auditing any protocol that accepts arbitrary ERC20 tokens, the absence of SafeERC20 (or a custom low-level wrapper) should be flagged as a Medium to High severity finding, as it leads to a permanent Denial of Service (DoS) for the most liquid stablecoin in the market (USDT).