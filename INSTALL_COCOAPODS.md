# Fix CocoaPods for Flutter (iOS/macOS)

CocoaPods is required for Flutter plugins on iOS and macOS. Run **one** of the options below in your **regular Terminal** (not inside Cursor’s restricted environment).

---

## ⚠️ "ffi requires Ruby version >= 3.0" (macOS system Ruby 2.6)

macOS system Ruby is 2.6; current CocoaPods needs Ruby 3+. Use **one** of these:

### A) Install CocoaPods with older ffi (try first)

Install an ffi version that supports Ruby 2.6, then CocoaPods:

```bash
sudo gem install ffi -v 1.14.2
sudo gem install cocoapods -v 1.10.2
```

If that still tries to upgrade ffi and fails, use **B**.

### B) Install Homebrew, then CocoaPods (recommended)

Homebrew installs its own Ruby/CocoaPods and avoids system Ruby:

1. **Install Homebrew** (one-time):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   When it finishes, it will show two lines to run (e.g. for Apple Silicon) to add Homebrew to PATH. Run those, then close and reopen Terminal.

2. **Install CocoaPods**:
   ```bash
   brew install cocoapods
   ```

3. **Verify**:
   ```bash
   pod --version
   flutter doctor
   ```

---

## Option 1: Homebrew (recommended)

If you have Homebrew:

```bash
brew install cocoapods
```

Then run:

```bash
flutter doctor
```

---

## Option 2: Ruby gem (built-in on macOS)

In Terminal, run:

```bash
sudo gem install cocoapods
```

Enter your Mac password when asked. Then:

```bash
flutter doctor
```

---

## Option 3: Gem without sudo (user install)

If you prefer not to use `sudo`:

```bash
gem install cocoapods --user-install
```

Then add the gem bin path to your shell. For **zsh**, add this line to `~/.zshrc`:

```bash
export PATH="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION')/bin:$PATH"
```

Reload your shell and check:

```bash
source ~/.zshrc
which pod
flutter doctor
```

---

## After installing CocoaPods

1. Run: `flutter doctor`
2. In your project, run: `cd ios && pod install && cd ..` if you see CocoaPods or iOS plugin issues.
3. Run the app: `flutter run` (or choose an iOS device/simulator).

---

## “Unable to get list of installed Simulator runtimes”

That often means Xcode or simulators aren’t fully set up. After CocoaPods is installed, try:

1. Open **Xcode** once and accept the license if prompted.
2. Install a simulator: **Xcode → Settings → Platforms** → add an iOS simulator.
3. Run: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
4. Run: `flutter doctor` again.
