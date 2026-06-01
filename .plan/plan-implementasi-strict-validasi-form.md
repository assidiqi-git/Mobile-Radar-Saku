We need to enhance our Offline-First architecture to handle "Poison Pill" scenarios (Data Conflicts) where the local SQLite database accepts a transaction, but the Laravel API rejects it during the background sync (e.g., returning a 422 Validation Error).

Please implement a dual-layer strategy: Prevention (Client-Side Validation) and Handling (Data Quarantine).

**Phase 1: Database & Model Updates for Quarantine**

- Update the `DatabaseHelper` for the `transactions` and `transfers` tables:
  1. Change the `is_synced` column (if it's a boolean) to a `sync_status` column (TEXT/String). It should support three states: `'synced'`, `'pending'`, and `'error'`. Default should be `'pending'`.
  2. Add a new column `sync_error_message` (TEXT, nullable) to store the JSON error response from the server.
- Update the corresponding Dart Models (`Transaction` and `Transfer`) to reflect these new properties (`syncStatus` and `syncErrorMessage`). Update `fromJson` and `toJson`.

**Phase 2: Client-Side Validation (Prevention)**

- Update the UI forms (e.g., `AddTransactionScreen` and `AddTransferScreen`).
- Implement strict client-side validation that mirrors the OpenAPI spec _before_ saving to SQLite:
  1. **Amount:** Must be numeric and greater than or equal to 0.01.
  2. **Name:** Maximum length of 255 characters.
  3. **Photo (if implemented):** File size must not exceed 2MB.
  4. **Required Fields:** Ensure all fields marked as required in the OpenAPI spec are not empty.
- Prevent the "Save" action and show validation errors directly on the UI fields if these conditions are not met.

**Phase 3: Update SyncManager Logic (Handling)**

- Update the background sync logic (`SyncManager`).
- When pushing pending records (`sync_status == 'pending'`) to the server (`POST /sync/transactions`):
  1. If the server responds with a `422 Validation Error`, DO NOT discard the record.
  2. Update the local SQLite record: set `sync_status = 'error'` and save the server's error message into `sync_error_message`.
  3. If the server responds with a success (200), update the local record to `sync_status = 'synced'` and clear the `sync_error_message`.

**Phase 4: UI Updates for Quarantined Data**

- In the transaction list/history UI, visually distinguish items where `sync_status == 'error'` (e.g., use a red alert icon or highlight the row).
- If the user taps on an 'error' transaction, display a dialog showing the `sync_error_message` and provide two options:
  1. **Retry:** Re-opens the form with the existing data to let the user fix the issue.
  2. **Delete:** Removes the record permanently from the local database and reverses its effect on the local wallet balance.

Please execute Phase 1 and Phase 2 first, and let me know when they are complete.
