Act as an Expert Flutter Developer. I have generated a new screen design using Google Stitch via MCP called "Detail Transaksi" (Transaction Detail Screen).

Please translate this Stitch design into a functional Flutter widget. Ensure it integrates perfectly with our Offline-First SQLite architecture.

CRITICAL NOTE: This screen is STRICTLY for viewing details and deleting. DO NOT implement any "Edit" or "Update" functionality.

Please implement the screen step-by-step:

**Step 1: Screen Setup & Data Fetching**

- Create a new file `transaction_detail_screen.dart`.
- The screen should accept a `transactionId` (ULID) as a parameter.
- Fetch the complete transaction data, including its related `Wallet` and `TransactionCategory` (and its `action` type), directly from the local SQLite database.

**Step 2: UI Implementation (Mapping Stitch Design)**

- Translate the Stitch HTML/CSS layout into Material 3 Flutter widgets.
- **Amount Display:** Format the amount as Indonesian Rupiah (e.g., "Rp 50.000" without decimals). Apply visual logic based on the category's `action`:
  - `addition`: Green text with '+' prefix.
  - `deduction`: Red text with '-' prefix.
  - `neutral`: Grey/Black text.
- **Details Section:** Display Date, Category Name, Wallet Name, and Note.
- **Sync Status:** Display a badge indicating the `sync_status` ('synced', 'pending', or 'error'). If it's 'error', display the `sync_error_message` below it in red text.
- **Photo:** If there is a photo, display it using an `Image` widget with fallback handling.

**Step 3: Delete Action (Offline-First Logic)**

- Add a "Delete" icon button.
- When tapped, show a confirmation Dialog: "Apakah Anda yakin ingin menghapus transaksi ini?".
- If confirmed, implement the offline-first delete logic:
  1. Reverse the wallet balance mutation in the local SQLite database (if `addition`, decrease balance; if `deduction`, increase it).
  2. Soft-delete the transaction locally (set `deleted_at` to the current timestamp).
  3. Close the Detail Screen (pop context).
  4. Trigger the asynchronous `SyncManager` to push this deletion to the server.

Please execute Step 1 and Step 2 first. Let me know when you are ready to implement the Delete logic in Step 3.
