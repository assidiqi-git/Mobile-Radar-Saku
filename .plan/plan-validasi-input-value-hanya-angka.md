Correction on the amount input fields: The application uses Indonesian Rupiah (Rp), which does not use decimals. Therefore, the amount fields must only accept whole numbers (integers).

Please update all monetary input fields (Add Transaction, Add Transfer, Add Wallet) with the following step-by-step instructions:

**Step 1: Strictly Integer Input & Thousand Separator UX**

- Set the keyboard type to strictly numbers without decimals:
  `keyboardType: TextInputType.number,`
- Change the input formatters to only allow digits:
  `inputFormatters: [FilteringTextInputFormatter.digitsOnly],`
- **Crucial UX Enhancement:** Implement a custom `TextInputFormatter` (or use the `intl` package) to automatically format the input with a dot (.) as the thousands separator while the user types (e.g., typing "50000" formats to "50.000").

**Step 2: Parsing & Validation**

- Update the `validator` and the `onSaved` (or controller parsing) logic.
- Before saving or validating, you MUST strip the thousand separators (remove the dots) to parse the value back into a clean integer.
- Update the validation rule: The parsed integer must be `>= 1` (ignore the 0.01 minimum from the API spec since this is Rupiah).

Please apply these formatting and validation fixes to all amount fields and let me know when it's done.
