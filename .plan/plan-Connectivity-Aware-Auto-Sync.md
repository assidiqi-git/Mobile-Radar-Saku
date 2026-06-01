We need to add an automatic synchronization feature that triggers as soon as the app detects that the device has reconnected to the internet. This will eliminate the need for users to always press the sync button manually when they get back online.

Please implement this "Connectivity-Aware Auto-Sync" feature step-by-step:

**Step 1: Create a Connectivity Listener Service**

- Create a `ConnectivityService` or integrate a listener within the existing `SyncManager`.
- Use the `connectivity_plus` package to subscribe to the connectivity change stream (`Connectivity().onConnectivityChanged`).
- Ensure the stream correctly filters the states: it should trigger the sync logic ONLY when the status transitions from "No Connection" (none) to an active network state (e.g., wifi, mobile).

**Step 2: Implement the Auto-Sync Trigger**

- When a reconnection event is detected:
  1. Check if the user is currently authenticated (has a valid Bearer token). If not authenticated, abort the sync silently.
  2. If authenticated, call the background sync method to fetch all local records with `sync_status == 'pending'`.
  3. Batch push these records to the server using the `POST /sync/transactions` endpoint.
  4. Perform a delta pull (`GET /sync/transactions/pull`) to ensure local data is fully up-to-date with any server changes.

**Step 3: Lifecycle Management & Optimization**

- Initialize this network listener early in the application lifecycle (e.g., in `main.dart` or during the initialization of the global `SyncManager` provider).
- Ensure the stream subscription is properly managed and disposed of when the app closes to prevent memory leaks.
- Add a basic debouncing mechanism (e.g., a short delay or checking if a sync is already in progress) to prevent multiple rapid sync calls if the network connection flickers/jitters.

Please implement Step 1 and Step 2 first, and let me know when it is ready for review.
