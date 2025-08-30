# Firebase Setup Guide for iOS App

This guide will walk you through setting up Firebase for the Parking App iOS application.

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Firebase account (free tier is sufficient)
- Apple Developer Account (for device testing)

## Step 1: Create Firebase Project

1. **Go to Firebase Console**
   - Visit [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Sign in with your Google account

2. **Create New Project**
   - Click "Create a project"
   - Enter project name: `Parking App` (or your preferred name)
   - Choose whether to enable Google Analytics (optional)
   - Click "Create project"

3. **Project Setup**
   - Wait for project creation to complete
   - Click "Continue" to proceed

## Step 2: Add iOS App to Firebase

1. **Add iOS App**
   - In the Firebase console, click the iOS icon (🍎)
   - Enter your app's bundle identifier: `com.yourcompany.parking`
   - Enter app nickname: `Parking App`
   - Click "Register app"

2. **Download Configuration File**
   - Download the `GoogleService-Info.plist` file
   - **Important**: Keep this file secure and don't commit it to public repositories

3. **Add to Xcode Project**
   - Drag the `GoogleService-Info.plist` file into your Xcode project
   - Make sure it's added to your main app target
   - Verify it appears in the project navigator

## Step 3: Enable Firebase Services

### Authentication

1. **Enable Authentication**
   - In Firebase console, go to "Authentication" → "Get started"
   - Click "Sign-in method" tab
   - Enable "Email/Password" authentication
   - Click "Save"

2. **Optional: Enable Additional Providers**
   - You can also enable Google Sign-In, Apple Sign-In, etc.
   - For now, Email/Password is sufficient

### Firestore Database

1. **Create Firestore Database**
   - Go to "Firestore Database" → "Create database"
   - Choose "Start in test mode" (for development)
   - Select a location close to your users
   - Click "Done"

2. **Security Rules** (for production)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can read/write their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Anyone can read parking spots
       match /parking_spots/{spotId} {
         allow read: if true;
         allow write: if request.auth != null && 
           request.auth.uid == resource.data.owner_id;
       }
       
       // Users can read/write their own bookings
       match /bookings/{bookingId} {
         allow read, write: if request.auth != null && 
           (request.auth.uid == resource.data.finder_id || 
            request.auth.uid == resource.data.owner_id);
       }
     }
   }
   ```

## Step 4: Install Firebase SDK

### Using Swift Package Manager (Recommended)

1. **Add Firebase Dependencies**
   - In Xcode, go to File → Add Package Dependencies
   - Enter URL: `https://github.com/firebase/firebase-ios-sdk`
   - Select the following products:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseCore

2. **Add to Target**
   - Select your app target
   - Click "Add Package"

### Alternative: Using CocoaPods

If you prefer CocoaPods, add to your `Podfile`:
```ruby
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'Firebase/Core'
```

Then run:
```bash
pod install
```

## Step 5: Configure iOS App

### Update Bundle Identifier

1. **Set Bundle ID**
   - In Xcode, select your project
   - Go to "Signing & Capabilities"
   - Update Bundle Identifier to match what you entered in Firebase

### Add Location Permissions

1. **Add to Info.plist**
   - Open `Info.plist`
   - Add the following keys:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs location access to show nearby parking spots and auto-fill your address.</string>
   
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>This app needs location access to show nearby parking spots and auto-fill your address.</string>
   ```

### Update API Base URL

1. **Configure Backend URL**
   - Open `FirebaseService.swift`
   - Update the `baseURL` property:
   ```swift
   private let baseURL = "https://your-vercel-app.vercel.app/api" // Your deployed backend URL
   ```

## Step 6: Test Firebase Integration

### Test Authentication

1. **Build and Run**
   - Select your target device/simulator
   - Press Cmd+R to build and run

2. **Test Sign Up**
   - Tap "Sign Up" in the app
   - Enter test credentials
   - Verify user appears in Firebase Authentication

3. **Test Sign In**
   - Sign out and sign back in
   - Verify authentication works

### Test Firestore

1. **Create Test Data**
   - Add a parking spot in the app
   - Check Firebase console → Firestore Database
   - Verify data appears in the database

2. **Test Real-time Updates**
   - Make changes in the app
   - Verify changes appear in Firebase console

## Step 7: Production Setup

### Security Rules

1. **Update Firestore Rules**
   - Go to Firestore Database → Rules
   - Replace test mode rules with production rules (see Step 3)

2. **Enable App Check** (Optional)
   - Go to Project Settings → App Check
   - Enable App Check for additional security

### Environment Configuration

1. **Separate Development/Production**
   - Create separate Firebase projects for dev/prod
   - Use different `GoogleService-Info.plist` files
   - Update bundle identifiers accordingly

## Troubleshooting

### Common Issues

1. **"Firebase not configured" error**
   - Ensure `GoogleService-Info.plist` is added to the project
   - Verify it's included in the app target
   - Check that `FirebaseApp.configure()` is called in `parkingApp.swift`

2. **Authentication errors**
   - Verify Email/Password authentication is enabled in Firebase
   - Check that users are being created in Firebase console
   - Ensure proper error handling in the app

3. **Firestore permission errors**
   - Check Firestore security rules
   - Verify user authentication state
   - Test with different user accounts

4. **Network errors**
   - Check internet connectivity
   - Verify API base URL is correct
   - Test backend deployment

### Debug Mode

Enable debug logging:
```swift
// In FirebaseService.swift
import FirebaseCore

// Add to init() method
#if DEBUG
FirebaseConfiguration.shared.setLoggerLevel(.debug)
#endif
```

### App Check Warning (Development)

If you see this warning in the console:
```
Error getting App Check token; using placeholder token instead. Error: Error Domain=com.google.app_check_core Code=4 "The attestation provider DeviceCheckProvider is not supported on current platform and OS version."
```

This is normal for development and can be safely ignored. The warning occurs because:
- DeviceCheck is not supported in the iOS Simulator
- App Check is disabled in development mode to avoid this warning
- For production, App Check can be enabled by uncommenting the code in `parkingApp.swift`

To enable App Check for production:
1. Uncomment the App Check code in `parkingApp.swift`
2. Add your debug token to `Info.plist`:
   ```xml
   <key>FirebaseAppCheckDebugToken</key>
   <string>your-debug-token-here</string>
   ```
3. Get the debug token from Firebase Console → App Check → Get debug token

## Next Steps

### Advanced Features

1. **Push Notifications**
   - Enable Firebase Cloud Messaging
   - Add notification capabilities to your app

2. **Analytics**
   - Enable Firebase Analytics
   - Track user behavior and app performance

3. **Crashlytics**
   - Add Firebase Crashlytics
   - Monitor app crashes and errors

### Security Best Practices

1. **Secure API Keys**
   - Never commit `GoogleService-Info.plist` to public repositories
   - Use environment variables for sensitive data
   - Implement proper authentication flows

2. **Data Validation**
   - Validate all user inputs
   - Implement proper error handling
   - Use Firestore security rules

## Support

If you encounter issues:

1. Check Firebase documentation: [https://firebase.google.com/docs](https://firebase.google.com/docs)
2. Review Firebase console for error messages
3. Check Xcode console for debugging information
4. Verify all configuration steps are completed

## Additional Resources

- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
- [Firebase Authentication Guide](https://firebase.google.com/docs/auth/ios/start)
- [Firestore iOS Guide](https://firebase.google.com/docs/firestore/quickstart)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
