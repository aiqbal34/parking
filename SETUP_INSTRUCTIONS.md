# Parking App Setup Instructions

This document provides comprehensive setup instructions for the Parking App, including both the iOS app and the FastAPI backend with Firebase integration.

## Project Overview

The Parking App is a comprehensive parking spot booking application with the following features:

### iOS App Features
- **Finder Mode**: Browse and request to book parking spots
- **Renter Mode**: List and manage your parking spots
- **Booking Requests**: Request-based booking system (no instant booking)
- **Real-time Updates**: Live booking status updates
- **Location Services**: Find nearby parking spots
- **User Profiles**: Manage your account and preferences

### Backend Features
- **FastAPI Backend**: Modern, fast REST API
- **Firebase Integration**: Authentication and Firestore database
- **Booking Workflow**: Request → Approval → Confirmation system
- **User Management**: Complete user profile system
- **Real-time Data**: Live updates across all clients

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS App       │    │   FastAPI       │    │   Firebase      │
│   (SwiftUI)     │◄──►│   Backend       │◄──►│   (Auth + DB)   │
│                 │    │   (Python)      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

### For iOS Development
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS 14.0 or later
- Apple Developer Account (for device testing)

### For Backend Development
- Python 3.8 or higher
- Firebase project with Authentication and Firestore enabled
- Firebase service account key

## Setup Instructions

### 1. Firebase Project Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Create a project"
   - Enter project name (e.g., "parking-app")
   - Follow the setup wizard

2. **Enable Authentication**
   - In Firebase Console, go to "Authentication"
   - Click "Get started"
   - Enable Email/Password authentication
   - Add your app (iOS) to the project

3. **Enable Firestore Database**
   - Go to "Firestore Database"
   - Click "Create database"
   - Choose "Start in test mode" for development
   - Select a location close to your users

4. **Generate Service Account Key**
   - Go to Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save the JSON file as `firebase-service-account.json`

### 2. iOS App Setup

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd parking
   ```

2. **Open in Xcode**
   ```bash
   open parking.xcodeproj
   ```

3. **Configure Firebase for iOS**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add it to your Xcode project
   - Make sure it's included in your target

4. **Install Dependencies**
   - The project uses Swift Package Manager
   - Dependencies will be automatically resolved in Xcode

5. **Build and Run**
   - Select your target device/simulator
   - Press Cmd+R to build and run

### 3. Backend Setup

1. **Navigate to Backend Directory**
   ```bash
   cd backend
   ```

2. **Create Virtual Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Firebase**
   - Place `firebase-service-account.json` in the backend directory
   - Or set the environment variable:
     ```bash
     export FIREBASE_SERVICE_ACCOUNT_KEY='{"your":"service_account_json"}'
     ```

5. **Run the Backend**
   ```bash
   python main.py
   ```
   
   Or with uvicorn:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Verify Backend**
   - API: http://localhost:8000
   - Documentation: http://localhost:8000/docs
   - Health check: http://localhost:8000/health

### 4. Backend Deployment to Vercel

1. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Login to Vercel**
   ```bash
   vercel login
   ```

3. **Set Environment Variables**
   ```bash
   vercel env add FIREBASE_SERVICE_ACCOUNT_KEY
   ```

4. **Deploy**
   ```bash
   cd backend
   vercel --prod
   ```

5. **Update iOS App**
   - Update the API base URL in your iOS app to point to your Vercel deployment

## Key Features Implementation

### Booking Request System

The app now uses a request-based booking system instead of instant booking:

1. **User sends booking request** with:
   - Start and end times
   - Optional message to owner
   - Total price calculation

2. **Owner receives notification** and can:
   - Approve the request (with optional message)
   - Reject the request (with optional reason)

3. **User gets notified** of the decision and can:
   - Confirm approved bookings
   - Cancel pending requests

### User Interface Updates

- **SpotDetailView**: Now shows "Send Booking Request" instead of instant booking
- **BookingRequestSheet**: New sheet for composing booking requests
- **RenterView**: Added "Requests" tab for managing pending requests
- **BookingRequestDetailView**: Detailed view for reviewing requests

### Backend API Endpoints

The backend provides comprehensive API endpoints:

- **Authentication**: Register, login, profile management
- **Parking Spots**: CRUD operations, search, nearby spots
- **Bookings**: Request creation, approval/rejection, status management

## Testing the Application

### 1. Test User Registration
- Open the iOS app
- Register a new account
- Verify user appears in Firebase Authentication

### 2. Test Parking Spot Creation
- Switch to Renter mode
- Add a new parking spot
- Verify spot appears in Firestore

### 3. Test Booking Request Flow
- Switch to Finder mode
- Browse available spots
- Send a booking request
- Switch to Renter mode to approve/reject
- Verify status updates in Finder mode

### 4. Test Backend API
- Use the Swagger UI at `/docs`
- Test authentication endpoints
- Test parking spot and booking endpoints

## Troubleshooting

### Common Issues

1. **Firebase Configuration**
   - Ensure `GoogleService-Info.plist` is properly added to Xcode project
   - Verify Firebase project settings match your app bundle ID

2. **Backend Connection**
   - Check if backend is running on correct port
   - Verify CORS settings allow iOS app requests
   - Check Firebase service account key configuration

3. **Authentication Issues**
   - Ensure Firebase Authentication is enabled
   - Verify user registration flow
   - Check token validation in backend

4. **Data Synchronization**
   - Verify Firestore rules allow read/write operations
   - Check network connectivity
   - Review error logs in Xcode console

### Debug Mode

Enable debug logging in the iOS app:
```swift
// In your ViewModel or Service classes
print("Debug: \(message)")
```

For backend debugging:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## Next Steps

### Potential Enhancements

1. **Push Notifications**
   - Implement Firebase Cloud Messaging
   - Notify users of booking status changes

2. **Payment Integration**
   - Add Stripe or PayPal integration
   - Handle payment processing for bookings

3. **Real-time Chat**
   - Add messaging between finders and renters
   - Implement chat functionality

4. **Advanced Search**
   - Add more filtering options
   - Implement price range and availability filters

5. **Reviews and Ratings**
   - Add review system for parking spots
   - Implement user rating system

### Production Considerations

1. **Security**
   - Implement proper Firestore security rules
   - Add input validation and sanitization
   - Enable Firebase App Check

2. **Performance**
   - Implement caching strategies
   - Optimize database queries
   - Add pagination for large datasets

3. **Monitoring**
   - Set up Firebase Analytics
   - Implement error tracking
   - Add performance monitoring

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Firebase documentation
3. Check FastAPI and SwiftUI documentation
4. Create an issue in the project repository

## License

This project is licensed under the MIT License.