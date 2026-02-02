# Delete Tour Time API Implementation

## Overview
Implemented the `deleteTourtime` API integration to track when users exit a tour and whether they submitted any samples/work.

## Changes Made

### 1. **Network Paths** (`lib/core/constants/network_paths.dart`)
- Added new constant: `static const String deleteTourTime = '/api/deleteTourtime';`

### 2. **Tour State Service** (`lib/core/services/tour_state_service.dart`)

#### New Method: `deleteTourTime()`
```dart
Future<void> deleteTourTime() async {
  if (activeTourId.value != null) {
    await _callDeleteTourTimeAPI(activeTourId.value!);
  }
}
```
- Convenience method to call the delete tour time API

#### New Method: `_callDeleteTourTimeAPI(String tourId)`
```dart
Future<void> _callDeleteTourTimeAPI(String tourId) async {
  // Gathers:
  // - driverId (from storage)
  // - tourId
  // - date (tour start date)
  // - time (current time when exiting)
  // - exit: 0 if no samples submitted, 1 if samples were submitted
  
  // Makes POST request to /api/deleteTourtime
}
```

**Key Features:**
- Determines `exit` flag based on `samplesSubmittedCount`:
  - `exit = 0`: User didn't submit any samples (just exited without work)
  - `exit = 1`: User submitted at least one sample (work was done)
- Captures current time when user exits
- Uses tour start date from storage
- Comprehensive logging for debugging

### 3. **Tour Details Screen** (`lib/features/dashboard/views/tour_dr_list_screen.dart`)

#### Updated Back Button Handler (2 locations)

**Location 1: WillPopScope.onWillPop**
```dart
// When tour is fully completed
if (completed >= totalDoctors && totalDoctors > 0) {
  await tourStateService.deleteTourTime();  // NEW
  await tourStateService.endTour();
  return true;
}

// In exit dialog callbacks
onConfirm: () async {
  await tourStateService.deleteTourTime();  // NEW
  await tourStateService.endTour();
},
onSilentExit: () async {
  await tourStateService.deleteTourTime();  // NEW
  print('🚪 Silent exit: Called deleteTourTime...');
},
```

**Location 2: AppBar Leading Button**
```dart
// When tour is fully completed
if (completed >= totalDoctors && totalDoctors > 0) {
  await tourStateService.deleteTourTime();  // NEW
  await tourStateService.endTour();
  Get.back();
  return;
}

// In exit dialog callbacks
onConfirm: () async {
  await tourStateService.deleteTourTime();  // NEW
  await tourStateService.endTour();
  Get.back();
},
onSilentExit: () async {
  await tourStateService.deleteTourTime();  // NEW
  print('🚪 Silent exit: Called deleteTourTime...');
  Get.back();
},
```

## API Behavior

### Request Payload
```json
{
  "driverId": 1,
  "tourId": 20,
  "date": "2026-01-27",
  "time": "15:30",
  "exit": 1
}
```

### Exit Flag Rules
- **exit = 0**: User opened tour but didn't submit any work (no samples/tasks completed)
- **exit = 1**: User submitted at least one sample or completed at least one task

### Automatic Tracking
- `samplesSubmittedCount` is automatically incremented via `TourStateService.incrementSamplesSubmitted()`
- This method is called whenever a sample is submitted in the app
- The exit flag is determined by checking this count when user exits

## Flow Diagram

```
User presses back button
         ↓
Check if tour is active
         ↓
If tour complete: deleteTourTime() → endTour() → Exit
         ↓
If tour incomplete: Show exit dialog
         ↓
    Option 1: Continue → Return to tour
         ↓
    Option 2: Exit without work (exit=0)
       → deleteTourTime() → Tour remains active → Exit
         ↓
    Option 3: Exit with work (exit=1)
       → deleteTourTime() → endTour() → Exit
```

## Logging
The implementation includes detailed logging:
```
📤 deleteTourTime URL: http://5.189.172.20:5000/api/deleteTourtime
📤 deleteTourTime Body: {...}
   - Driver ID: 1
   - Tour ID: 20
   - Date: 2026-01-27
   - Time: 15:30
   - Samples Submitted: 0
   - Exit Flag: 0 (0=no samples, 1=submitted samples)
📥 deleteTourTime Response: 200
📥 deleteTourTime Response Body: {...}
✅ Delete tour time API called successfully
```

## Testing Checklist

- [ ] User exits tour without submitting any work → exit=0
- [ ] User submits sample then exits → exit=1
- [ ] Time is captured correctly when exiting
- [ ] Date is correctly stored from tour start
- [ ] Driver ID is correctly retrieved from storage
- [ ] API response is logged correctly
- [ ] Both back button (WillPopScope) and AppBar back button work
- [ ] All exit scenarios (complete tour, partial exit, no work) work correctly

## Integration Points

1. **Sample Submission**: When `incrementSamplesSubmitted()` is called, it updates the counter
2. **Tour State**: Integrated with existing tour state management
3. **Exit Dialog**: Works seamlessly with existing exit confirmation dialog
4. **Logging**: Comprehensive debug logs for troubleshooting

## Notes

- The API call happens **before** `endTour()` to ensure accurate tracking
- Exit flag is based on actual submissions, not just doctor visits
- Time is captured at the moment of exit (not a fixed time)
- The implementation handles both "silent exit" (no work) and "confirmed exit" (with work) scenarios
