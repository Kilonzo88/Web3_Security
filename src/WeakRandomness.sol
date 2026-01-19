// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WeakRandomness
 * @dev This contract demonstrates a common vulnerability where weak sources of randomness
 * are used for critical logic (like a lottery or game).
 * 
 * Sources of "randomness" used here are:
 * - block.timestamp: predictable and manipulatable by miners (to a small degree)
 * - block.difficulty: (now prevrandao) predictable within the same block
 * - block.number: completely predictable
 * - blockhash: predictable if called within the same block, or manipulatable by miners
 */
contract WeakRandomness {
    
    constructor() payable {}

    /**
     * @dev A game where a user guesses a random number.
     * To play, sending 1 ether is required. If guessed correctly, you win 2 ether.
     */
    function guessTheRandomNumber(uint256 _guess) public payable {
        require(msg.value == 1 ether, "Must send 1 ether to play");

        // VULNERABILITY: Generating randomness from public block variables
        uint256 weakRandom = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty, // In newer solidity versions (>0.8.18), this is block.prevrandao
                    block.number,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );

        if (weakRandom == _guess) {
            // Winner!
            (bool success, ) = msg.sender.call{value: 2 ether}("");
            require(success, "Transfer failed");
        }
    }

    // Helper function to view the "random" components
    function getComponents() public view returns (uint256, uint256, uint256, bytes32) {
        return (
            block.timestamp,
            block.difficulty,
            block.number,
            blockhash(block.number - 1)
        );
    }

    receive() external payable {}
}
