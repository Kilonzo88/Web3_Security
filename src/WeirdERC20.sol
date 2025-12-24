// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title USDT "Missing Return Value" Vulnerability Demo
 * @dev This contract demonstrates why standard IERC20 interfaces fail with USDT.
 */

interface IERC20_Standard {
    // The standard expects a boolean return
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IUSDT_Actual {
    // How USDT actually looks on-chain (No return value)
    function transferFrom(address from, address to, uint256 value) external;
}

contract USDTBugDemo {
    // USDT Mainnet Address: 0xdAC17F958D2ee523a2206206994597C13D831ec7
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /**
     * @notice THIS WILL FAIL with USDT.
     * Even if the transfer is successful, the EVM will revert here because
     * it expects 32 bytes of return data (the bool) but receives 0.
     */
    function vulnerableDeposit(uint256 amount) external {
        bool success = IERC20_Standard(USDT).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
    }

    /**
     * @notice THE FIX: Using SafeERC20 or low-level calls.
     * OpenZeppelin's SafeERC20 handles the 'missing return value' by 
     * checking if the call succeeded via opcode rather than return data.
     */
    function secureDeposit(uint256 amount) external {
        // Low-level call ignores the missing return value
        (bool success, bytes memory data) = USDT.call(
            abi.encodeWithSelector(IERC20_Standard.transferFrom.selector, msg.sender, address(this), amount)
        );
        
        // We check: 
        // 1. Did the call revert? (success)
        // 2. If it returned data, is it a true boolean? (USDT returns nothing, so data.length == 0)
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }
}