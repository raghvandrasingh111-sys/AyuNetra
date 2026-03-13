# How to Connect Supabase to Sanjeevni

## Step 1: Create a Supabase project

1. Go to **[supabase.com](https://supabase.com)** and sign in (or create an account).
2. Click **"New project"**.
3. Fill in:
   - **Name:** e.g. `sanjeevni`
   - **Database password:** choose a strong password and save it.
   - **Region:** pick the closest to you.
4. Click **Create new project** and wait until it’s ready (1–2 minutes).

---

## Step 2: Get your project URL and API key

1. In the left sidebar, open **Project Settings** (gear icon).
2. Click **API** in the left menu.
3. Copy these two values (you’ll use them in the app):
   - **Project URL** (e.g. `https://xxxxxxxxxxxx.supabase.co`)
   - **anon public** key (under "Project API keys")

---

## Step 3: Put the credentials in the app

1. Open **`lib/utils/constants.dart`** in your project.
2. Replace the placeholders with your values:

```dart
static const String supabaseUrl = 'https://YOUR-PROJECT-REF.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6...';  // your anon key
```

3. Save the file.

**Important:** The **anon** key is meant to be used in your app. Never put the **service_role** key in the app.

---

## Step 4: Create the database tables

1. In the Supabase dashboard, go to **SQL Editor**.
2. Click **New query**.
3. Open your project’s **`supabase_setup.sql`** file and copy its **entire** content.
4. Paste it into the SQL Editor.
5. Click **Run** (or press Cmd/Ctrl + Enter).
6. Confirm you see a success message and that there are no errors.

This creates:

- **profiles** (user data)
- **prescriptions** (prescription records)
- **Row Level Security** policies
- **Storage** bucket for prescription images

---

## Step 5: Turn on Email auth (for login/signup)

1. In Supabase, go to **Authentication** → **Providers**.
2. **Email** should be enabled by default.
3. Optional: Under **Authentication** → **Email Templates** you can edit confirmation emails.

For local testing you can disable “Confirm email”:

1. Go to **Authentication** → **Providers** → **Email**.
2. Turn **OFF** “Confirm email” if you don’t want to verify email for now.

---

## Step 6: Run the app

```bash
flutter run -d chrome
# or
flutter run -d macos
```

Then sign up with a new email/password. The app will use Supabase Auth and your new tables.

---

## Quick reference

| What        | Where to find it in Supabase          |
|------------|----------------------------------------|
| Project URL| Project Settings → API → Project URL   |
| anon key   | Project Settings → API → anon public   |
| Run SQL    | SQL Editor → New query → paste & Run   |
| Auth       | Authentication → Providers / Users     |
| Storage    | Storage → `prescriptions` bucket       |

---

## Troubleshooting

**“Invalid API key” or connection errors**  
- Double-check **Project URL** and **anon key** in `lib/utils/constants.dart`.  
- No quotes inside the string, no spaces at the start/end.

**“relation does not exist”**  
- Tables are missing. Run the full **`supabase_setup.sql`** script in the SQL Editor again.

**Sign up fails**  
- In Supabase: Authentication → Users. If “Confirm email” is ON, check your inbox or turn it off for testing.  
- Check Authentication → Providers → Email is enabled.

**Images don’t upload**  
- In Supabase: Storage. You should have a bucket named **`prescriptions`** (created by the SQL script).  
- If not, create a bucket named `prescriptions` and set it to **Public**.
