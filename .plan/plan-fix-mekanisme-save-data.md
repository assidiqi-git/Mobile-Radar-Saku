The current Offline-First implementation works great, but currently, data is only pushed to the server via manual sync. I want to enhance the user experience by adding an "Immediate Background Sync" feature.

Please update the transaction saving logic with the following step-by-step instructions:

**Step 1: Update the Save Method (Provider/Repository)**

- Locate the method where a new transaction (or transfer) is saved to the local SQLite database.
- The flow must be:
  1. Save the data to SQLite locally.
  2. Immediately update the local state/UI so the user sees the new balance and transaction instantly.
  3. Close the transaction form/bottom sheet (do not wait for the API).

**Step 2: Implement "Fire-and-Forget" Background Sync**

- Right after the local SQLite save is confirmed (and the UI is updating), trigger the `SyncManager`'s push method asynchronously.
- CRITICAL: Do NOT `await` the sync result in a way that blocks the UI. You can use a detached Future, `Future.microtask`, or simply call the async function without awaiting it.
- Ensure any network exceptions or API errors during this background sync are caught silently. If the sync fails (e.g., no internet), the app should not crash or show an error dialog; the data will simply remain unsynced in SQLite to be picked up by the next manual or lifecycle sync.

Please apply these changes and let me know when it is done.
