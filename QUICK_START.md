# 🚀 Quick Start Guide

Get the Kerja Praktik App running in 5 minutes with Flutter!

## Prerequisites

Before starting, ensure you have:
- **Flutter SDK** installed (3.0.0 or higher)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extension
- **Git** (optional)

## Step 1: Install Flutter

### Windows:
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`
4. Restart terminal

### Verify Installation:
```powershell
flutter doctor
```

Fix any issues shown by `flutter doctor` before proceeding.

---

## Step 2: Setup Project

### Navigate to Project Directory:
```powershell
cd e:\ProjectSemoGaWacana
```

### Get Dependencies:
```powershell
flutter pub get
```

This will download all required packages (intl, etc.)

---

## Step 3: Run the App

### Option A: Run on Android Emulator

1. **Open Android Studio** → AVD Manager
2. **Create/Start** an Android emulator
3. **Run the app:**
   ```powershell
   flutter run
   ```

The app will compile and launch on the emulator!

### Option B: Run on Physical Device

1. **Enable Developer Mode** on your Android phone:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Enable "USB Debugging"

2. **Connect** your phone via USB

3. **Run the app:**
   ```powershell
   flutter run
   ```

### Option C: Run on Web (Chrome)

```powershell
flutter run -d chrome
```

### Option D: Run on iOS Simulator (Mac Only)

```powershell
open -a Simulator
flutter run
```

---

## Step 4: Test the App

Once the app loads, you'll see:

1. **Header** with "Kerja Praktik" title (deep blue background)
2. **Statistics cards** showing Total, Active, Completed, and Pending counts
3. **Filter buttons** to filter by status
4. **Sample data** - 3 pre-loaded internship entries
5. **Orange "+ button** at bottom-right

### Try These Actions:

#### ➕ Add New Internship
1. Tap the orange **+** button
2. Fill in required fields (marked with *)
3. Tap **Simpan** to save

#### 👁️ View Details
1. Tap any internship card
2. View full information
3. Tap **X** to close

#### ✅ Update Status
1. Open an internship detail
2. Tap **Aktifkan** (for pending) or **Selesai** (for active)
3. Status will update instantly

#### 🗑️ Delete Entry
1. Open an internship detail
2. Tap **Hapus** button
3. Confirm deletion

#### 🔍 Filter Data
1. Tap filter buttons: **Semua**, **Pending**, **Aktif**, **Selesai**
2. List updates automatically

---

## 🛠️ Common Issues & Solutions

### Issue: Flutter doctor shows issues
```powershell
# Follow the specific instructions shown by flutter doctor
flutter doctor -v
```

### Issue: "Gradle build failed" (Android)
```powershell
flutter clean
flutter pub get
flutter run
```

### Issue: Packages not found
```powershell
flutter pub get
```

### Issue: Hot reload not working
- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Save files to trigger auto-reload

### Issue: App crashes on startup
```powershell
flutter clean
cd android
./gradlew clean
cd ..
flutter run
```

---

## 📂 Project Structure Overview

```
e:\ProjectSemoGaWacana/
├── lib/
│   ├── main.dart                    ← Main app file (START HERE)
│   └── code/                        ← All functions & components
│       ├── theme.dart               ← Colors and design system
│       ├── utils.dart               ← Helper functions
│       ├── internship_service.dart  ← Data management
│       ├── models/
│       │   └── internship.dart      ← Data model
│       └── components/
│           ├── internship_card.dart
│           ├── stat_card.dart
│           └── add_internship_modal.dart
│
├── pubspec.yaml                     ← Dependencies
├── analysis_options.yaml            ← Linter rules
└── need/
    └── KerjaPraktik.xlsx            ← Reference data
```

---

## 🎨 Customization Quick Tips

### Change Primary Color
`lib/code/theme.dart` → Line 19
```dart
static const Color primary = Color(0xFF2C3E50);  // Change this hex code
```

### Add New Status
`lib/code/internship_service.dart` → Add to sample data
```dart
status: 'your-new-status',
```

Then update `lib/code/theme.dart` → StatusColors
```dart
'your-new-status': StatusColorConfig(
  bg: Color(0xFFXXXXXX),
  border: Color(0xFFXXXXXX),
  text: Color(0xFFXXXXXX),
)
```

### Modify Sample Data
`lib/code/internship_service.dart` → Line 10-50

---

## 📖 Next Steps

1. ✅ Read [README.md](README.md) for full documentation
2. 🎨 Check [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for design details
3. 💻 Explore code in `lib/code/` folder
4. 🔧 Customize to your needs
5. 🚀 Build release APK: `flutter build apk --release`

---

## 💡 Pro Tips

1. **Use Hot Reload**: Press `r` to see changes instantly
2. **Use Flutter DevTools**: Run `flutter pub global activate devtools`
3. **Test on Real Device**: More accurate than emulators
4. **Enable Hot Reload**: Save files and see updates without full reload
5. **Use Dart DevTools**: Press `v` in terminal to open DevTools

---

## 🎯 Flutter Commands Cheat Sheet

```powershell
# Run app
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Hot reload
r (in terminal)

# Hot restart
R (in terminal)

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# Build for iOS
flutter build ios --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Check Flutter health
flutter doctor
```

---

## 📞 Need Help?

- Check terminal for error messages
- Run `flutter doctor` to diagnose issues
- Visit Flutter documentation: https://flutter.dev/docs
- Check Dart documentation: https://dart.dev/guides

---

**Happy Coding! 🎉**

Your Flutter app should now be running. Enjoy managing internships with style! ✨


