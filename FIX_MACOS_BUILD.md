# Fix: iOS/macOS Build Failed (CodeSign / resource fork)

Error: **resource fork, Finder information, or similar detritus not allowed**  
Cause: Extended attributes on frameworks (e.g. **Flutter.framework** or **App.framework**) make code signing reject the app.

**Do not run** `xattr -cr .` on the whole project — it hits `ios/Pods` and `.git` and can give "Permission denied". Use the steps below instead.

---

## Fix for iPhone / iOS device (run in Terminal)

**Step 1 – Clean project build**
```bash
cd ~/Documents/FlutterDev/Sanjeevni
rm -rf build/ios
flutter clean
flutter pub get
```

**Step 2 – Strip extended attributes from Flutter cache and project**

Strip Flutter’s cache (engine/frameworks) and your project’s `build` and `lib` (so **App.framework** is created in a clean tree). Use your real Flutter SDK path:

```bash
# Flutter cache (use your path; use sudo if you get Permission denied)
xattr -cr /Users/raghavendrasingh/Documents/FlutterDev/sdk/flutter/bin/cache

# Project build + lib (avoid Pods and .git)
cd ~/Documents/FlutterDev/Sanjeevni
xattr -cr build 2>/dev/null || true
xattr -cr lib  2>/dev/null || true
```

If Flutter cache says **Permission denied**:
```bash
sudo xattr -cr /Users/raghavendrasingh/Documents/FlutterDev/sdk/flutter/bin/cache
```

**Step 3 – Run again**
```bash
cd ~/Documents/FlutterDev/Sanjeevni
flutter run
```
Then select your iPhone when prompted.

---

## Fix for macOS desktop (run in Terminal)

Same idea as iOS: clean build and strip Flutter cache (no `xattr -cr .` on the project).

```bash
cd ~/Documents/FlutterDev/Sanjeevni
rm -rf build/macos
xattr -cr /Users/raghavendrasingh/Documents/FlutterDev/sdk/flutter/bin/cache
# if permission denied: sudo xattr -cr .../flutter/bin/cache
flutter clean
flutter pub get
flutter run -d macos
```

---

## If it still fails

**Option A – Strip everything that’s safe (Flutter cache + project build/lib), then run**
```bash
sudo xattr -cr /Users/raghavendrasingh/Documents/FlutterDev/sdk/flutter/bin/cache
cd ~/Documents/FlutterDev/Sanjeevni
rm -rf build/ios
xattr -cr build lib 2>/dev/null || true
flutter clean && flutter pub get && flutter run
```

**Option A2 – If the error is on App.framework:** right after the failed build, strip `build/ios` and run again (no full clean):
```bash
cd ~/Documents/FlutterDev/Sanjeevni
xattr -cr build/ios
flutter run
```

**Option B – Run on Chrome instead of macOS**
```bash
flutter run -d chrome
```

**Option C – Disable code signing for local debug (temporary)**  
- Open `macos/Runner.xcodeproj` in Xcode  
- Select **Runner** → **Signing & Capabilities**  
- Uncheck **Automatically manage signing** (or use a development team only for real devices)  
- For “Run” scheme, confirm the build is Debug; code signing is often more relaxed

---

The failure is code signing: **Flutter.framework** or **App.framework** has extended attributes. Strip Flutter’s `bin/cache` and the project’s `build` (and `lib`) without touching Pods or .git. If the error points at **App.framework**, also run `xattr -cr build/ios` and try `flutter run` again.
