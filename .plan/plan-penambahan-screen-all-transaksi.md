Act as an Expert Flutter Developer and UI Designer. I want to refactor the transaction display logic, add a new dedicated Transactions Screen with filters, and update the main navigation structure.

Please implement this step-by-step:

**Task 1: Dashboard Refactoring**

- Modify the `DashboardScreen` to limit the "Recent Transactions" list to only show the top 5 most recent items from the local SQLite database.
- If there is a "See All" button next to the recent transactions, make sure tapping it programmatically switches the BottomNavigationBar to the "Transaksi" tab.

**Task 2: Update the Bottom Navigation Bar**

- Modify the main scaffold that holds the `BottomNavigationBar`.
- Replace the old Profile tab with the new "All Transactions" screen (since the profile button is already accessible in the top right corner of the Dashboard AppBar).
- Set the navigation tabs to this exact order:
  1. **Beranda** (Routes to DashboardScreen)
  2. **Transaksi** (Routes to the new AllTransactionsScreen)
  3. **Dompet** (Routes to WalletsScreen)
  4. **Transfer** (Routes to TransferScreen)

**Task 3: Design the New Screen via MCP (Stitch)**

- Please use the Google Stitch tool via MCP to design the new screen called `AllTransactionsScreen`.
- The design should follow the "Radar Saku" aesthetic (Material 3, Rp currency format, clean layout).
- Requirements for the visual design:
  1. **Header Section**: Title "Semua Transaksi".
  2. **Search Bar**: A modern search input at the top to filter transactions by Name or Note.
  3. **Filter Row (Chips/Horizontal Scroll)**: Quick filters for Transaction Types (Income, Expense) and Wallets.
  4. **Date Range Picker**: An icon or button to filter transactions within a specific date range.
  5. **Transaction List**: A scrollable list showing full transaction details (Icon, Category, Wallet Name, Amount with +/- prefix, and Date). Ensure the visual logic (Green for addition, Red for deduction, Grey for neutral) is applied.
  6. **Empty State**: A visual design for when no transactions match the active filters.

**Task 4: Implementation in Flutter**

- Once the Stitch design is ready, translate it into a modular Flutter widget (`all_transactions_screen.dart`).
- Implement the filtering logic in the state management (e.g., `TransactionProvider`) or `Repository`:
  - Create a query method that supports parameters for `searchText`, `walletId`, `categoryAction`, and `dateRange`.
  - The filtering MUST run against the local SQLite database.
- Ensure the UI state updates automatically and efficiently when any filter is changed.

Please start by executing Task 1 and Task 2 (Dashboard and Navigation updates), then proceed to Task 3 (Designing the new screen in Stitch via MCP). Let me know when the Stitch design is ready for my review before you proceed to Task 4.
