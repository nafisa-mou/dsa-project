# Setup and Installation Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Firebase Setup](#firebase-setup)
3. [Google Maps Configuration](#google-maps-configuration)
4. [Flutter Project Setup](#flutter-project-setup)
5. [Running Locally](#running-locally)
6. [Deployment](#deployment)

---

## Prerequisites

### System Requirements
- **OS**: Windows, macOS, or Linux
- **Flutter**: 3.0.0 or higher
- **Dart**: Included with Flutter
- **Java**: JDK 11 or higher (for Android)
- **Xcode**: 14.0 or higher (for iOS)

### Accounts Needed
- **Google Account** (for Firebase & Google Maps)
- **GitHub Account** (for version control)
- **Apple Developer Account** (for iOS deployment)
- **Google Play Developer Account** (for Android deployment)

### Tools to Install

#### Flutter SDK
```bash
# Download Flutter
https://flutter.dev/docs/get-started/install

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

#### Android Studio
```bash
# Download and install from https://developer.android.com/studio
# Install Android SDK and emulator
```

#### Xcode (macOS)
```bash
# Install via App Store or:
xcode-select --install

# Accept license
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

---

## Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a new project"
3. Project name: "Smart Bus System"
4. Disable Google Analytics (optional)
5. Click "Create Project"

### Step 2: Register Apps

#### Android App
1. In Firebase Console, click "Android"
2. Package name: `com.smartbus.student` (for student app)
3. App nickname: "Smart Bus Student"
4. SHA-1 certificate fingerprint:
```bash
# Get from keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
5. Click "Register app"
6. Download `google-services.json`
7. Place in `android/app/`

#### iOS App
1. Click "iOS"
2. Bundle ID: `com.smartbus.student`
3. App nickname: "Smart Bus Student"
4. Download `GoogleService-Info.plist`
5. Place in `ios/Runner/`

#### Web App (Admin Dashboard)
1. Click "Web"
2. App nickname: "Smart Bus Admin"
3. Copy config object

### Step 3: Enable Services

In Firebase Console, enable:

#### Authentication
```bash
# In Firebase Console:
1. Go to Authentication
2. Click "Get Started"
3. Enable Email/Password
4. Enable Phone (optional)
```

#### Firestore Database
```bash
1. Go to Firestore Database
2. Click "Create Database"
3. Select "Start in production mode"
4. Choose region (closest to users)
5. Enable Firestore
```

#### Realtime Database
```bash
1. Go to Realtime Database
2. Click "Create Database"
3. Start in test mode (change rules later)
4. Select region
```

#### Storage
```bash
1. Go to Storage
2. Click "Get Started"
3. Start in test mode (change rules later)
```

#### Cloud Messaging
```bash
1. Go to Cloud Messaging
2. Set up Web API Key
```

### Step 4: Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Students can read/write their profile
    match /students/{studentId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // Public read for bus information
    match /buses/{busId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.isAdmin == true;
    }
    
    // Admin only for analytics
    match /analytics/{document=**} {
      allow read, write: if request.auth.token.isAdmin == true;
    }
  }
}
```

### Step 5: Realtime Database Rules

```json
{
  "rules": {
    "buses_live_locations": {
      "$busId": {
        ".read": true,
        ".write": "root.child('buses').child($busId).child('driverId').val() === auth.uid"
      }
    },
    "student_live_locations": {
      "$studentId": {
        ".read": "auth.uid === $studentId",
        ".write": "auth.uid === $studentId"
      }
    },
    "pickup_requests_active": {
      ".read": true,
      ".write": true
    }
  }
}
```

---

## Google Maps Configuration

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project: "Smart Bus System"
3. Enable billing

### Step 2: Enable APIs

Enable the following APIs:
- Maps SDK for Android
- Maps SDK for iOS
- Maps JavaScript API
- Places API
- Directions API
- Distance Matrix API

```bash
# Command line (optional)
gcloud services enable \
  maps-android-backend.googleapis.com \
  maps-ios-backend.googleapis.com \
  maps-backend.googleapis.com \
  places-api.googleapis.com \
  directions-api.googleapis.com \
  distance-matrix-api.googleapis.com
```

### Step 3: Create API Keys

#### Android API Key
1. Go to Credentials
2. Click "Create Credentials" → "API Key"
3. Edit and restrict to:
   - Application type: Android apps
   - Package name: `com.smartbus.student`
   - SHA-1: (from debug.keystore)

#### iOS API Key
1. Create another API Key
2. Restrict to:
   - Application type: iOS apps
   - Bundle IDs: `com.smartbus.student`

#### Web API Key
1. Create another API Key
2. Restrict to:
   - Application type: Web applications
   - HTTP referrers: `localhost:*`, your domain

### Step 4: Configure in Apps

#### Android
Edit `android/app/AndroidManifest.xml`:
```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY"/>
</application>
```

#### iOS
Edit `ios/Runner/Info.plist`:
```xml
<dict>
  <key>GMSApiKey</key>
  <string>YOUR_IOS_API_KEY</string>
</dict>
```

#### Web
Update `admin_dashboard/web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY"></script>
```

---

## Flutter Project Setup

### Step 1: Clone Projects

```bash
# Student App
cd student_app
flutter pub get

# Driver App
cd ../driver_app
flutter pub get

# Admin Dashboard
cd ../admin_dashboard
flutter pub get
```

### Step 2: Configure FlutterFire

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Student App
cd student_app
flutterfire configure --project=smart-bus-system

# Configure Driver App
cd ../driver_app
flutterfire configure --project=smart-bus-system

# Configure Admin Dashboard
cd ../admin_dashboard
flutterfire configure --project=smart-bus-system
```

### Step 3: Create Firebase Config Files

Each app gets a `firebase_options.dart` file automatically.

### Step 4: Update Dependencies

```bash
flutter pub get
flutter pub upgrade
```

---

## Running Locally

### Student App (Mobile)

#### Android
```bash
cd student_app

# Run on emulator
flutter run -d emulator-5554

# Run on physical device
flutter run -d <device_id>
```

#### iOS
```bash
cd student_app

# Run on simulator
flutter run -d simulator

# Run on physical device
flutter run -d <device_id>
```

### Driver App (Mobile)

Same as Student App, just change directory.

### Admin Dashboard (Web)

```bash
cd admin_dashboard

# Run on web
flutter run -d chrome

# Or specify port
flutter run -d web-server --web-port=8080
```

### Enable Location Services

For GPS tracking to work:

**Android:**
1. Go to Settings → Apps → Smart Bus
2. Enable "Location" permission
3. Select "Allow only while using the app" or "Allow all the time"

**iOS:**
1. Go to Settings → Privacy → Location Services
2. Enable "Location Services"
3. Find Smart Bus app and select "While Using"

---

## Deployment

### Android Deployment

#### Step 1: Create Signed APK
```bash
cd student_app

# Build release APK
flutter build apk --release

# Build AAB (recommended)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Step 2: Upload to Play Store
1. Create Google Play Developer account
2. Create new app
3. Upload AAB file
4. Fill in store listing details
5. Submit for review

### iOS Deployment

#### Step 1: Create Certificate
```bash
cd student_app/ios

# Open Xcode
open Runner.xcworkspace
```

In Xcode:
1. Select Runner project
2. Go to Signing & Capabilities
3. Select your team
4. Xcode auto-manages certificates

#### Step 2: Build Archive
```bash
flutter build ios --release
```

#### Step 3: Upload to App Store
1. Open Xcode organizer
2. Distribute App
3. Upload to App Store
4. Wait for review

### Web Deployment

#### Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Build web app
cd admin_dashboard
flutter build web --release

# Deploy
firebase deploy
```

#### Custom Server
```bash
# Build release
flutter build web --release

# Upload build/web to your server
# Configure web server (nginx, Apache, etc.)
```

---

## Troubleshooting

### Common Issues

#### Flutter Command Not Found
```bash
# Add Flutter to PATH
export PATH="$PATH:~/flutter/bin"

# Verify
flutter doctor
```

#### Firebase Connection Error
- Check internet connection
- Verify Firebase credentials
- Check Firestore security rules
- Clear Flutter cache: `flutter clean`

#### Google Maps Not Loading
- Verify API key is correct
- Check API is enabled in Google Cloud Console
- Verify package name/bundle ID matches
- Clear app cache

#### Location Permission Denied
- Check AndroidManifest.xml has permissions
- On iOS, check Info.plist has location keys
- Restart app after granting permission

#### Emulator Issues
```bash
# List devices
flutter devices

# Restart adb
adb kill-server
adb start-server

# Launch emulator
emulator -avd <avd_name>
```

---

## Environment Variables

Create `.env` file in project root:

```env
# Firebase
FIREBASE_PROJECT_ID=smart-bus-system
FIREBASE_API_KEY=YOUR_API_KEY

# Google Maps
GOOGLE_MAPS_API_KEY=YOUR_MAPS_KEY

# App Configuration
APP_VERSION=1.0.0
BUILD_NUMBER=1
```

---

## Next Steps

1. ✅ Setup Firebase Project
2. ✅ Configure Google Maps
3. ✅ Clone and setup Flutter projects
4. ✅ Run locally for testing
5. ⏭️ Read [API.md](API.md) for API documentation
6. ⏭️ Review [ARCHITECTURE.md](ARCHITECTURE.md) for system design
7. ⏭️ Deploy to app stores

---

**Last Updated**: January 2024
