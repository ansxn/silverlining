# StormMode MVP

> A closed-loop care coordination iOS app for remote Canadian communities with Storm Mode resilience.

![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2017+-blue)
![Status](https://img.shields.io/badge/Status-MVP%20Demo-green)

## 🌨️ What is StormMode?

StormMode is a care coordination app designed for Clearwater Ridge, a remote northern Canadian community (~1,800 residents). When winter storms close the highway, the app activates **Storm Mode** to:

- ✅ Track **referrals** from creation to completion (closed-loop)
- 🚗 Coordinate **transportation** (rides, pharmacy pickups)
- 📱 Trigger **wellness check-ins** for vulnerable residents
- 📋 Generate **tasks** for clinic staff follow-up

## 🚀 Quick Start

### Prerequisites
- **Xcode 15+** (with iOS 17 SDK)
- **macOS Sonoma** or later recommended

### Run the App

1. **Open in Xcode**
   ```bash
   open /Users/anson/Documents/silverlining/stormmode/StormMode.xcodeproj
   ```

2. **Select a Simulator**
   - Click the device dropdown in Xcode
   - Choose "iPhone 15 Pro" or any iOS 17+ simulator

3. **Build & Run**
   - Press `Cmd + R` or click the Play button
   - The app will launch in the simulator

### Demo the App

The app includes a **role switcher** in the bottom navigation:

| Role | Experience |
|------|------------|
| **Clinic Staff** | Dashboard, create referrals, manage tasks, toggle Storm Mode |
| **Patient** | View referrals, request rides, see storm status |
| **Volunteer** | View open requests, accept rides, complete jobs |

**Demo Flow:**
1. Start as **Clinic Staff** → Toggle **Storm Mode ON**
2. See check-in tasks auto-generated for vulnerable patients
3. Switch to **Patient** → See storm banner, view referral details
4. Switch to **Volunteer** → Accept a ride request
5. Back to **Staff** → Simulate check-in responses

## 📁 Project Structure

```
StormMode/
├── StormModeApp.swift          # App entry point
├── ContentView.swift           # Root navigation + role switcher
│
├── Models/
│   ├── User.swift              # User with roles
│   ├── Referral.swift          # Referral tracking
│   ├── TransportRequest.swift  # Rides & pickups
│   ├── Task.swift              # Clinic workflow tasks
│   ├── StormState.swift        # Storm mode state
│   └── CheckIn.swift           # Wellness check-ins
│
├── Services/
│   └── MockDataService.swift   # Mock data for demo
│
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── PatientViewModel.swift
│   ├── VolunteerViewModel.swift
│   └── ClinicStaffViewModel.swift
│
├── Views/
│   ├── Components/             # Reusable UI components
│   ├── Patient/                # Patient screens
│   ├── Volunteer/              # Volunteer screens
│   └── ClinicStaff/            # Staff screens
│
└── Design/
    ├── Colors.swift            # Color palette
    ├── Typography.swift        # Font styles
    └── Styles.swift            # Reusable modifiers
```

## 🎨 Design System

The UI follows a soft, warm aesthetic inspired by modern wellness apps:

- **Background**: Soft peachy beige (`#F5EDE4`)
- **Cards**: Pastel colors (lavender, mint, yellow, coral, sage)
- **Typography**: Rounded, friendly fonts
- **Progress**: Bubble grid visualizations
- **Storm Mode**: Deep indigo accent with pulse animation

## 🔧 Current Status (MVP)

### ✅ Implemented
- [x] Full project structure
- [x] Design system (colors, typography, styles)
- [x] All data models
- [x] Mock data service with sample data
- [x] Role-based navigation
- [x] Patient home, referral detail, create request
- [x] Volunteer request list and assignment
- [x] Staff dashboard with Storm Mode toggle
- [x] Check-in simulation
- [x] Demo role switcher

### ❌ Not Yet Implemented (Future Work)
- [ ] Firebase integration
- [ ] Twilio SMS
- [ ] Real authentication
- [ ] Push notifications
- [ ] Admin web dashboard

## 📱 Screenshots

Launch the app in Xcode Simulator to see:

1. **Staff Dashboard** - Metrics grid, storm toggle, tasks
2. **Storm Mode Active** - Banner, check-in cards, urgent alerts
3. **Patient Home** - Greeting, progress bubbles, referrals
4. **Volunteer View** - Open requests, accept/complete flow

## 🔮 Next Steps

To connect to real backend:

1. **Add Firebase SDK** via Swift Package Manager
2. **Replace MockDataService** with Firestore listeners
3. **Add Cloud Functions** for:
   - `activateStormMode()` - Bulk SMS, task generation
   - `smsWebhookHandler()` - Inbound SMS parsing
   - `sweepForMissedAppointments()` - Scheduled cleanup
4. **Configure Twilio** for SMS notifications

---

Built for hackathon demo purposes. 🏥⛈️
