# Login not working – what to check

## 1. Configure Firebase first

- Run **`dart run flutterfire_cli:configure`** once so **lib/firebase_options.dart** is generated. See **FIREBASE_SETUP.md**.
- In Firebase Console: **Authentication** → **Sign-in method** → enable **Email/Password**.

## 2. Use Sign up first

- If you never signed up, use **Sign up** (toggle below the button), choose **Patient** or **Doctor**, enter name, email, and password (6+ characters), then sign up.
- Then use **Login** with the same email and password, and the **same** role (Patient or Doctor).

## 3. Patient vs Doctor

- Select **Patient** or **Doctor** **before** logging in; it must match how you signed up.

## 4. "No profile found"

- Your Firebase user exists but there is no **profiles** document in Firestore. Sign up again with the same email so the app can create the profile.

## 5. Invalid email or password

- Use the same email and password you used when signing up. If needed, **Sign up** again with a new email.

## 6. Network / configuration

- Check your internet connection.
- Ensure Firestore and Storage are created in the same Firebase project and rules are published (see **FIREBASE_SETUP.md**).
