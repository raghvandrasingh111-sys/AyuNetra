# Supabase backend setup for Sanjeevani

1. Create a project at [supabase.com](https://supabase.com).
2. In **Project Settings → API**, copy the **Project URL** and **anon public** key into `lib/utils/constants.dart`:
   - `supabaseUrl` = Project URL  
   - `supabaseAnonKey` = anon public key

3. In the Supabase **SQL Editor**, run the script below.

4. In **Storage**, create a bucket named `prescriptions` and set it to **Public** (or add a policy that allows public read and authenticated upload/delete as needed).

5. **Login without email verification:** In **Authentication → Providers → Email**, turn **OFF** "Confirm email" so users (especially doctors using a registration number) can log in right after sign up. If you leave it ON, you may see "email rate limit exceeded" after several signup attempts, and doctors won’t receive a real confirmation email.

---

## SQL script (run in SQL Editor)

```sql
-- Enable UUID extension if not already
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('patient', 'doctor')),
  phone TEXT,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Prescriptions
CREATE TABLE IF NOT EXISTS public.prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  notes TEXT,
  ai_summary TEXT,
  medications TEXT[],
  dosage TEXT,
  instructions TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/update their own row; insert only for own id
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Prescriptions: doctors/patients see their related rows
CREATE POLICY "Users can view prescriptions where they are doctor or patient"
  ON public.prescriptions FOR SELECT
  USING (auth.uid() = doctor_id OR auth.uid() = patient_id);

CREATE POLICY "Authenticated users can insert prescriptions"
  ON public.prescriptions FOR INSERT
  WITH CHECK (auth.uid() = doctor_id);

CREATE POLICY "Doctors can delete prescriptions they created"
  ON public.prescriptions FOR DELETE
  USING (auth.uid() = doctor_id);

-- Trigger to create profile on signup (uses name/user_type from signUp data)
```

---

## Migration: Aadhar & Doctor registration (run if you already have the base tables)

Run this in the SQL Editor to add patient Aadhar and doctor registration number support:

```sql
-- Add columns to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS aadhar_number TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS doctor_registration_number TEXT;

-- Allow doctors to read patient profiles (id, aadhar_number) for prescription lookup by Aadhar
CREATE POLICY "Doctors can view patient profiles for lookup"
  ON public.profiles FOR SELECT
  USING (
    (SELECT p.user_type FROM public.profiles p WHERE p.id = auth.uid()) = 'doctor'
    AND user_type = 'patient'
  );
```

- **Patient signup**: requires email + unique 12-digit Aadhar.
- **Doctor login/signup**: uses Doctor Registration Number + password (stored internally as `{number}@sanjeevani.doctor`).
- **Doctor upload prescription**: doctor enters patient’s Aadhar number; app finds the patient and links the prescription.

---

## Feature: Patient-approved doctor access (medical history via Aadhar)

This enables:
- Doctor requests access using patient Aadhar
- Patient approves/denies
- Only **approved** doctors can view that patient’s prescriptions/history

Run this SQL in Supabase SQL Editor:

```sql
-- Doctor ↔ Patient access requests
CREATE TABLE IF NOT EXISTS public.doctor_patient_access (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending','approved','denied')) DEFAULT 'pending',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at TIMESTAMPTZ,
  UNIQUE (doctor_id, patient_id)
);

ALTER TABLE public.doctor_patient_access ENABLE ROW LEVEL SECURITY;

-- Doctors can create (request) access for themselves
CREATE POLICY "Doctors can request access"
  ON public.doctor_patient_access FOR INSERT
  WITH CHECK (auth.uid() = doctor_id);

-- Doctors can view their own requests
CREATE POLICY "Doctors can view own access requests"
  ON public.doctor_patient_access FOR SELECT
  USING (auth.uid() = doctor_id);

-- Patients can view requests to them
CREATE POLICY "Patients can view access requests"
  ON public.doctor_patient_access FOR SELECT
  USING (auth.uid() = patient_id);

-- Patients can approve/deny requests to them
CREATE POLICY "Patients can update access requests"
  ON public.doctor_patient_access FOR UPDATE
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

-- Allow approved doctors to read patient prescriptions (medical history)
DROP POLICY IF EXISTS "Users can view prescriptions where they are doctor or patient" ON public.prescriptions;

CREATE POLICY "Users can view prescriptions where they are doctor or patient or approved doctor"
  ON public.prescriptions FOR SELECT
  USING (
    auth.uid() = doctor_id
    OR auth.uid() = patient_id
    OR EXISTS (
      SELECT 1
      FROM public.doctor_patient_access a
      WHERE a.doctor_id = auth.uid()
        AND a.patient_id = public.prescriptions.patient_id
        AND a.status = 'approved'
    )
  );
```

Notes:
- If you already have a `prescriptions` SELECT policy with a different name, adjust the `DROP POLICY` line.
- This grants doctors access to **all** prescriptions for the approved patient (even if created by other doctors), which matches “full medical history”.

## Storage bucket `prescriptions`

1. Go to **Storage** in the Supabase dashboard.
2. Create a bucket named **`prescriptions`** and set it to **Public** (so `getPublicUrl` works).
3. Run the **Storage policies** below in the SQL Editor. Without these, you get **"new row violates row-level security policy" / 403 Unauthorized** when saving a prescription.

### Storage policies (run in SQL Editor)

Run this **after** the bucket `prescriptions` exists:

```sql
-- Allow anyone to view files in prescriptions bucket (for public URLs)
CREATE POLICY "Anyone can view prescriptions bucket"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'prescriptions');

-- Allow any authenticated user (doctors) to upload prescription images
CREATE POLICY "Authenticated users can upload prescriptions"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'prescriptions' AND auth.role() = 'authenticated');

-- Allow users to delete their own uploads (path is userId/filename)
CREATE POLICY "Users can delete own prescription uploads"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'prescriptions' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

If you see "policy already exists", the policies are there; you can skip or drop and re-create.

---

## Migration: Record type (Prescription vs Lab Report)

Run this in the SQL Editor to support separate Prescriptions and Lab Reports:

```sql
-- Add record_type column (prescription | lab_report)
ALTER TABLE public.prescriptions
  ADD COLUMN IF NOT EXISTS record_type TEXT NOT NULL DEFAULT 'prescription'
  CHECK (record_type IN ('prescription', 'lab_report'));
```

Existing rows will default to `'prescription'`. New uploads can be saved as either prescriptions or lab reports.

---

## Migration: Manual Prescription Fields

Run this in the SQL Editor to support the new manual prescription fields:

```sql
-- Make image optional (for manual entry)
ALTER TABLE public.prescriptions ALTER COLUMN image_url DROP NOT NULL;

-- Add new manual fields
ALTER TABLE public.prescriptions
  ADD COLUMN IF NOT EXISTS patient_name TEXT,
  ADD COLUMN IF NOT EXISTS patient_age TEXT,
  ADD COLUMN IF NOT EXISTS patient_height TEXT,
  ADD COLUMN IF NOT EXISTS blood_pressure TEXT,
  ADD COLUMN IF NOT EXISTS pulse_rate TEXT,
  ADD COLUMN IF NOT EXISTS gender TEXT,
  ADD COLUMN IF NOT EXISTS is_manual BOOLEAN DEFAULT FALSE;
```

Existing rows will remain unchanged.

---

After this, run `flutter pub get` and configure `Constants.supabaseUrl` and `Constants.supabaseAnonKey` in `lib/utils/constants.dart`.
