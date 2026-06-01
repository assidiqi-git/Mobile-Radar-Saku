The initial implementation is complete, but there is a visual bug in the Transaction List UI (Dashboard and History screens). All transactions are currently displayed with a red color and the standard 'outcome' icon, regardless of their actual type.

Please fix this step-by-step by wiring the UI components to the transaction's `action` data, as defined in the OpenAPI spec context (addition, deduction, neutral).

**Step 1: Update the Transaction Model (If Necessary)**

- Ensure the Dart `Transaction` model (or its nested `Category` model) correctly decodes the `action` field from the JSON response as a String or an Enum. It should support: `addition`, `deduction`, and `neutral`.

**Step 2: Implement UI Logic in the Transaction List Item**

- Locate the Flutter Widget responsible for rendering a single line item in the transaction list (e.g., `TransactionListItem`).
- Modify the logic to change the visual appearance based on the transaction's category action:
  1. **For `addition` (Income):**
     - Change the amount text color to Green.
     - Add a '+' prefix to the amount text (e.g., "+ Rp 50.000").
     - Optional: Use a specific icon (like a green upward arrow).

  2. **For `deduction` (Outcome/Expense):**
     - Keep the amount text color Red.
     - Add a '-' prefix to the amount text (e.g., "- Rp 25.000").
     - Keep the current outcome icon.

  3. **For `neutral` (e.g., adjustment, transfer):**
     - Change the amount text color to Grey or Black.
     - Optional: Use a neutral icon (like a double-headed horizontal arrow).

Please apply these visual changes and let me know when it is done for review.
