# Sanjeevani - Project Documentation

## Overview

**Sanjeevani** is a medical prescription management app built with Flutter. It allows patients and doctors to store, manage, and analyze prescriptions with AI-powered capabilities using Google Gemini.

---

## Directory Structure

```
sanjeevani/
├── lib/
│   ├── main.dart                     # App entry point
│   ├── models/
│   │   ├── user_model.dart           # User data model
│   │   └── prescription_model.dart   # Prescription data model
│   ├── providers/
│   │   ├── auth_provider.dart        # Authentication state
│   │   └── prescription_provider.dart # Prescription CRUD
│   ├── screens/
│   │   ├── splash_screen.dart        # Initial loading
│   │   ├── auth/
│   │   │   └── login_screen.dart     # Login/Signup
│   │   ├── patient/
│   │   │   ├── patient_dashboard.dart
│   │   │   ├── add_prescription_screen.dart
│   │   │   └── prescription_detail_screen.dart
│   │   └── doctor/
│   │       └── doctor_dashboard.dart
│   ├── services/
│   │   └── ai_service.dart           # Gemini AI integration
│   └── utils/
│       └── constants.dart            # Config & theme
└── pubspec.yaml
```

---

## Data Models

### UserModel (`lib/models/user_model.dart`)

```dart
class UserModel {
  final String id;              // UUID from Supabase auth
  final String email;
  final String name;
  final String userType;        // 'patient' or 'doctor'
  final String? phone;
  final String? profileImageUrl;
}
```

### Prescription (`lib/models/prescription_model.dart`)

```dart
class Prescription {
  final String id;
  final String doctorId;
  final String patientId;
  final String imageUrl;        // Uploaded prescription image
  final String? notes;
  final String? aiSummary;      // AI-generated summary
  final List<String>? medications;
  final String? dosage;
  final String? instructions;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## State Management (Provider Pattern)

### AuthProvider (`lib/providers/auth_provider.dart`)

Handles all authentication logic:

| Property | Type | Purpose |
|----------|------|---------|
| `currentUser` | `UserModel?` | Currently logged-in user |
| `isLoading` | `bool` | Loading state for UI |
| `errorMessage` | `String?` | Error messages |
| `isAuthenticated` | `bool` | Quick auth check |

**Key Methods:**
- `signIn(email, password, userType)` - Login with credentials
- `signUp(email, password, name, userType)` - Create account (email confirmation required)
- `signOut()` - Logout and clear session
- `loadCurrentUser()` - Restore session on app startup

### PrescriptionProvider (`lib/providers/prescription_provider.dart`)

Handles prescription operations:

| Property | Type | Purpose |
|----------|------|---------|
| `prescriptions` | `List<Prescription>` | User's prescriptions |
| `isLoading` | `bool` | Loading state |
| `errorMessage` | `String?` | Error messages |

**Key Methods:**
- `fetchPrescriptions(userId, userType)` - Load prescriptions
- `createPrescription(...)` - Create with AI analysis
- `uploadImage(file, userId)` - Upload to Supabase Storage
- `deletePrescription(id)` - Remove prescription

---

## Screens & Navigation

```
App Launch
    │
    ▼
SplashScreen (checks auth)
    │
    ├── User authenticated?
    │   ├── Patient → PatientDashboard
    │   └── Doctor  → DoctorDashboard
    │
    └── Not authenticated → LoginScreen
```

### Screen Details

| Screen | File | Purpose |
|--------|------|---------|
| **SplashScreen** | `splash_screen.dart` | Auth check, 2s delay, route to dashboard |
| **LoginScreen** | `auth/login_screen.dart` | Login/Signup toggle, user type selection |
| **PatientDashboard** | `patient/patient_dashboard.dart` | View prescriptions, add new |
| **DoctorDashboard** | `doctor/doctor_dashboard.dart` | Manage created prescriptions |
| **AddPrescriptionScreen** | `patient/add_prescription_screen.dart` | Upload image, add notes |
| **PrescriptionDetailScreen** | `patient/prescription_detail_screen.dart` | View full details + AI briefing |

---

## AI Service (`lib/services/ai_service.dart`)

Uses Google Gemini API for:

### 1. Prescription Analysis
When a prescription is uploaded, it extracts:
- Medications list
- Dosage information
- Usage instructions
- Summary

### 2. Patient Briefing Generation
Creates patient-friendly explanations:
- What medications to take
- When and how to take them
- Warnings and side effects
- What to do if a dose is missed

---

## Database Schema (Supabase)

### `profiles` Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key (from auth.users) |
| email | TEXT | User's email |
| name | TEXT | Display name |
| user_type | TEXT | 'patient' or 'doctor' |
| phone | TEXT | Optional phone number |
| profile_image_url | TEXT | Optional profile image |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update |

### `prescriptions` Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| doctor_id | UUID | Reference to auth.users |
| patient_id | UUID | Reference to auth.users |
| image_url | TEXT | Prescription image URL |
| notes | TEXT | Doctor's notes |
| ai_summary | TEXT | AI-generated summary |
| medications | TEXT[] | Array of medications |
| dosage | TEXT | Dosage information |
| instructions | TEXT | Usage instructions |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update |

### Storage Bucket
- **Name:** `prescriptions`
- **Access:** Public read for images
- **Structure:** `prescriptions/{user_id}/{filename}`

---

## Authentication Flow

### Sign Up
1. User selects type (Patient/Doctor)
2. Enters email, password, name
3. Supabase creates auth user
4. Profile row created (via trigger or manual)
5. Email confirmation sent
6. User clicks link → can now login

### Sign In
1. User selects type
2. Enters credentials
3. Supabase authenticates
4. Profile fetched from database
5. User type verified against selection
6. Navigates to appropriate dashboard

### Session Persistence
- On app launch, `SplashScreen` calls `loadCurrentUser()`
- Supabase checks for cached session
- If valid, auto-navigates to dashboard

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Backend (Auth, Database, Storage) |
| `provider` | State management |
| `google_generative_ai` | Gemini AI integration |
| `google_fonts` | Poppins typography |
| `image_picker` | Camera/gallery access |
| `cached_network_image` | Image caching |
| `intl` | Date formatting |

---

## Configuration (`lib/utils/constants.dart`)

```dart
// Supabase
static const String supabaseUrl = 'https://...supabase.co';
static const String supabaseAnonKey = 'eyJ...';

// Google Gemini
static const String geminiApiKey = 'AIza...';

// Theme Colors
static const Color primaryColor = Color(0xFF2E7D32);   // Green
static const Color secondaryColor = Color(0xFF66BB6A);
static const Color errorColor = Color(0xFFE53935);
static const Color successColor = Color(0xFF43A047);
```

---

## Core Features

### For Patients
- View all prescriptions
- Add new prescriptions (camera/gallery)
- Get AI-powered medication briefings
- Understand medications in simple language

### For Doctors
- Create prescriptions for patients
- Upload prescription images
- Add notes
- View all created prescriptions

### AI Features
- Automatic prescription analysis
- Medication extraction
- Dosage identification
- Patient-friendly briefing generation

---

## App Entry Point (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );

  runApp(const SanjeevaniApp());
}
```

The app uses `MultiProvider` to provide:
- `AuthProvider` - Authentication state
- `PrescriptionProvider` - Prescription state

---

## Theme

- **Design System:** Material Design 3
- **Primary Color:** Green (#2E7D32)
- **Typography:** Google Fonts (Poppins)
- **Style:** Gradient backgrounds, card-based layouts

---

## Security

- **Row Level Security (RLS):** Users only see their own data
- **Authenticated uploads:** Only logged-in users can upload
- **User type validation:** Prevents patient login as doctor and vice versa
- **Email confirmation:** Required before first login

---

## File Summary

| File | Lines | Description |
|------|-------|-------------|
| main.dart | ~109 | App setup, theme, providers |
| auth_provider.dart | ~241 | Auth logic |
| prescription_provider.dart | ~139 | Prescription CRUD |
| ai_service.dart | ~117 | Gemini integration |
| login_screen.dart | ~324 | Login/Signup UI |
| patient_dashboard.dart | ~229 | Patient home |
| doctor_dashboard.dart | ~230 | Doctor home |
| add_prescription_screen.dart | ~268 | Add prescription |
| prescription_detail_screen.dart | ~209 | View details |
| splash_screen.dart | ~107 | Initial screen |
| constants.dart | ~43 | Configuration |
| user_model.dart | ~40 | User model |
| prescription_model.dart | ~68 | Prescription model |
