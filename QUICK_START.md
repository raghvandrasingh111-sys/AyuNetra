# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Configure Credentials

Edit `lib/utils/constants.dart` and add your credentials:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
static const String geminiApiKey = 'your-gemini-api-key-here';
```

### 2. Set Up Supabase Database

1. Go to your Supabase project → SQL Editor
2. Copy and paste contents of `supabase_setup.sql`
3. Run the SQL script

### 3. Install & Run

```bash
flutter pub get
flutter run
```

## 📱 App Features

### For Patients:
- ✅ View all prescriptions
- ✅ AI-powered prescription summaries
- ✅ Patient-friendly medication briefings
- ✅ Prescription image viewing

### For Doctors:
- ✅ Create prescriptions for patients
- ✅ Upload prescription images
- ✅ View all created prescriptions
- ✅ AI-powered prescription analysis

## 🎨 UI Highlights

- Modern Material Design 3
- Beautiful gradient backgrounds
- Smooth animations
- Intuitive navigation
- Responsive layouts

## 🔐 Security

- Row Level Security (RLS) enabled
- Secure authentication
- Encrypted data storage
- User-specific data access

## 📝 Notes

- Make sure to run the Supabase SQL script before using the app
- Both Supabase and Gemini API keys are required
- Storage bucket must be public for image viewing

For detailed setup instructions, see `SETUP_GUIDE.md`
