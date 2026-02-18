# doctor_app – Driver Tour, Pickup & Drop-Off App (A to Z)

This README explains the entire workspace/project **A to Z in a single flow** –
from login to tour, doctor visits, sample pickup, report, drop-off, pending drop
dates, and real‑time notifications, so that no part of the flow is missed.

---

## 1. High Level Overview (Single Flow Visual)

The driver's real-life workflow is roughly:

1. **Login**
2. **Load Today’s Tasks** (all of today’s tours + appointments for the driver)
3. **Specific Tour select**
4. **View Tour Doctor List**
5. **Particular Doctor Details** (location/info)
6. **Sample Pickup & Barcode Scan**
7. **Pickup Confirmation & Report (if there is any problem)**
8. **Choose Drop Location / verify via QR**
9. **Sample Scanning at Drop Point**
10. **Drop Confirmation submit (image, data)**
11. **Handle / clear Pending Drop Dates**
12. **Real‑time Extra Pickup notifications via Socket**

_Visualization (text diagram):_

```text
App Start
  └── Check local storage (driver id, active tour)
        ├── No driver  → Login Screen
        └── Driver ok
             ├── Active tour & not exited → Tour Doctor List Screen
             └── Otherwise              → Today's Task Screen

Login → Save driver info → Open socket → Go to Today's Task

Today's Task
  ├── Fetch extra pickups (pre-cache)
  └── Fetch tours (appointments + tours)
        ↓
    Select One Tour → Confirm Start → Start Tour (API + local state)
        ↓
    Tour Doctor List
        ↓ select doctor
    Doctor Details
        ↓
    Barcode Scanner (pickup mode)
        ↓
    Pickup Confirmation / Report
        ↓
    Drop Location Flow (QR validation + sample scanning)
        ↓
    Drop Confirmation submit → Pending Drop Date handling

Socket (background)
  └── extra_pickup_created / accepted / rejected / expired
        → Notifications update + in‑app snackbar
```

---

## 2. Tech Stack & Major Packages

- **Framework:** Flutter
- **State Management & Routing:** GetX (`get`)
- **Local Storage:** GetStorage (`get_storage`)
- **Networking (REST):** `http` + custom wrapper classes
- **Functional Error Handling:** `fpdart` (using `Either`)
- **Realtime Communication:** `socket_io_client`
- **Responsive UI:** `flutter_screenutil`
- **Connectivity:** `connectivity_plus`

---

## 3. Project Structure (Important Folders)

Key root paths:

- `lib/main.dart` – App entrypoint, initial route logic, global overlays.
- `lib/core/`
  - `di/dependency_injection.dart` – Registers all global dependencies.
  - `routes/app_routes.dart` – Route string constants.
  - `routes/app_pages.dart` – GetX `GetPage` list + bindings.
  - `themes/app_theme.dart` & `themes/app_colors.dart` – Light theme, colors.
  - `constants/network_paths.dart` – All API paths & helper URL builders.
  - `services/connectivity_service.dart` – Online/offline tracking.
  - `services/tour_state_service.dart` – Active tour, dates, samples count etc.
  - `utils/app_translations.dart` & `app_translations_data.dart` – i18n.
  - `utils/locale_utils.dart` – Saved locale load/save.
  - `utils/snackbar_utils.dart` – Success/error/warning snackbar helper.
- `lib/data/`
  - `local/storage_service.dart` – GetStorage wrapper (`read/write/remove`).
  - `networks/get_networks.dart` – GET wrapper (timeout, Either).
  - `networks/post_with_response.dart` – POST + JSON response.
  - `networks/post_without_response.dart` – Simple POST (bool success).
  - `networks/socket_service.dart` – Socket.IO client.
  - `services/global_notification_service.dart` – App‑level socket listeners.
  - `models/pending_drop_date_model.dart` – Pending drop date response model.
  - `repositories/pending_drop_date_repository.dart` – API for pending dates.
- `lib/features/auth/` – Login feature (screens + controller + repo).
- `lib/features/dashboard/` – Today’s tasks, notifications, tour doctor list.
- `lib/features/delivery/` – Doctor details, barcode scanning, pickup/report.
- `lib/features/drop_off/` – Drop location, sample scanning, image submit,
  drop confirmation, pending drop dates.
- `lib/shared/` – Common widgets (app bar, buttons, loading, etc.).

**Visualization – Layered View:**

```text
UI Layer (Screens & Widgets)
  ├── features/auth
  ├── features/dashboard
  ├── features/delivery
  ├── features/drop_off
  └── shared/shared_widgets

Core Layer
  ├── core/routes (AppRoutes, AppPages)
  ├── core/themes (AppTheme, AppColors)
  ├── core/services (TourStateService, ConnectivityService)
  ├── core/utils (translations, locale, snackbar)
  └── core/constants (NetworkPaths)

Data Layer
  ├── data/local (StorageService)
  ├── data/networks (GET/POST wrappers, SocketService)
  ├── data/services (GlobalNotificationService)
  ├── data/models (DTOs like PendingDropDateModel)
  └── data/repositories (API-specific repositories)
```

---

## 4. App Bootstrap & Global Services

**File:** `lib/main.dart`

Flow:

1. `WidgetsFlutterBinding.ensureInitialized();`
2. `DependencyInjection.init();` call – registers all global dependencies.
3. Use `StorageService` to read `id` (driver id) from local storage.
4. Determine `initialRoute` from active tour related keys:
   - No driver → `AppPages.initial` = Login
   - Driver exists:
     - If `active_tour_id` is set and `tour_intentional_exit != true`
       → go directly to `AppRoutes.tourDrList` with `taskId`
     - Otherwise → `AppRoutes.todaysTask`
5. `runApp(MyApp(initialRoute, initialArguments))`

**Visualization – Startup Flow:**

```text
App Start
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
DependencyInjection.init()
  ↓
Read driver id from StorageService
  ├── No driver id
  │     → initialRoute = AppPages.initial (login)
  └── Has driver id
        ├── Has active_tour_id AND not intentional exit
        │     → initialRoute = AppRoutes.tourDrList (with taskId)
        └── Otherwise
              → initialRoute = AppRoutes.todaysTask
  ↓
runApp(MyApp(initialRoute, initialArguments))
```

`MyApp`:

- `ScreenUtilInit` → sets up responsive UI.
- `GetMaterialApp`:
  - `theme: AppTheme.lightTheme`
  - `translations: AppTranslations()`
  - `locale: getSavedLocale(storage)`
  - `initialRoute: widget.initialRoute`
  - `getPages: AppPages.routes`
  - Global fade transition
  - Inside the `builder`:
    - Observes `ConnectivityService.isOnline`
    - When offline, blurs the entire UI and shows a **No Internet** overlay
- `onReady`:
  - If `initialArguments` is set (active tour), after the first frame
    calls `Get.offAllNamed(widget.initialRoute, arguments: widget.initialArguments)`

**Lifecycle handling:**

- `_MyAppState` implements `WidgetsBindingObserver`
- In `didChangeAppLifecycleState`, when **resumed**:
  - Checks whether the socket service is registered
  - Reads the driver id
  - Reconnects the socket if it is disconnected
  - Calls `GlobalNotificationService.ensureSocketConnected`

**Visualization – Runtime Responsibilities of MyApp:**

```text
MyApp
  ├── Build GetMaterialApp
  │     ├── Apply AppTheme
  │     ├── Load translations & locale
  │     └── Register routes (AppPages.routes)
  ├── Wrap child with connectivity overlay
  │     ├── Online  → show child
  │     └── Offline → show "No Internet" full-screen dialog
  └── Observe lifecycle
        └── On resumed
              ├── Ensure SocketService is registered
              ├── Read driver id from StorageService
              └── Ensure socket is connected (GlobalNotificationService)
```

---

## 5. Dependency Injection (DI) & Core Services

**File:** `lib/core/di/dependency_injection.dart`

`DependencyInjection.init()`:

- `GetStorage.init()` – prepares local key‑value storage.
- `Get.lazyPut` (fenix: true):
  - `StorageService`
  - `PostWithoutResponse`
  - `PostWithResponse`
  - `GetNetwork`
  - `SocketService`
- `TourStateService` – `Get.put(..., permanent: true)`
- `ConnectivityService().init()` – async init, permanent.
- `GlobalNotificationService` – permanent.
- `NotificationsController` – permanent (global notification cache).
- `GetTourRepository` – permanent.
- `TodaysTaskController` – permanent (tour list state).

**Concept:** Almost all core services are registered here so that any part of
the app can use `Get.find` to access them.

**Visualization – Dependency Graph (simplified):**

```text
DependencyInjection.init()
  ├── StorageService (GetStorage)
  ├── Network Layer
  │     ├── PostWithoutResponse
  │     ├── PostWithResponse
  │     └── GetNetwork
  ├── SocketService
  ├── TourStateService (permanent)
  ├── ConnectivityService (permanent, async init)
  ├── GlobalNotificationService (permanent)
  ├── NotificationsController (permanent)
  ├── GetTourRepository (uses GetNetwork)
  └── TodaysTaskController (uses GetTourRepository)

Usage example:
  Any screen/controller
    → Get.find<TourStateService>()
    → Get.find<StorageService>()
    → Get.find<SocketService>()
```

---

## 6. Routing System (Pages & Bindings)

**Route constants:** `lib/core/routes/app_routes.dart`

- Example:
  - `AppRoutes.login = '/login'`
  - `AppRoutes.todaysTask = '/todays-task'`
  - `AppRoutes.tourDrList = '/tour-dr-list'`
  - `AppRoutes.drDetails = '/dr-details'`
  - `AppRoutes.barcodeScanner = '/barcode-scanner'`
  - `AppRoutes.dropLocation = '/drop-location'`
  - `AppRoutes.sampleScanning = '/sample-scanning'`
  - `AppRoutes.dropConfirmation = '/drop-confirmation'`
  - `AppRoutes.report = '/report'`

**Page config:** `lib/core/routes/app_pages.dart`

- `AppPages.routes` is the `List<GetPage>`:
  - Login → `LoginScreen`, `LoginBinding`
  - Today’s Task → `TodaysTaskScreen`, `TodaysTaskBinding`
  - Notifications → `NotificationsScreen`, `NotificationsBinding`
  - Tour Doctor List → `TourDrListScreen`, `TourDrListBinding`
  - Delivery:
    - `DrDetailsScreen` + `DrDetailsBinding`
    - `BarcodeScannerScreen` + `BarcodeScannerBinding`
    - `PickupConfirmationScreen` + `PickupConfirmationBinding`
  - Drop Off:
    - `DropLocationScreen` + `DropLocationBinding`
    - `PendingDropDateScreen` + inline `BindingsBuilder`
    - `LocationCodeScreen` + `LocationCodeBinding`
    - `ImageSubmissionScreen` + `ImageSubmissionBinding`
    - `SampleScanningScreen` + `SampleScanningBinding`
    - `DropConfirmationScreen` + `DropConfirmationBinding`
  - `ReportScreen` + `ReportBinding`

Each screen’s related controller/repository binding is defined here so that
dependencies are ready as soon as you navigate.

**Visualization – Navigation Map (high level):**

```text
LoginScreen (/login)
  └── On success → /todays-task

TodaysTaskScreen (/todays-task)
  ├── Tap Tour Card      → /tour-dr-list (with taskId)
  └── Tap Drop Point FAB → /pending-drop-date (with driverId)

TourDrListScreen (/tour-dr-list)
  ├── Tap Doctor Card → /dr-details
  └── Back            → ExitTourWarningDialog → /todays-task

DrDetailsScreen (/dr-details)
  └── Start pickup → /barcode-scanner

BarcodeScannerScreen (/barcode-scanner)
  ├── Pickup mode      → PickupConfirmation / Report (delivery flow)
  └── Drop location QR → verifies drop point then returns

Drop Off Screens
  /drop-location → /sample-scanning → /image-submission → /drop-confirmation
```

---

## 7. Networking Layer & API Paths

### 7.1 API Paths

**File:** `lib/core/constants/network_paths.dart`

- `baseUrl = 'http://5.189.172.20:5000'`
- Extra pickup, drop location, tour, doctor, and appointment related paths:
  - `/api/extra-pickups`
  - `/api/droplocations`
  - `/api/startTour`, `/api/endTour`, `/api/deleteTourtime`
  - `/api/startReport`, `/api/problemReportDr`,
    `/api/doctor-report-image`
  - Appointment start, driver appointments (`/api/appointments/driver/...`)
  - Drop off submit: `/api/submit`

Helper methods:

- `acceptExtraPickup(int id)`, `rejectExtraPickup(int id)`
- `getPendingPickupsByDriver(int driverId)`
- `getDropLocation(name, floor)`
- `getDropLocationByName(name)`
- `getDropLocationByNameAndDriver(name, driverId)`
- `getDropLocationById(id)`

### 7.2 HTTP Wrapper Classes

**GET:** `lib/data/networks/get_networks.dart`

- `GetNetwork.getData<T>`:
  - Uses `baseUrl + url` for GET
  - 30s timeout
  - Status 200/201/202 → `Right(fromJson(json))`
  - Otherwise wraps the error message in `Left`

**POST with response:** `lib/data/networks/post_with_response.dart`

- `PostWithResponse.postData<T>`:
  - Sends JSON body
  - On 200/201/202 decodes and calls `fromJson`
  - On error tries to parse error response (`error` / `message`)

**POST without response:** `lib/data/networks/post_without_response.dart`

- Simple POST:
  - Success → `Right(true)`
  - Error → `Left(error.toString())`

### 7.3 Feature Repositories

Examples:

- **Login:** `features/auth/repositories/login_repo.dart`
  - Calls `/api/drivers/login` and returns `LoginModel`.
- **Tours:** `features/dashboard/repositories/get_tour_repo.dart`
  - `GET /api/appointments/driver/{driverId}/{date}`
  - Response map → `CombinedScheduleModel`.
- **Extra Pickup:** `features/dashboard/repositories/extra_pickup_repository.dart`
  - Accept / reject / get pending / get by id – all `Either` based.
- **Drop Location:** `features/drop_off/repositories/drop_location_repository.dart`
  - Name+floor, id, name+driver+date, verify name+id, operating hours.
- **Drop Off Submit:** `features/drop_off/repositories/submit_drop_off_repo.dart`
  - Posts the final drop-off payload to `/api/submit`.
- **Pending Drop Dates:** `data/repositories/pending_drop_date_repository.dart`
  - `/api/pendingDropDate?driverId=...`

**Visualization – Data Flow Example (Tours):**

```text
TodaysTaskController._fetchTours()
  ↓
GetTourRepository.execute(date, driverId)
  ↓
GetNetwork.getData<CombinedScheduleModel>()
  ↓
HTTP GET: /api/appointments/driver/{driverId}/{date}
  ↓
Response JSON
  ↓
CombinedScheduleModel.fromJson(...)
  ↓
Controller updates todaySchedule (Rx)
  ↓
TodaysTaskScreen UI rebuilds via Obx()
```

---

## 8. Tour State Management (TourStateService)

**File:** `lib/core/services/tour_state_service.dart`

This is the tour **single source of truth**:

- Storage keys:
  - `active_tour_id`
  - `active_tour_start_time`
  - `tour_start_date`
  - `completed_doctors`
  - `visited_doctors`
  - `samples_submitted_count`
  - `tour_intentional_exit`
  - `active_appointment_id`
- Reactive fields:
  - `activeTourId` (`RxString`)
  - `tourStartTime` (`Rx<DateTime?>`)
  - `tourStartDate` (`RxString`)
  - `completedDoctorIds` (`RxSet<String>`)
  - `visitedDoctorIds` (`RxSet<String>`)
  - `samplesSubmittedCount` (`RxInt`)
  - `tourIntentionalExit` (`RxBool`)

Key responsibilities:

- **State restore**:
  - If `tour_intentional_exit == true` → clear local state.
  - Otherwise loads tour id, dates, completed/visited doctors from storage.
- **Start tour** (`startTour`):
  - If a previous active tour exists, clears its state.
  - Writes `active_tour_id`, `tour_start_date`, appointment id.
  - Sends a start event to the backend via `_callStartTourAPI`.
- **End tour** (`endTour`):
  - Resolves the effective tour id (arg + state + storage).
  - Calls `_callEndTourAPI` to send end info.
  - On success sets `tour_intentional_exit = true` and clears local state.
- **Delete tour time** (`deleteTourTime`):
  - Sends an exit flag indicating whether any samples were submitted.
- **Check and complete**:
  - `_checkAndCompleteTourInternal` calls the API with completed stats.
- **Doctor state**:
  - `markDoctorVisited` / `markDoctorCompleted` / `incrementSamplesSubmitted`

This lets the app know which tour is active, how many doctors have been visited,
and how many samples have been submitted, etc.

**Visualization – Tour State Timeline:**

```text
No Active Tour
  ↓ startTour(tourId, appointmentId)
Active Tour
  ├── activeTourId = tourId
  ├── tourStartDate set + stored
  ├── StartTour API called
  ├── markDoctorVisited(id)  → visitedDoctorIds
  ├── markDoctorCompleted(id) → completedDoctorIds
  ├── incrementSamplesSubmitted() → samplesSubmittedCount
  └── deleteTourTime() / endTour()
          ↓
        tour_intentional_exit = true
        Local storage cleared
        Rx fields reset (no active tour)
```

---

## 9. Authentication Flow (Login)

**Screen:** `features/auth/views/login_screen.dart`  
**Controller:** `features/auth/controllers/login_controller.dart`  
**Repository:** `features/auth/repositories/login_repo.dart`

Visual flow:

```text
LoginScreen
  └── LoginFormWidget (userId + password)
        ↓ onPress LoginButton
LoginController.handleLogin()
  ├── Validate form
  ├── Call LoginRepository.execute()
  │     → POST /api/drivers/login
  ├── On success:
  │     • Save driver id, username, name in StorageService
  │     • Clear NotificationsController cache
  │     • Disconnect old socket, connect new one
  │     • GlobalNotificationService.attachListeners
  │     • Fetch initial pending pickups
  │     • Navigate to AppRoutes.todaysTask
  └── On error:
        Show snackbar with error message
```

Important points:

- **Password validation** – min length 6 etc.
- **Logged in username** – comes from the API response, not from the form.
- **Storage keys** – saves `'id'`, `'username'`, `'name'`.
- **Socket reconnection** – reconnects the socket with the new driver id.

**Visualization – Data & Service Interaction on Login Success:**

```text
LoginController.handleLogin()
  ↓
LoginRepository.execute()
  ↓
POST /api/drivers/login
  ↓
LoginModel
  ↓
StorageService
  ├── write('id', driverId)
  ├── write('username', username)
  └── write('name', driverName)
  ↓
NotificationsController
  └── clearAllData()
  ↓
SocketService
  ├── disconnect old socket
  └── connect(driverId)
        ↓
      GlobalNotificationService.attachListeners(driverId)
        ↓
      NotificationsController.fetchPendingPickups()
  ↓
Get.offAllNamed(AppRoutes.todaysTask)
```

---

## 10. Today’s Task & Tour Selection

**Screen:** `features/dashboard/views/todays_task_screen.dart`  
**Controller:** `features/dashboard/controllers/todays_task_controller.dart`

Screen behaviour:

- App bar: `CustomAppBarWidget` (driver info + notification icon etc.).
- Two FABs:
  - `Today Task` mode (default)
  - `Drop Point` mode (directly opens pending drop date flow)
- When entering the screen:
  - `initState` calls `controller.refreshTasks()`.

Controller major logic:

- `loadTodaysTasks`:
  - `_fetchAllExtraPickups()` → pre-caches pending extra pickups for the driver.
  - `_fetchTours()` → calls `GetTourRepository.execute`.
- `_fetchTours()`:
  - Reads driver id from storage
  - Converts the date to API format (`toApiDate()` from shared extension).
  - Gets `CombinedScheduleModel` response:
    - contains `appointments`, `tours`, etc.
  - Filters active tours:
    - Shows only tours where the appointment status is not `completed`.
  - Caches doctor info in `NotificationsController`.
- `navigateToTourDetails(taskId)`:
  - Finds the tour and calculates doctor count
  - Shows `TourStartConfirmationDialog`
  - On confirm:
    - Calls `tourStateService.startTour(taskId, appointmentId)`
    - Waits briefly
    - Navigates to `AppRoutes.tourDrList` (tour doctor list screen)

**Visualization – Today’s Task Loading & Tour Start:**

```text
TodaysTaskScreen.initState()
  ↓
controller.refreshTasks()
  ↓
loadTodaysTasks()
  ├── _fetchAllExtraPickups()
  │     └── ExtraPickupRepository.getPendingPickups(driverId)
  │           → cache in NotificationsController
  └── _fetchTours()
        └── GetTourRepository.execute(date, driverId)
              → todaySchedule (CombinedScheduleModel)

User taps a tour card
  ↓
navigateToTourDetails(taskId)
  ↓
TourStartConfirmationDialog
  ↓ on confirm
TourStateService.startTour(taskId, appointmentId)
  ↓
Get.toNamed(AppRoutes.tourDrList, arguments: {taskId})
```

---

## 11. Tour Doctor List & Doctor Details

### 11.1 TourDrListScreen

**File:** `features/dashboard/views/tour_dr_list_screen.dart`

Responsibilities:

- On init:
  - Uses `TourStateService` to ensure the tour has started.
  - Calls the first appointment start API.
  - Refreshes notifications (silent).
- Back press handling:
  - Uses `PopScope` for a custom exit dialog.
  - Shows `ExitTourWarningDialog`:
    - Displays total doctors, visited, completed, and sample count.
    - On confirm/silent exit → calls `deleteTourTime` + `clearTourState` and
      navigates back to `TodaysTask`.
- UI:
  - `TourHeaderWidget` – tour name.
  - `DoctorStatsWidget` – completed/inProgress/pending doctors.
  - List of doctors (filters out already completed doctors from
    `tour.allDoctors`).

Doctor card tap:

- Calls `markDoctorVisited(id)`.
- Navigates with `Get.toNamed(AppRoutes.drDetails, arguments: {...})` passing:
  - `doctorId`, `tourId`, `appointmentId`, `isExtraPickup`, `extraPickupId`,
    and a `doctorData` map (name, location, contact, pdf, description).

**Visualization – Tour Doctor List Flow:**

```text
TourDrListScreen
  ├── Reads current tourId from arguments or TourStateService
  ├── Ensures tour started + appointmentStart API called
  ├── Shows stats:
  │     ├── completedDoctorIds.length
  │     └── pending = tour.allDoctors - completed
  └── Doctor list
        └── onTap(doctor)
              ├── TourStateService.markDoctorVisited(doctor.id)
              └── Navigate → /dr-details (with full doctorData)
```

### 11.2 Doctor Details Screen

**File:** `features/delivery/views/dr_details_screen.dart`

- App bar:
  - Back → `DrDetailsController.goBack`
  - Title → doctor name
  - Notifications icon with badge (pending pickups count).
- Body:
  - `DoctorInfoHeaderWidget`:
    - Doctor image (network or fallback icon).
    - Name, specialty/description.
    - Address (street, area, zip).
    - Contact info (phone, email).
    - PDF/download/info link if available (instructions/documents).

From here the user typically starts the pickup process (barcode scanner etc.).

---

## 12. Sample Pickup – Barcode Scanner Flow

**Screen:** `features/delivery/views/barcode_scanner_screen.dart`  
**Controller:** `features/delivery/controllers/barcode_scanner_controller.dart`  
**Widgets:** `ProgressHeaderWidget`, `ScannedSamplesListWidget`,
`ActionButtonsWidget`

Modes:

- **Pickup mode** (default) – scan samples during a doctor visit.
- **Drop location mode** (`isDropLocation = true`) – verify drop point QR.

Main pieces:

- Mobile scanner setup:
  - `MobileScannerController` from the `mobile_scanner` package.
  - `scanWindow` rectangular overlay (custom painter).
- Pickup mode:
  - `ProgressHeaderWidget`:
    - Shows `controller.progressText` + optional progress bar.
    - Shows `controller.scannerStatus` text.
  - `ScannedSamplesListWidget`:
    - List of already scanned sample codes.
  - `ActionButtonsWidget`:
    - Next, delete, confirm, etc. (driven by controller logic).
  - `onDetect`:
    - Calls `controller.onBarcodeDetected(code, context)`.
- Drop location mode:
  - Uses the same scanner, but:
    - No progress header.
    - No samples list/action buttons (only QR verification).
  - `BarcodeScannerScreen._handleDropLocationQrScan`:
    - Calls `DropLocationController.onQRCodeScanned(qrCode)`.
    - If valid, closes the scanner and returns to the drop location screen.
    - If invalid, shows a dialog (`invalid_location` message).
    - Uses a loading overlay to lock the screen while scanning.

**Visualization – Scanner State Machine (simplified):**

```text
BarcodeScannerScreen
  ├── Mode: pickup (isDropLocation = false)
  │     ├── Show ProgressHeaderWidget
  │     ├── Show ScannedSamplesListWidget
  │     ├── Show ActionButtonsWidget
  │     └── onDetect(code)
  │           → BarcodeScannerController.onBarcodeDetected(code, context)
  │                 ├── Validate code
  │                 ├── Add to scanned list
  │                 └── Update progress text/status
  └── Mode: drop location (isDropLocation = true)
        ├── Hide progress + scanned list + action buttons
        └── onDetect(qrCode)
              → DropLocationController.onQRCodeScanned(qrCode)
                    ├── Valid   → close scanner & return
                    └── Invalid → show "invalid location" dialog
```

---

## 13. Drop Location & Drop-Off Flow

The drop-off flow is built from multiple screens:

1. **Drop Location Screen** – where to drop.
2. **QR verification (BarcodeScannerScreen in drop mode)** – verify the
   correct station.
3. **Sample Scanning Screen** – which samples are being dropped.
4. **Image Submission Screen** – proof image capture/upload.
5. **Drop Confirmation Screen** – final confirmation & API call.
6. **Pending Drop Date Screen** – handles any dates that were pending.

**Visualization – End-to-End Drop-Off Flow:**

```text
DropLocationScreen
  ├── Choose / verify location (possibly via QR)
  └── Continue
        ↓
SampleScanningScreen
  ├── Scan all samples being dropped
  └── Continue
        ↓
ImageSubmissionScreen
  ├── Capture/upload proof image
  └── Continue
        ↓
DropConfirmationScreen
  ├── Show summary (location + sample count + image info)
  ├── Submit via SubmitDropOffRepository.submitDropOff()
  └── On success → clear local state / navigate back

PendingDropDateScreen
  ├── Fetch pending dates via PendingDropDateRepository
  └── Let user complete outstanding drop-offs for those dates
```

### 13.1 Drop Location Repository

**File:** `features/drop_off/repositories/drop_location_repository.dart`

Key ideas:

- Tries multiple name variants – so backend records can still match even if
  formatting differs:
  - `"Second Floor"`, `"SecondFloor"`, `"Second-Floor"`, `"Second_Floor"`, etc.
- `getDropLocationInfo(name, floor)`:
  - Calls GET with candidate names.
  - Retries up to 3 times per candidate on 5xx server error.
  - Returns clear messages when not found / error.
- `getDropLocationById(id)` – detail lookup by id.
- `getDropLocationByName(name, driverId, date)` – name+driver+date based
  secure lookup:
  - Logs response structure including `pendingSamples`, `totalSamples`, etc.
- `verifyDropLocationByIdAndName(id, name)`:
  - First looks up by id.
  - Then compares the name case-insensitively.
- `isWithinOperatingHours(startTime, endTime)`:
  - Checks whether the current time is between start and end.
- `getOperatingHoursMessage(...)`:
  - Builds a user-friendly status string.

### 13.2 Submit Drop-Off Repository

**File:** `features/drop_off/repositories/submit_drop_off_repo.dart`

- `uploadProofImage(imagePath)`:
  - Currently mocked – backend is not ready yet; returns the local path as
    `imageUrl`.
- `submitDropOff(dropOffData)`:
  - `POST {baseUrl}/api/submit`
  - Full payload log: keys, values.
  - 30s timeout.
  - 2xx → JSON parse/empty handle.
  - Non‑2xx → error message parse and log.

### 13.3 Pending Drop Date

- Model: `data/models/pending_drop_date_model.dart`
  - `success`, `pendingDates: List<String>`
- Repo: `data/repositories/pending_drop_date_repository.dart`
  - `/api/pendingDropDate?driverId=...`
  - Prints response and converts into `PendingDropDateModel`.
- Related Screen/Controller:
  - `features/drop_off/views/pending_drop_date_screen.dart`
  - `features/drop_off/controllers/pending_drop_date_controller.dart`
  - Binding: inline `BindingsBuilder` in `AppPages`.

Flow:

- When the driver switches to drop point mode, it fetches pending drop dates
  using the actual driver id.
- The user then processes those pending dates to complete drop-offs.

---

## 14. Real‑Time Notifications & Extra Pickups

### 14.1 Socket Service

**File:** `data/networks/socket_service.dart`

- Base URL: `NetworkPaths.baseUrl`.
- Connection:
  - Transport: `websocket`
  - Auto reconnection enabled
  - Effectively unlimited attempts (+ delay strategy)
  - Extra header: `'driver-id': driverId.toString()`
- On connect:
  - Sets `_isConnected = true`
  - Joins room: `emit('join-driver', driverId)`
  - Starts keep-alive timer – sends a `ping` event every 25s.
  - Calls `GlobalNotificationService.attachListeners(driverId)`.
- On disconnect:
  - Sets `_isConnected = false`
  - Stops the keep-alive timer
  - Attempts auto reconnection.

### 14.2 Global Notification Service

**File:** `data/services/global_notification_service.dart`

- Handles socket listeners at the app level:
  - `extra_pickup_created`
    - Shows a success snackbar – new extra pickup assigned.
    - Immediately tells `NotificationsController` to update.
  - `extra_pickup_accepted`
  - `extra_pickup_rejected`
  - `extra_pickup_expired` – shows a warning snackbar and refreshes.
- Ensures:
  - If `StorageService` & `SocketService` are registered, it reads the driver id.
  - If not connected, it connects the socket.
  - The `attachListeners` method lets **SocketService** re-attach listeners on
    any connect/reconnect events.

### 14.3 Extra Pickup Repository (Dashboard side)

**File:** `features/dashboard/repositories/extra_pickup_repository.dart`

- `acceptExtraPickup(id)` – PUT
- `rejectExtraPickup(id)` – PUT
- `getPendingPickups(driverId)` – GET; je format e asuk, list of map e convert.
- `getExtraPickupById(extraPickupId)` – Single pickup details.

`TodaysTaskController`:

- `_fetchAllExtraPickups()` pre-caches all pending extra pickups in
  `NotificationsController.extraPickupCacheById`.

**Visualization – Real-Time Extra Pickup Flow:**

```text
Server emits extra_pickup_created
  ↓
SocketService (driver room)
  ↓
GlobalNotificationService
  ├── Show success snackbar
  └── If data is Map
        └── NotificationsController.addNewNotification(pickupMap)
      Else
        └── NotificationsController.fetchPendingPickups()

Dashboard UI
  ├── Notifications badge counts pendingPickups.length
  └── Notifications screen lists all pending extra pickups
```

---

## 15. Connectivity & Offline Behaviour

**File:** `core/services/connectivity_service.dart`

- Uses `Connectivity().checkConnectivity()` & `onConnectivityChanged`.
- Real internet check:
  - `InternetAddress.lookup('google.com')` with 3s timeout.
- `isOnline` (`RxBool`) is consumed in the `builder` of `main.dart`:

Behaviour:

- Online:
  - Shows the normal app child UI.
- Offline:
  - Full screen semi‑transparent dark overlay.
  - Wi‑Fi off icon, title & message (`internet_required_title/message`) shown.
  - Background screen is wrapped in `AbsorbPointer` to disable interaction.

**Visualization – Connectivity Overlay Logic:**

```text
ConnectivityService.isOnline (RxBool)
  ├── true
  │     → Show normal app child tree
  └── false
        → Stack(
              child: app child (AbsorbPointer)
              overlay: Scaffold with "No Internet" message + icon
           )
```

---

## 16. Localization & Translations

**Files:**

- `core/utils/app_translations.dart`
- `core/utils/app_translations_data.dart`
- `core/utils/locale_utils.dart`

Concept:

- `AppTranslations` implements `GetX Translations`.
- In `main.dart`:
  - `translations: AppTranslations()`
  - `locale: getSavedLocale(storage)`
  - `fallbackLocale: Locale('en')`
- UI text uses `'<key>'.tr` or `'<key>'.trParams()`.
- `english_german_translations.xlsx` can be used to manage/plan translations
  externally.

Result:

- The app easily supports multiple languages; more languages can be added later.

**Visualization – Translation Lookup:**

```text
View widget
  └── Text('login_success_welcome'.trParams({'name': userName}))
        ↓
AppTranslations
  ├── Detect current locale (e.g., en)
  └── Find key "login_success_welcome" in that map
        ↓
        "Welcome, {name}!"
        ↓
Apply params → "Welcome, John!"
```

---

## 17. Theming & Shared UI Components

**Theme:** `core/themes/app_theme.dart`, `core/themes/app_colors.dart`

- Material 3, light theme.
- Central color scheme & appBarTheme, button styles.

**Shared Widgets:** `lib/shared/shared_widgets/`

- `custom_app_bar.dart`
- `custom_text_form_field.dart`
- `primary_button.dart`, `secondary_button.dart`
- `info_card.dart`
- `loading_widget.dart` + `LoadingOverlay`

**Dashboard specific widgets:**

- `doctor_card_widget.dart`, `doctor_stats_widget.dart`
- `task_card_widget.dart`, `tour_header_widget.dart`
- Various dialog widgets (start confirmation, exit warning, extra pickup
  dialog).

**Delivery & Drop-off widgets:**

- `doctor_info_header_widget.dart`
- Barcode/camera section widgets
- Sample list, progress header, report buttons etc.

This creates a modular UI and makes reuse easy.

---

## 18. How to Run the Project

This is a standard Flutter project, so the usual workflow applies:

1. **Prerequisites**
   - Flutter SDK installed (stable channel)
   - Android Studio / Xcode + simulators/emulators
   - Dart plugin etc.
2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run on device/emulator**

   ```bash
   flutter run
   ```

4. **Platform specific**
   - Android: Ensure emulator / physical device is connected.
   - iOS: Xcode setup & signing configured properly.

> Note: The API base URL is already set in `NetworkPaths.baseUrl`. If the backend
> server is not reachable, network related features will fail or time out.

---

## 19. Original Flutter README (Preserved)

The section below comes from the default Flutter README that was generated when
the project was created. As required, it is kept unchanged.

### Flutter Template

- A new Flutter project.

#### Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
