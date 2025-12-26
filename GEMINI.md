# ITSUKI ALARM (SwiftUI)

## Project Overview

**ItsukiAlarm** is an iOS Alarm application built with **SwiftUI** and the **AlarmKit** framework (introduced in WWDC 2025). It serves as a comprehensive example (or "copycat") of a modern alarm app, featuring:

*   **Traditional Alarms:** Schedule one-shot or repeating alarms.
*   **Timers:** Countdown timers with Lock Screen and Dynamic Island support via Live Activities.
*   **Custom Alarms:** Flexible configuration for fixed dates, relative schedules, countdowns, and snooze options.

## Architecture & Core Logic

The project follows a SwiftUI-centric architecture with a central singleton manager for business logic.

### Key Components

*   **`ItsukiAlarmManager` (`Shared/ItsukiAlarmManager.swift`)**:
    *   **Role:** The central source of truth and controller.
    *   **Responsibilities:**
        *   Manages lifecycle of alarms (Add, Edit, Delete, Toggle).
        *   Interacts directly with `AlarmKit.AlarmManager` to schedule system alarms.
        *   Persists local metadata (titles, icons) using `UserDefaults` (App Group: `group.itsukiAlarm`).
        *   Observes system alarm updates and syncs them with local state.
*   **`ItsukiAlarm` (`Shared/Models/ItsukiAlarm.swift`)**:
    *   **Role:** The main data model.
    *   **Details:** Wraps the system `AlarmKit.Alarm` object and combines it with custom `_AlarmMetadata`. It also calculates the current presentation state (alerting, countdown, paused) based on the alarm's status.
*   **`CountdownLiveActivity`**:
    *   Contains the Widget Extension for Live Activities, allowing timer countdowns to appear on the Lock Screen and Dynamic Island.

### Data Flow

1.  **UI Interaction:** The user creates/modifies an alarm in the SwiftUI views (`ItsukiAlarm/Views/`).
2.  **Manager Action:** The view calls `ItsukiAlarmManager.shared` methods (e.g., `addAlarm`, `stopAlarm`).
3.  **System Sync:** The manager updates `AlarmKit` and saves metadata to `UserDefaults`.
4.  **Updates:** The app observes `AlarmManager.alarmUpdates` to reflect state changes (e.g., alarm firing, snooze) back into the UI.

## File Structure

*   **`ItsukiAlarm/`**: Main app bundle.
    *   `ItsukiAlarmApp.swift`: App entry point.
    *   `Views/`: SwiftUI Views (Alarms, Timers, Custom).
    *   `Components/`: Reusable UI components (Pickers, Badges).
*   **`Shared/`**: Code shared between the main app and extensions.
    *   `ItsukiAlarmManager.swift`: Core business logic.
    *   `Models/`: Data models (`ItsukiAlarm`, `AlarmMetadata`).
    *   `Extensions/`: Swift extensions for helper functionality.
*   **`CountdownLiveActivity/`**: Widget Extension for Live Activities.

## Building and Running

**Prerequisites:**
*   macOS with Xcode 16+ (Required for AlarmKit support).
*   iOS 18+ (Target OS).

**Steps:**
1.  Open `ItsukiAlarm.xcodeproj` in Xcode.
2.  Select the **ItsukiAlarm** scheme.
3.  Ensure your development team is selected in the Signing & Capabilities tab for all targets.
4.  Run on a Simulator or Device.

## Development Conventions

*   **Concurrency:** Heavy use of Swift Concurrency (`async`/`await`, `@MainActor`).
*   **Persistence:** `UserDefaults` is used for lightweight metadata storage, keyed by App Group ID to share data with extensions.
*   **Error Handling:** Custom error types (e.g., `_Error` in `ItsukiAlarmManager`) are used to manage authorization and scheduling failures.
*   **Localization:** Strings are wrapped in `LocalizedStringResource`.
