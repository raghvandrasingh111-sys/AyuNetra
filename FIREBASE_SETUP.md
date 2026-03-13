# Connect Sanjeevni to Firebase

The app uses **Firebase Auth**, **Cloud Firestore**, and **Firebase Storage**. Follow these steps once.

---

## 1. Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and sign in.
2. Click **Add project** (or use an existing one).
3. Name it (e.g. **Sanjeevni**), disable Google Analytics if you prefer, then create the project.

---

## 2. Register your app with Firebase

1. In the project overview, click the **Web** icon (</>) to add a web app.
2. App nickname: e.g. **Sanjeevni Web**. Don’t check Firebase Hosting for now. Register app.
3. For **macOS**: install the FlutterFire CLI (step 4) and run `flutterfire configure`; it can add macOS when supported.
4. Copy the `firebaseConfig` object from the snippet (you’ll use it via FlutterFire in step 4).

---

## 3. Enable Auth and create Firestore + Storage

- **Authentication**  
  - Go to **Build → Authentication** → **Get started**  
  - **Sign-in method** → **Email/Password** → Enable → Save  

- **Firestore**  
  - **Build → Firestore Database** → **Create database**  
  - Start in **test mode** for now (or production with rules below) → choose a region  

- **Storage**  
  - **Build → Storage** → **Get started**  
  - Start in **test mode** for now (or production with rules below)  

---

## 4. Generate Flutter config (required)

In your project folder run:

```bash
cd ~/Documents/FlutterDev/Sanjeevni
dart run flutterfire_cli:configure
```

If the CLI isn’t installed:

```bash
dart pub global activate flutterfire_cli
dart run flutterfire_cli:configure
```

- Sign in with Google when asked.
- Select the Firebase project you created.
- Select platforms (e.g. **Web**, **macOS** if available).
- This creates/updates **`lib/firebase_options.dart`** with your project’s keys. **Do not commit this file if it contains secrets and your repo is public.**

Then:

```bash
flutter pub get
flutter run -d chrome
# or
flutter run -d macos
```

---

## 5. Firestore security rules (recommended)

In Firebase Console → **Firestore Database** → **Rules**, use:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /prescriptions/{docId} {
      allow read: if request.auth != null
        && (resource.data.patient_id == request.auth.uid || resource.data.doctor_id == request.auth.uid);
      allow create: if request.auth != null && request.resource.data.doctor_id == request.auth.uid;
      allow delete: if request.auth != null && resource.data.doctor_id == request.auth.uid;
    }
  }
}
```

Publish the rules.

---

## 6. Storage security rules (recommended)

In **Storage** → **Rules**:

```text
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /prescriptions/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Publish the rules.

---

## 7. Firestore indexes (if needed)

When you first load prescriptions, Firestore may show an error in the console with a link to create an index. Open that link and create the index. Or in **Firestore → Indexes** add:

- Collection: **prescriptions**
- Fields: **patient_id** (Ascending), **created_at** (Descending)
- Query scope: Collection

And:

- Collection: **prescriptions**
- Fields: **doctor_id** (Ascending), **created_at** (Descending)
- Query scope: Collection

---

## Quick checklist

| Step | Action |
|------|--------|
| 1 | Create Firebase project |
| 2 | Add Web app (and macOS via FlutterFire if needed) |
| 3 | Enable Email/Password auth, create Firestore and Storage |
| 4 | Run `dart run flutterfire_cli:configure` in the app folder |
| 5 | Deploy Firestore and Storage rules (steps 5–6) |
| 6 | Create composite indexes if Firestore prompts you |

After step 4 you can run the app; sign up and login will use Firebase.
