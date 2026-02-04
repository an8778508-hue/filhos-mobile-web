# Escola - Flutter Mobile App

A Flutter mobile application for school management with two distinct flavors: **Parents** and **Professors**.

## Prerequisites

Before setting up the project, ensure you have the following installed:

- **Git** - Version control
- **Flutter SDK** - Version **3.29.3** (managed via FVM)
- **Dart SDK** - Version >= 3.0.5 < 4.0.0 (included with Flutter)
- **Java JDK** - Version 11
- **Android Studio** - Latest version with:
  - Android SDK (API 36)
  - Android SDK Build-Tools
  - Android Emulator
- **Xcode** (macOS only) - Version 14+ for iOS development
- **CocoaPods** (macOS only) - For iOS dependency management

## Quick Start

### 1. Install FVM (Flutter Version Manager)

FVM ensures everyone on the team uses the same Flutter version.

```bash
# Install FVM using Dart
dart pub global activate fvm

# Or using Homebrew (macOS)
brew tap leoafarias/fvm
brew install fvm
```

### 2. Install the Required Flutter Version

```bash
# Install Flutter 3.29.3 (as specified in .fvmrc)
fvm install 3.29.3

# Use it for this project
fvm use 3.29.3
```

### 3. Setup the Project

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd filhos-mobile

# Quick setup using Makefile (recommended)
make setup

# Or manually:
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs

# iOS only - Install pods
cd ios && pod install && cd ..
```

### 4. Run the App

```bash
# Run Parents app
fvm flutter run -t lib/main.dart --flavor parents

# Run Professors app
fvm flutter run -t lib/main_professores.dart --flavor professores
```

## Project Structure

```
filhos-mobile/
├── lib/
│   ├── main.dart                 # Parents app entry point
│   ├── main_professores.dart     # Professors app entry point
│   ├── core/                     # Core utilities and shared code
│   │   ├── components/           # Reusable UI components
│   │   ├── config/               # App configuration
│   │   ├── dependency_injection/ # GetIt DI setup
│   │   ├── errors/               # Error handling
│   │   ├── local_db/             # Hive local database
│   │   ├── localization/         # Multi-language support (en, ar, pt)
│   │   ├── models/               # Shared data models
│   │   ├── network/              # Dio HTTP client
│   │   ├── notifications_service/# Push & local notifications
│   │   ├── theme/                # App theming
│   │   ├── user/                 # User authentication BLoC
│   │   └── utils/                # Utility functions
│   ├── features/                 # Feature modules
│   │   ├── login/
│   │   ├── register/
│   │   ├── home/
│   │   ├── diary/
│   │   ├── gallery/
│   │   ├── chat/
│   │   └── ...                   # Other features
│   └── shared/
│       └── assets/               # Generated asset constants
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
├── assets/                       # App resources
│   ├── icons/
│   ├── images/
│   ├── fonts/
│   ├── langs/                    # Localization files
│   └── sounds/
├── pubspec.yaml                  # Flutter dependencies
├── .fvmrc                        # FVM Flutter version config
└── firebase.json                 # Firebase configuration
```

## App Flavors

This project uses Flutter flavors to build two separate apps from the same codebase:

| Flavor | Package Name | Entry Point | Description |
|--------|--------------|-------------|-------------|
| `parents` | com.algoriza.disneyNew | `lib/main.dart` | App for parents |
| `professores` | com.algoriza.profedisneyNew | `lib/main_professores.dart` | App for teachers |

## Development Commands

### Running the App

```bash
# Parents flavor (Debug)
fvm flutter run -t lib/main.dart --flavor parents

# Professors flavor (Debug)
fvm flutter run -t lib/main_professores.dart --flavor professores
```

### Building the App

```bash
# Build Parents APK (Debug)
fvm flutter build apk -t lib/main.dart --flavor parents --debug

# Build Professors APK (Debug)
fvm flutter build apk -t lib/main_professores.dart --flavor professores --debug
```

For release builds, add `--release --no-tree-shake-icons` flags:
```bash
fvm flutter build apk -t lib/main.dart --flavor parents --release --no-tree-shake-icons
```

Or use the Makefile:
```bash
make build-parents-apk
make build-professors-apk
```

### Code Generation

```bash
# Generate assets and other code (main project)
fvm dart run build_runner build --delete-conflicting-outputs

# Generate code for alarm package (required - run BOTH commands)
cd lib/alarm_package/alarm-5.1.3
fvm dart pub get
fvm dart run pigeon --input pigeons/alarm_api.dart
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart format .
cd ../../..

# Watch mode (auto-regenerate on changes)
fvm dart run build_runner watch --delete-conflicting-outputs
```

**Important:** The alarm package requires **pigeon** to generate platform bindings (`platform_bindings.g.dart`) and **build_runner** for JSON serialization (`notification_settings.g.dart`).

### Regenerate App Icons and Splash Screens

After updating logo or splash assets, regenerate them:

```bash
# Generate app icons for both flavors
fvm dart run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml
fvm dart run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml

# Generate splash screens for both flavors
fvm dart run flutter_native_splash:create --flavor parents
fvm dart run flutter_native_splash:create --flavor professores
```

### AABAR Logo Assets Guide

To rebrand the app with the AABAR logo, generate the following assets from the source logo:

#### App Icons (in `assets/app_icon/`)

| File | Size | Description | How to Generate |
|------|------|-------------|-----------------|
| `app_icon_parents.png` | 1024x1024 px | **Fallback icon (pubspec.yaml)** | Same as parents launcher icon - **don't skip this one!** |
| `app_icon_parents2A.png` | 1024x1024 px | Parents app launcher icon | Square PNG with AABAR logo centered, transparent or solid background |
| `app_icon_parents2.png` | 1024x1024 px | Parents adaptive icon foreground | Same as above, used for Android adaptive icons |
| `app_icon_professors2A.png` | 1024x1024 px | Professors app launcher icon | Same logo, can add subtle color variation to distinguish |
| `app_icon_professors2.png` | 1024x1024 px | Professors adaptive icon foreground | Same as above |

#### Splash Screen Assets (in `assets/app_icon/`)

| File | Size | Description | How to Generate |
|------|------|-------------|-----------------|
| `native_splash_icon.png` | 512x512 px | Logo shown during app launch | AABAR logo on transparent background |
| `native_splash_background.png` | Any size | Splash screen background | Solid color image (#F5F7FA or white recommended) |

#### In-App Logos (in `assets/icons/`)

| File | Format | Description | How to Generate |
|------|--------|-------------|-----------------|
| `default_logo.svg` | SVG | Default logo used throughout the app | Convert AABAR logo to SVG format |
| `default_horizontal_logo.svg` | SVG | Horizontal layout version | Create horizontal variant of logo |
| `filhos_logo.svg` | SVG | Main brand logo | AABAR logo in SVG format |
| `filhos_logo_white.svg` | SVG | White version for dark backgrounds | AABAR logo with white fill |

#### In-App Logos (in `assets/images/`)

| File | Format | Description | How to Generate |
|------|--------|-------------|-----------------|
| `filhos_logo.png` | PNG | Main brand logo (raster) | AABAR logo, 512x512 px recommended |

#### Brand Colors (AABAR)

Use these colors when creating logo variants:
- **Primary Navy Blue:** `#1E3A5F`
- **Accent Orange:** `#E87722`
- **Light Background:** `#F5F7FA`

#### Quick Steps to Rebrand

1. Create all PNG assets from the AABAR logo using an image editor (Figma, Photoshop, GIMP)
2. Create SVG versions using a vector editor (Figma, Illustrator, Inkscape)
3. Replace all files listed above in their respective folders
4. Run the regeneration commands above to generate platform-specific icons

### Maintenance Commands

```bash
# Clean build artifacts
fvm flutter clean

# Get dependencies
fvm flutter pub get

# Upgrade dependencies
fvm flutter pub upgrade

# Check for outdated packages
fvm flutter pub outdated

# Run analyzer
fvm flutter analyze
```

## IDE Setup

### VS Code

1. Install the **Flutter** and **Dart** extensions
2. Open the project folder
3. Use the pre-configured launch configurations in `.vscode/launch.json`:
   - **Flutter parents** - Runs the parents app
   - **Flutter Professores** - Runs the professors app

### Android Studio

1. Install the **Flutter** and **Dart** plugins
2. Open the project
3. Create Run Configurations:
   - **Parents**: Entry point `lib/main.dart`, Additional arguments: `--flavor parents`
   - **Professors**: Entry point `lib/main_professores.dart`, Additional arguments: `--flavor professores`

## Firebase Configuration

The project uses Firebase for:
- Authentication
- Cloud Firestore
- Cloud Messaging (Push Notifications)
- Cloud Storage
- Crashlytics
- App Check

Firebase configuration is in `lib/firebase_options.dart`.

## Localization

The app supports multiple languages:
- English (en)
- Arabic (ar)
- Portuguese (pt)

Localization files are in `assets/langs/`.

## Troubleshooting

### Common Issues

**Flutter version mismatch:**
```bash
fvm use 3.29.3
fvm flutter pub get
```

**Build runner fails:**
```bash
fvm flutter clean
rm -rf .dart_tool
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

**Alarm package "platform_bindings.g.dart" not found:**
```bash
cd lib/alarm_package/alarm-5.1.3
fvm dart pub get
fvm dart run pigeon --input pigeons/alarm_api.dart
fvm dart run build_runner build --delete-conflicting-outputs
cd ../../..
```

**iOS build fails:**
```bash
cd ios
pod deintegrate
pod install
cd ..
fvm flutter clean
fvm flutter pub get
```

**Android build fails:**
```bash
cd android
./gradlew clean
cd ..
fvm flutter clean
fvm flutter pub get
```

## Environment Requirements Summary

| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.29.3 |
| Dart SDK | >= 3.0.5 < 4.0.0 |
| Java JDK | 11 |
| Android SDK | API 36 (min 23) |
| iOS | 13.0+ |
| Kotlin | 2.1.21 |

## License

Private project - All rights reserved.
