# Sanjeevni Setup Guide

Follow these steps to set up and run the Sanjeevni app on your machine.

## Step 1: Install Flutter

If you haven't already, install Flutter:

1. Visit [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Follow the installation instructions for your operating system
3. Verify installation by running: `flutter doctor`

## Step 2: Set Up Supabase

### 2.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Fill in your project details:
   - Name: `sanjeevni` (or any name you prefer)
   - Database Password: Choose a strong password
   - Region: Choose the closest region
4. Wait for the project to be created (takes a few minutes)

### 2.2 Set Up Database

1. In your Supabase project, go to **SQL Editor**
2. Click **New Query**
3. Copy and paste the entire contents of `supabase_setup.sql`
4. Click **Run** (or press Cmd/Ctrl + Enter)
5. Verify that all tables and policies were created successfully

### 2.3 Set Up Storage

1. Go to **Storage** in your Supabase dashboard
2. You should see a bucket named `prescriptions` (created by the SQL script)
3. If not, create it manually:
   - Click **New bucket**
   - Name: `prescriptions`
   - Make it **Public**

### 2.4 Get API Credentials

1. Go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (under "Project URL")
   - **anon/public key** (under "Project API keys")

## Step 3: Set Up Google Gemini API

### 3.1 Get API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click **Create API Key**
4. Select or create a Google Cloud project
5. Copy the generated API key

### 3.2 Enable Gemini API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Library**
4. Search for "Generative Language API"
5. Click **Enable**

## Step 4: Configure the App

1. Open `lib/utils/constants.dart`
2. Replace the placeholder values:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';  // Paste your Supabase URL
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';  // Paste your anon key
static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';  // Paste your Gemini API key
```

## Step 5: Install Dependencies

Open your terminal in the project directory and run:

```bash
flutter pub get
```

## Step 6: Run the App

### For iOS (macOS only):

```bash
flutter run -d ios
```

### For Android:

```bash
flutter run -d android
```

### For Web:

```bash
flutter run -d chrome
```

## Step 7: Test the App

1. **Create a Doctor Account:**
   - Open the app
   - Select "Doctor" user type
   - Sign up with a new email
   - Complete registration

2. **Create a Patient Account:**
   - Log out (if logged in as doctor)
   - Select "Patient" user type
   - Sign up with a different email
   - Complete registration

3. **Test Prescription Upload:**
   - Login as doctor
   - Click "Create Prescription"
   - Upload a prescription image
   - Add notes (optional)
   - Save

4. **View as Patient:**
   - Log out and login as patient
   - View the prescription
   - Check AI summary and briefing

## Troubleshooting

### Issue: "Supabase connection failed"
- **Solution**: Verify your Supabase URL and anon key in `constants.dart`
- Check if your Supabase project is active

### Issue: "AI analysis not working"
- **Solution**: Verify your Gemini API key in `constants.dart`
- Check if Generative Language API is enabled in Google Cloud Console
- Ensure you have API quota available

### Issue: "Image upload failed"
- **Solution**: Verify storage bucket `prescriptions` exists and is public
- Check storage policies in Supabase

### Issue: "Authentication failed"
- **Solution**: Check Supabase Auth settings
- Verify email confirmation is not required (or confirm your email)
- Check Supabase logs for detailed error messages

## Next Steps

- Customize the UI colors in `lib/utils/constants.dart`
- Add more features like appointment scheduling
- Implement push notifications
- Add prescription sharing capabilities

## Support

For issues or questions:
- Check Supabase documentation: [supabase.com/docs](https://supabase.com/docs)
- Check Flutter documentation: [flutter.dev/docs](https://flutter.dev/docs)
- Check Google Gemini documentation: [ai.google.dev](https://ai.google.dev)
