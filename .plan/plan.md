Act as an Expert Flutter Developer and AI Native Engineer. I have connected this workspace to a newly created Flutter "Empty Application" project via MCP. 

We are building "Radar Saku", a personal financial tracking app. The app uses an offline-first architecture (using SQLite for local storage and ULIDs for primary keys) and synchronizes with a Laravel REST API. 

I have provided two context sources:
1. The UI/UX design components generated from Google Stitch.
2. The OpenAPI JSON specification of the Laravel backend.

Please implement the app step-by-step. Do not generate all the code at once; wait for my confirmation after completing each phase.

**Phase 1: Project Architecture & Setup**
- Create a clean folder structure (e.g., `lib/models`, `lib/screens`, `lib/services`, `lib/database`, `lib/providers`).
- Set up `flutter_dotenv` and create a `.env` file to store the `API_BASE_URL`. Ensure it is initialized in `main.dart`.
- Configure the SQLite database initialization in a `DatabaseHelper` class. Ensure the tables match the schemas defined in the OpenAPI spec. Use `TEXT` for ID columns since we use ULIDs.

**Phase 2: Models & API Integration**
- Generate Dart Data Classes (Models) based on the OpenAPI JSON, including `fromJson` and `toJson` methods.
- Create an `ApiService` class to handle HTTP requests (Login, Register, Sync, etc.). 
- The `ApiService` MUST read the base URL dynamically from the `.env` file. Ensure it handles the Bearer token properly and includes error handling.

**Phase 3: The Offline-First Logic (Crucial)**
- Create a `SyncManager` service. 
- Implement the logic for `POST /sync/transactions` (pushing local data to the server).
- Implement the logic for `GET /sync/transactions/pull` (pulling delta updates from the server using `last_synced_at` and applying them locally).

**Phase 4: UI Implementation (From Stitch)**
- Translate the provided Stitch UI designs into modular Flutter widgets.
- Build the core screens: Auth, Dashboard, Transaction Form, and Sync/Profile screen.
- Wire the UI to the local SQLite database using a State Management approach (e.g., Provider). The UI must read from and write to the local database *only*. The SyncManager will handle background sync with the API.

Please acknowledge these instructions and begin by executing Phase 1. Let me know when you are ready for me to review Phase 1.