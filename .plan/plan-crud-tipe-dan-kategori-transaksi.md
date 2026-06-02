Act as an Expert Flutter Developer. I need to build Offline-First CRUD (Create, Read, Update, Delete) management screens for "Transaction Types" and "Transaction Categories" based on the OpenAPI specification provided earlier.

These management screens will be accessed from the Profile Screen. Since the app is Offline-First, all CRUD operations must be performed on the local SQLite database first (using ULIDs for new records and marking them as `sync_status = 'pending'`), which will later be handled by our SyncManager.

Please implement this step-by-step:

**Step 1: Profile Screen Navigation**

- Open the existing `ProfileScreen` widget.
- Add a new "Pengaturan" (Settings) section or a list of menu items.
- Add two `ListTile` buttons:
  1. "Manajemen Tipe Transaksi" -> Navigates to `TransactionTypeListScreen`.
  2. "Manajemen Kategori Transaksi" -> Navigates to `TransactionCategoryListScreen`.

**Step 2: Transaction Type CRUD Implementation**

- Create `TransactionTypeListScreen`: A list showing all active types. Include an Add (FAB) button.
- Create `TransactionTypeFormScreen` (used for both Create and Update):
  - **Fields:** `name` (required), `description` (optional).
  - **Action Dropdown:** Must let the user select from the allowed enum: `addition`, `deduction`, or `neutral`.
- **Delete Logic:** Soft-delete locally. Note that the server will return a 409 Conflict if categories are still using it, so ensure the `SyncManager` and UI can handle and display this specific sync error later.

**Step 3: Transaction Category CRUD Implementation**

- Create `TransactionCategoryListScreen`: A list showing all active categories. Display the category name and its associated transaction type name. Include an Add (FAB) button.
- Create `TransactionCategoryFormScreen` (used for both Create and Update):
  - **Fields:** `name` (required), `description` (optional).
  - **Type Dropdown:** Must query the local SQLite database to fetch all active "Transaction Types" and display them in a dropdown so the user can select the `transaction_type_id`.
- **Delete Logic:** Soft-delete locally. Similar to Types, the server will return a 409 Conflict if transactions are still using this category.

**Step 4: Provider/Repository SQLite Logic**

- Ensure the respective Providers/Repositories handle generating ULIDs for new records.
- Ensure Update operations modify the local record and set `sync_status = 'pending'` if it was previously synced.
- Ensure Delete operations set `deleted_at` to the current timestamp and set `sync_status = 'pending'` so the SyncManager knows to send the DELETE request to the server.

Please execute Step 1 and Step 2 first. Let me know when the Transaction Type CRUD is ready so I can review it before you proceed to Step 3.
