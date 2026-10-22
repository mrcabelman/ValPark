# ValPark

A valet parking management app for iOS built with SwiftUI and Firebase.

---

## Overview

ValPark lets valet teams create and manage parking tickets, track vehicle status in real time, and collaborate within shared organizations — all backed by Firebase Auth and Firestore.

---

## What Changed from ParkCol

| Area | Before (ParkCol) | After (ValPark) |
|---|---|---|
| Auth | Google Sign-In only (no account required) | Firebase Auth — email/password + Google SSO |
| Persistence | SwiftData (on-device) | Firestore (cloud, real-time) |
| Multi-user | Single device | Organizations with role-based membership |
| Settings sync | Google Drive App Data | Firestore (org data) |
| Email verification | None | Required for email/password accounts |
| Ticket ownership | Device-local | Per-org, keyed off Firebase UID |

---

## Features

### Authentication
- **Email/Password** sign-up and sign-in with Firebase Auth
- **Google Sign-In (SSO)** — one-tap sign-in via the GoogleSignIn SDK
- **Email verification gate** — email/password users must verify before accessing the app; Google users skip this step (pre-verified by Google)
- **Persistent sessions** — Firebase Auth state listener restores the session on launch automatically

### Organizations
- **Create an organization** with a globally unique name (enforced via a Firestore transaction on an `orgNames` lock collection — no duplicates possible)
- **Join by name** — submit a join request; an admin must approve before access is granted
- **Multi-org support** — belong to multiple organizations and switch between them
- **Admin controls:**
  - View the full member list and roles
  - Add members directly by email (target must already have a ValPark account)
  - Approve or deny pending join requests
  - Promote/demote members between `admin` and `member` roles
  - Remove members
  - Last-admin guard — prevents removing or demoting the only admin
  - Add and remove **parking zones** for the organization
- Real-time Firestore listeners keep member list, join requests, and org data live across all devices

### Parking Tickets
- Check in a vehicle: customer name, phone, vehicle description, parking zone, payment timing/method, amount, and notes
- Ticket status lifecycle: **Parked → Car Requested → On The Way → Delivered / Cancelled**
- **Active tickets** view with live elapsed timers and color-coded status/payment badges
- **History** view — searchable list of all delivered and cancelled tickets for the current org
- **Car details sheet** — full ticket info, status advancement, and edit capability
- **PDF report** generation per ticket

### Cloud & Real-Time Sync
- All tickets stored in Firestore at `organizations/{orgId}/tickets/{ticketId}`
- Org members see each other's tickets in real time with no manual refresh

### Notifications
- Local push notification when a join request arrives (shown on admin devices)
- Notification permission requested at first launch

### Localization
- English and Spanish supported throughout
- Language toggle on the sign-in screen and in Settings — no app restart required

---

## App Navigation

```
Not signed in           → WelcomeView  (email/password or Google sign-in + sign-up link)
Signed in, unverified   → VerifyEmailView  (email/password accounts only)
Verified, no org        → OrganizationsView  (create or join an org)
Verified + org member   → MainTabView  (Active | History | Settings)
```

---

## Architecture

| File | Role |
|---|---|
| `ParkColApp.swift` | App entry point; `FirebaseApp.configure()`, environment injection, `RootView` auth router |
| `FirebaseAuthManager.swift` | Firebase Auth wrapper — email/password + Google SSO, Firestore `users/{uid}` profile |
| `OrganizationStore.swift` | Org CRUD, membership management, join-request flow, Firestore listeners |
| `TicketStore.swift` | Ticket CRUD backed by Firestore |
| `OrganizationModels.swift` | `UserProfile`, `Organization`, `Membership`, `JoinRequest` Codable structs |
| `ParkingTicket.swift` | `ParkingTicket` Codable struct + `TicketStatus`, `PaymentTiming`, `PaymentMethod` enums |
| `CloudSyncManager.swift` | Firestore path helpers and sync utilities |
| `NotificationManager.swift` | Local notification scheduling and permission |
| `Localization.swift` | `LocalizationManager` — in-app EN/ES switching backed by UserDefaults |
| `WelcomeView.swift` | Sign-in screen (email/password form + Google button + language toggle) |
| `SignUpView.swift` | Email/password account creation sheet |
| `VerifyEmailView.swift` | Email verification gate with resend and reload |
| `OrganizationsView.swift` | Onboarding — create or join an org |
| `OrgMembersView.swift` | Admin member management, join-request approval |
| `MainTabView.swift` | Root tab bar (Active / History / Settings) |
| `ActiveView.swift` | Live ticket list with timers |
| `AddTicketView.swift` | New ticket check-in form |
| `CarDetailsView.swift` | Ticket detail, status advancement |
| `HistoryView.swift` | Completed/cancelled ticket search |
| `ReportSheetView.swift` | Revenue report with filters |
| `SettingsView.swift` | Org info, language, sign-out |

---

## Data Model

### `ParkingTicket`

| Property | Type | Description |
|---|---|---|
| `id` | `String` | UUID — also the Firestore document ID |
| `customerFirstName/LastName` | `String` | Customer name |
| `phoneNumber` | `String` | Contact phone |
| `vehicle` | `String` | Vehicle description |
| `parkingZone` | `String` | Zone within the org |
| `paymentTiming` | `PaymentTiming` | Pay Before / Pay Half / Pay After |
| `paymentMethod` | `PaymentMethod` | Cash / Card / Neiki / Bancolombia Transfer |
| `amount` | `Double` | Parking fee |
| `notes` | `String` | Attendant notes |
| `status` | `TicketStatus` | Current lifecycle status |
| `checkedInAt` | `Date` | Check-in timestamp |
| `deliveredAt` | `Date?` | Delivery timestamp |
| `expectedEndTime` | `Date?` | For notification scheduling |
| `createdBy` | `String` | UID of the attendant who checked in the car |
| `orgId` | `String` | Organization this ticket belongs to |

### `Organization`

| Property | Description |
|---|---|
| `id` | UUID |
| `name` | Display name |
| `nameLower` | Lowercase — used for case-insensitive uniqueness |
| `createdBy` | UID of the creator |
| `parkingZones` | Array of zone name strings |
| `myRole` | Transient — `.admin` or `.member` (populated from the membership document) |

### Firestore Collections

```
users/{uid}
orgNames/{nameLower}                          ← name uniqueness lock
organizations/{orgId}
organizations/{orgId}/members/{uid}
organizations/{orgId}/joinRequests/{uid}
organizations/{orgId}/tickets/{ticketId}
```

---

## Firebase Setup

### 1. Firebase Console

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and open (or create) your Firebase project.
2. **Add an iOS app** — use your bundle ID (e.g. `com.yourname.ValPark`).
3. Download `GoogleService-Info.plist` and drag it into Xcode under the `ValPark` target (check **Add to targets: ValPark**).
4. Under **Authentication → Sign-in method**, enable:
   - **Email/Password**
   - **Google**
5. Under **Firestore Database**, create a Firestore database.

### 2. Google Sign-In URL Scheme

The `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist` must be registered as a URL scheme so Google's OAuth redirect works. It is already configured in `Info.plist`:

```
CFBundleURLTypes → GoogleSignIn → CFBundleURLSchemes:
  com.googleusercontent.apps.14302625617-5hacp1nu2f898516vlf37a1gf4jrpmid
```

If you switch to a different Firebase project, replace this value with the `REVERSED_CLIENT_ID` from your new `GoogleService-Info.plist`.

### 3. Firestore Index

The org membership query uses a collection-group query that requires a composite index:

| Collection group | Field | Order |
|---|---|---|
| `members` | `uid` | Ascending |

On first run against a new project, Firestore returns an error with a direct link to create the index in one click.

### 4. Firestore Security Rules (starter)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    match /orgNames/{name} {
      allow read, write: if request.auth != null;
    }

    match /organizations/{orgId} {
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/organizations/$(orgId)/members/$(request.auth.uid));
      allow write: if request.auth != null;

      match /members/{uid} {
        allow read, write: if request.auth != null;
      }

      match /joinRequests/{uid} {
        allow read, write: if request.auth != null;
      }

      match /tickets/{ticketId} {
        allow read, write: if request.auth != null &&
          exists(/databases/$(database)/documents/organizations/$(orgId)/members/$(request.auth.uid));
      }
    }
  }
}
```

---

## Package Dependencies

| Package | Purpose |
|---|---|
| Firebase (FirebaseAuth, FirebaseFirestore) | Auth and real-time database |
| GoogleSignIn | Google SSO |
| GTMSessionFetcher | HTTP transport (Firebase transitive dependency) |
| AppCheck | Firebase App Check |
| GoogleAppMeasurement | Analytics |

---

## Requirements

- iOS 17+
- Xcode 16+
- A Firebase project with Authentication (Email/Password + Google) and Firestore enabled
