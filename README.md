# 🕌 Quran App - Premium Islamic Mobile Application

An elegant, high-fidelity, and feature-rich Flutter mobile application designed to provide users with an immersive Quran reading and listening experience, daily Azkar, supplications, prayer times, and deep listening analytics. 

Built using a modern **green and gold design language** with standard-setting UI/UX design practices, custom micro-animations, background audio playback, local biometric security, and atomic database tracking.

---

## ✨ Features

### 📖 Quran Explorer (`SurahListScreen`)
* **Elegant Reading Layout:** Features traditional Arabic typography (`Amiri` google font) with readable fonts, translations, and beautiful visual frames.
* **Audio Recitations:** Smooth background audio stream for all Surahs powered by `just_audio` and `just_audio_background`.
* **Sticky Mini-Player:** Accessible floating media controls that persist across screens to play, pause, seek, and manage active recitations.
* **Offline Audio Downloader:** Safe background download service utilizing a robust multi-threaded file system to fetch, cache, and play recitation tracks offline.

### 📿 Daily Azkar & Duas (`AzkarScreen`)
* A collection of authentic supplications and morning/evening remembrances.
* Categorized navigation cards with beautiful transition physics.

### 🕋 Prayer Times Tracker (`PrayerTimesScreen`)
* Displays accurate local Islamic prayer times with premium, dynamic UI cards.
* Clean visual indicators for the current active prayer slot.

### 📊 High-Fidelity Stats & Activity Dashboard (`DashboardScreen`)
* **Daily Activity Bar Chart:** Implemented with `fl_chart`, showcasing a beautiful green/gold gradient representing custom daily listening duration in minutes with responsive touch-tooltips.
* **Monthly Listening Goals:** Round progress tracking badge showing monthly targets vs current progress with a quick target modifier modal.
* **Most Listened Surah & Statistics:** Highlighted brand gradient card with gold star indicators, tracking your exact lifetime listening metrics.
* **Top 5 Listened Surahs:** Ranks your top surahs dynamically sorted by total play counts and listening duration.

### 🛡️ Authentication, Age Verification & Biometric Security
* **Secure Registration & Login:** Backed by Firebase Authentication.
* **COPPA-Compliant Age Verification:** Rigidly prevents registrations under **13 years old** using a highly polished birthday date-picker with automatic age calculations.
* **Local Biometrics (Fingerprint/Face ID):** Instant secure sign-in option using `local_auth` that securely stores credentials locally using cryptographic encryption via `flutter_secure_storage`.

---

## 🎨 Theme & Typography

The application strictly implements a premium design system tailored around soft colors and elegant branding:
* **Primary Green:** `#0F9D58` (Vibrant and modern Islamic Green)
* **Accent Gold:** `#D4AF37` (Soft and regal Gold)
* **Typography:** `Poppins` for clean English interfaces and `Amiri` for professional, authentic Quranic script rendering.
* **Micro-Animations:** Fluid, staggered list/grid entrance animations (`flutter_staggered_animations`) and custom `AnimatedSwitcher` navigation routes.

---

## 🛠️ Tech Stack & Dependencies

* **SDK:** Flutter `^3.11.0` (Dart 3 compatibility)
* **State Management:** `provider` (Multi-provider architecture pattern)
* **Database & Auth:** Firebase Core, Firebase Auth, Cloud Firestore (atomic batch transactions)
* **Local Storage:** `flutter_secure_storage` (Keychain/Keystore encryption), `shared_preferences` (settings cache)
* **Graphics & Charts:** `fl_chart` for dynamic vector graphics and dashboard charts
* **Multimedia:** `just_audio` (advanced music player engine) & `just_audio_background` (OS integration)

---

## 📂 Project Structure

```text
lib/
├── core/
│   └── theme.dart                 # Color palette (AppColors) & Typography (AppTheme)
├── features/
│   ├── auth/                      # Firebase auth wrappers, Login, Biometrics & Age-Limit validation
│   ├── azkar/                     # Supplications & Remembrance list screens
│   ├── dashboard/                 # Analytics dashboard, goal setting, and fl_chart widgets
│   ├── duas/                      # Category-based supplications and references
│   ├── library/                   # User bookmarks and downloaded surah items
│   ├── player/                    # Sticky mini-player controls and full player modal UI
│   ├── prayer/                    # Islamic prayer schedule widgets
│   ├── profile/                   # User metadata and app settings
│   └── quran/                     # Surah list display, verse navigation, and search engine
├── models/                        # Typed models for user stats, Surahs, and bookmarks
└── services/
    ├── audio_service.dart         # Audio engine control, persistent background play, Firestore syncing
    ├── auth_service.dart          # Firebase Email & Password authentication
    ├── biometric_service.dart     # Fingerprint & Face ID local_auth implementation
    ├── download_service.dart      # HTTP multi-threaded file downloader & local caching
    ├── firestore_service.dart     # Single atomic stats transaction updates and stats stream
    ├── quran_api_service.dart     # Rest APIs to fetch Quran text and metadata
    ├── secure_storage_service.dart# Encrypted local credential keychain
    └── storage_service.dart       # Preferences and local key-value store
```

---

## ⚙️ Getting Started

### 📋 Prerequisites
* Flutter SDK (`^3.11.0` or higher) installed.
* CocoaPods (for iOS/macOS builds).
* Android Studio / Xcode configured with emulator.

### 🔑 Environment Configuration
1. Duplicate `.env.example` in the project root and rename it to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Fill in your Firebase configuration keys for Android, iOS, and Web:
   ```ini
   ANDROID_API_KEY=your_android_api_key
   ANDROID_APP_ID=your_android_app_id
   IOS_API_KEY=your_ios_api_key
   IOS_APP_ID=your_ios_app_id
   PROJECT_ID=your_firebase_project_id
   STORAGE_BUCKET=your_firebase_storage_bucket
   ```

### 🚀 Running the App
1. **Get dependencies:**
   ```bash
   flutter pub get
   ```
2. **Run Linter / Code Analyzer:**
   ```bash
   flutter analyze
   ```
3. **Launch the Application:**
   ```bash
   flutter run
   ```

---

## 🐳 Docker Deployment (Web)

This application supports compilation and serving over the Web using a multi-stage Docker build served via a high-performance **Nginx** server.

For a detailed setup guide, please refer to the [Docker Setup & Usage Guide](file:///c:/Users/Probook/Desktop/Coding/Android_dev/projetMobDev/DOCKER.md).

Quick start command:
```bash
# Build the Docker image
docker build -t quran_app_web .

# Start the Nginx container on port 8080
docker run -d -p 8080:80 --name quran_app_web_container quran_app_web
```
Access the web app at: 👉 **http://localhost:8080**
