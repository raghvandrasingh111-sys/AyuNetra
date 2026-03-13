# Flutter PATH Setup Guide

## Quick Setup

### Option 1: Install Flutter via Homebrew (Recommended for macOS)

```bash
brew install --cask flutter
```

After installation, Flutter should already be in your PATH. Verify with:
```bash
flutter doctor
```

### Option 2: Manual Installation

1. **Download Flutter:**
   ```bash
   cd ~
   git clone https://github.com/flutter/flutter.git -b stable
   ```

2. **Add Flutter to PATH:**
   
   I've created a `.zshrc` file in your home directory. Now you need to:
   
   a. Open `~/.zshrc` in a text editor
   
   b. Uncomment the line that matches where you installed Flutter:
   ```bash
   export PATH="$PATH:$HOME/flutter/bin"
   ```
   
   c. Save the file and reload your shell:
   ```bash
   source ~/.zshrc
   ```

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```

## Current Setup

Your `.zshrc` file has been created with Flutter PATH configuration. 

**To complete the setup:**

1. **Install Flutter** (choose one method above)

2. **Edit `~/.zshrc`** and uncomment the appropriate Flutter PATH line

3. **Reload your shell:**
   ```bash
   source ~/.zshrc
   ```

4. **Verify it works:**
   ```bash
   flutter --version
   flutter doctor
   ```

## Troubleshooting

### Flutter command not found after setup

1. Make sure you've uncommented the correct PATH line in `~/.zshrc`
2. Reload your shell: `source ~/.zshrc`
3. Check if Flutter exists: `ls ~/flutter/bin/flutter` (adjust path as needed)
4. Verify PATH: `echo $PATH | grep flutter`

### Multiple Terminal Windows

After editing `.zshrc`, you need to either:
- Close and reopen your terminal, OR
- Run `source ~/.zshrc` in each terminal window

### Check Current Flutter Location

If Flutter is already installed somewhere, find it:
```bash
find ~ -name "flutter" -type f 2>/dev/null | grep bin/flutter
```

Then update the PATH in `~/.zshrc` to match that location.

## Next Steps

Once Flutter is set up:

1. Run `flutter doctor` to check for any missing dependencies
2. Install any missing tools (Xcode, Android Studio, etc.)
3. Navigate to your project: `cd ~/Documents/FlutterDev/Sanjeevni`
4. Run: `flutter pub get`
5. Run: `flutter run`
