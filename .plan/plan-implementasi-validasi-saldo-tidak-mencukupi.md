We need to implement strict client-side validation to prevent wallet balances from falling below zero (negative balance). Since this is an offline-first app, this validation must check the local SQLite state before attempting to save or sync.

Please update the form submission logic for both Transactions and Transfers step-by-step:

**Step 1: Validation Logic for Transactions**

- In the Add Transaction screen, when the user taps "Save", intercept the action.
- Check the `action` type of the selected Transaction Category.
- If the action is a `deduction` (expense):
  1. Read the current balance of the selected Wallet from the local state/provider.
  2. If the entered `amount` is greater than the wallet's current balance, block the save action.
  3. Display a clear error to the user (e.g., using the `TextFormField` error text or a SnackBar) saying: "Saldo tidak mencukupi".

**Step 2: Validation Logic for Transfers**

- In the Add Transfer screen, when the user taps "Save", intercept the action.
  1. Read the current balance of the selected `from_wallet` from the local state.
  2. Calculate the total deduction required: `total_deduction = amount + (fee ?? 0)`.
  3. If the `total_deduction` is greater than the `from_wallet`'s current balance, block the save action.
  4. Display the error: "Saldo tidak mencukupi".

**Step 3: Execution**

- Ensure these checks happen instantly on the client side.
- If the validation fails, DO NOT generate a ULID, DO NOT save to SQLite, and DO NOT trigger the API or SyncManager.

Please implement these balance guardrails and let me know when it is done.
