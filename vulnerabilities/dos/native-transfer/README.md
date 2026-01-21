# Native Transfers 🔒⚠️


## Case Study 2 — Native Token Transfer DoS (GMX V2)

### Attack mechanics

- In GMX V2, a boolean flag like `shouldUnwrapNativeToken` causes the protocol to send native ETH to a `receiver` during critical flows (for example, in liquidations or Auto-Deleveraging).
- If the `receiver` is a contract that cannot receive ETH (its `receive()` reverts), or if its receive/fallback consumes more gas than the gas limit supplied, the low-level `call` will fail and the higher-level operation (liquidation, ADL) will revert — preventing the protocol from executing critical functions and leaving unsafe positions uncleared.
- The vulnerability is particularly dangerous because attackers can create contracts that purposely reject ETH or manipulate gas consumption to force reverts. Additionally, passing a small fixed `gasLimit` makes the transfer sensitive to any gas-consuming logic on the receiver side.

### Code excerpt (GMX V2)

```solidity
function transferNativeToken(DataStore dataStore, address receiver, uint256 amount) internal {
   if (amount == 0) {return;}

   uint256 gasLimit = dataStore.getUint(keys.NATIVE_TOKEN_TRANSFER_GAS_LIMIT);

   (bool success, bytes memory data) = payable(receiver).call{value: amount, gas: gasLimit} ("");

   if (success){return;}

   string memory reason = string(abi.encode(data));
   emit NativeTokenTransferReverted(reason);

   revert NativeTokenTransferError(receiver, amount);
}
```

### Practical attack scenarios

- An attacker opens positions with `shouldUnwrapNativeToken == true` and ensures the position owner is a contract that rejects ETH or uses a receive function that consumes the allotted gas budget; later, when the position should be liquidated, the protocol call reverts and the liquidation cannot be processed.
- A receiver that intentionally consumes gas (heavy computation in `receive()`) can cause the `call` to fail if the `gasLimit` is insufficient, also causing a DoS.

### How to trigger / reproduce the revert (explicit)

You can reliably reproduce the failing transfer in a test or local deploy by exercising one of these scenarios:

1. Rejecting receiver (revert in `receive()`)
   - Deploy a contract whose `receive()` immediately `revert()`s (see `RejectingReceiver` in `src/DoSExamples.sol`).
   - Call the protocol path that triggers `transferNativeToken` (e.g., `NativeTransferVulnerable.liquidate(payable(rejectingReceiver))`) and supply a non-zero value.
   - Result: the transfer call fails, the `NativeTokenTransferReverted` event is emitted with encoded revert data, and the transaction reverts (e.g., with `NativeTokenTransferError`).

2. Low gas budget
   - Use a receiver with a gas-consuming `receive()` (see `HeavyGasReceiver`) or temporarily set the protocol's native transfer gas limit to a very low value (e.g., `setNativeTransferGasLimit(100)`).
   - Call the liquidation/transfer flow and observe the transfer `call` returning `success == false` due to gas starvation.

3. Custom-gas test
   - Use the PoC helper `transferWithCustomGas(receiver, amount, gasLimit)` to test various gas limits directly and observe when the call fails.

Why these reproduce the issue

- A direct `call{value: amount, gas: gasLimit}` will fail if the callee reverts or consumes more gas than `gasLimit`. In GMX-like flows, such a failure often aborts critical operations (liquidations, ADL) when the transfer is done inline and its failure is not handled permissively.

These steps are good to include in tests and fuzzing: test with rejecting receivers, gas-consuming receivers, and a range of gasLimit values to ensure your protocol continues to make progress and that failed transfers are handled safely.

### Robust mitigations and best practices

- Use the **pull payment** pattern: instead of sending ETH directly during critical flows, credit recipients in contract state (e.g., `pendingWithdrawals[receiver] += amount`) and let them withdraw with an explicit `withdraw()` call.
- Do not make the success of critical protocol operations depend on the success of external native transfers. Handle failed transfers gracefully: log the failure, record a pending claim, and continue with protocol state changes.
- Avoid relying on `isContract()` checks for safety — they are not reliable (constructor context, proxy patterns) and can be circumvented.
- Refrain from using small fixed gas budgets for critical transfers. If gas limits are necessary, ensure fallback handling does not block key flows.
- Consider optional custodial fallbacks (route failed native payouts to a protocol-managed vault) or a retry/escape hatch handled by governance.
- Add extensive test coverage: simulate rejecting receivers and gas-consuming receivers, fuzz `gasLimit` values, and confirm that liquidation and ADL flows continue to make progress even when transfers fail.

---

## Quick Detection Checklist ✅

- [ ] Unbounded loops over user-controlled arrays: `for(uint i=0; i<users.length; i++)`.
- [ ] Append points for those arrays where users can cheaply add entries (public `mint`/`transfer` functions).
- [ ] External calls inside loops (ETH transfers or external contract calls).
- [ ] Use of `call{value:..., gas:...}` whose failure causes the outer function to revert.

---

## PoC: Simple demo contracts

A sample PoC contract is included in this repo under `src/DoSExamples.sol`. It demonstrates:

- A `VulnerableForLoop` contract where `mint()` pushes new users into an array and `distributeDividends()` loops over `users[]` (vulnerable to unbounded-growth DoS).
- A `NativeTransferVulnerable` contract where `liquidate()` attempts to send native ETH to a receiver using a gas-limited `call` and **reverts** when the transfer fails (showcases the GMX-like DoS).
- `AttackerWallet` / `AttackerCreator` / `RejectingReceiver` contracts to show how an attacker can bloat the `users[]` or block `liquidate()` by rejecting ETH.

---

## Notes and Recommendations 💡

- Prefer pull-based patterns for user payouts (allow claiming) to avoid iterating over an unbounded set in a single tx.
- Add upper bounds or caps on arrays that represent user lists, or require proof-of-stake / economic cost to add entries.
- When needing to do transfers that could fail, make failure handling non-blocking: credit state and emit events so funds can be recovered.

---

If you'd like, I can also add a small Foundry test that demonstrates the gas growth or a simple script that shows failure when a receiver rejects ETH. Would you like me to add tests or a CI check to compile these examples? ✅