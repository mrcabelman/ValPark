# ParkCol

A native iOS app for valet parking services. Built with SwiftUI and SwiftData.

---

## Overview

ParkCol lets valet attendants check vehicles in and out, track parking status in real time, manage payments, and generate revenue reports — with full English/Spanish localization and optional Google Drive sync.

---

## Features

### Active Tickets
- Live list of all currently parked vehicles
- Real-time elapsed timer on every ticket card
- Color-coded payment and status badges
- Active ticket count shown in the navigation bar
- Tap any ticket to open the full detail view

### Check-In Flow
- Customer first name, last name, and phone number
- Vehicle description (make, model, color)
- Parking zone selector (zones are user-defined in Settings)
- Payment timing: **Pay Before**, **Pay Half**, **Pay After**
- Payment method: **Cash**, **Card**, **Neiki**, **Bancolombia Transfer**
- Parking start and end time pickers
- Dollar amount field
- Up to 5 vehicle photos from camera or photo library
- Optional notes (e.g. pre-existing damage)
- Automatic push notification scheduling on check-in

### Ticket Lifecycle
Tickets progress through a linear status pipeline:

```
Parked → Car Requested → On The Way → Delivered
                                    ↘ Cancelled
```

The detail view shows a visual timeline with timestamps for check-in and delivery. Status can be advanced one step at a time or cancelled with a confirmation dialog.

### History
- Searchable list of all delivered and cancelled tickets
- Search by customer name or vehicle description
- Tap any record to review full details

### Reports
- Filter by parking zone (or all zones) and custom date/time range
- Displays: total tickets, delivered count, cancelled count, and total revenue

### Settings
- Add and remove named parking zones
- Language toggle: English / Español
- App version and notification status info

### Notifications
- **15-minute warning** before a ticket's expected end time
- **Expiry alert** when parking time runs out
- Notifications are cancelled automatically on check-out or cancellation
- Bilingual notification text matches the current app language

### Google Integration
- Google Sign-In on the welcome screen
- Settings (parking zones + language) sync to the user's private Google Drive App Data folder via the Drive v3 API

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Persistence | SwiftData |
| State management | Swift `@Observable` |
| Notifications | UserNotifications |
| Photos | PhotosUI |
| Cloud sync | Google Drive API v3 |
| Auth | Google Sign-In |
| Minimum target | iOS 17 |
| Language | Swift 5.9+ |

---

## Project Structure

```
ParkCol/
├── ParkColApp.swift          # App entry point, SwiftData container setup
├── MainTabView.swift         # Root tab bar (Active / History / Settings)
│
├── Model
│   ├── ParkingTicket.swift   # SwiftData model + enums (status, payment)
│   └── Item.swift
│
├── Views
│   ├── WelcomeView.swift     # Google Sign-In screen + language toggle
│   ├── ActiveView.swift      # Live ticket list + TicketRowView + StatusBadge
│   ├── AddTicketView.swift   # New ticket form + shared sub-views
│   ├── CarDetailsView.swift  # Ticket detail, status advancement, TimelineCard
│   ├── HistoryView.swift     # Completed/cancelled ticket search list
│   ├── ReportSheetView.swift # Revenue report with date/zone filters
│   └── SettingsView.swift    # Zone management, language, app info
│
└── Services
    ├── AppSettings.swift         # Observable parking zone list (UserDefaults)
    ├── AuthManager.swift         # Google Sign-In wrapper
    ├── CloudSyncManager.swift    # Google Drive App Data sync
    ├── Localization.swift        # LocalizationManager + EN/ES string tables
    └── NotificationManager.swift # Schedule/cancel UNUserNotificationCenter reminders
```

---

## Data Model

### `ParkingTicket` (SwiftData `@Model`)

| Property | Type | Description |
|---|---|---|
| `id` | `UUID` | Unique identifier |
| `customerFirstName` | `String` | Customer first name |
| `customerLastName` | `String` | Customer last name |
| `phoneNumber` | `String` | Contact phone number |
| `vehicle` | `String` | Vehicle description |
| `parkingZone` | `String` | Zone where the car is parked |
| `paymentTiming` | `PaymentTiming` | Pay Before / Pay Half / Pay After |
| `paymentMethod` | `PaymentMethod` | Cash / Card / Neiki / Bancolombia Transfer |
| `amount` | `Double` | Parking fee |
| `notes` | `String` | Optional attendant notes |
| `status` | `TicketStatus` | Current lifecycle status |
| `checkedInAt` | `Date` | Check-in timestamp |
| `deliveredAt` | `Date?` | Delivery timestamp |
| `expectedEndTime` | `Date?` | Used to schedule expiry notifications |

### `TicketStatus`

| Value | Color |
|---|---|
| `parked` | Blue |
| `carRequested` | Orange |
| `onTheWay` | Yellow |
| `delivered` | Green |
| `cancelled` | Red |

---

## Localization

All UI strings are served through `LocalizationManager`, an `@Observable` class with built-in English and Spanish dictionaries. The active language is persisted in `UserDefaults` and can be changed at any time from the Welcome screen or Settings — no app restart required.

---

## Cloud Sync

Settings (parking zones and language preference) are stored as a single JSON file (`parkcol_settings.json`) in the user's Google Drive **App Data** folder. This folder is private to the app and not visible in the user's Drive. Sync is triggered manually from the Settings screen after signing in with Google.

---

## Requirements

- Xcode 15 or later
- iOS 17 or later
- A Google Cloud project with the Drive API and Sign-In SDK configured (for cloud sync features)

---

## Build

Open `ParkCol.xcodeproj` in Xcode, select a simulator or connected device running iOS 17+, and press **Run**.
