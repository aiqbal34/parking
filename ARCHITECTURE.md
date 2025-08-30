# Parking App - System Architecture

## Overview

The Parking App is a comprehensive parking spot booking application built with a modern, scalable architecture. The system consists of an iOS client application, a FastAPI backend service, and Firebase infrastructure for authentication and real-time data management.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   iOS App       │  │   SwiftUI       │  │   CoreLocation  │  │
│  │   (SwiftUI)     │  │   Views         │  │   Services      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ HTTPS/JSON
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   FastAPI       │  │   CORS          │  │   Authentication│  │
│  │   Backend       │  │   Middleware    │  │   Middleware    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ Firebase Admin SDK
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE LAYER                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Firebase      │  │   Firebase      │  │   Vercel        │  │
│  │   Authentication│  │   Firestore     │  │   Deployment    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend (iOS)
- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Architecture**: MVVM (Model-View-ViewModel)
- **Dependencies**: 
  - Firebase iOS SDK
  - CoreLocation
  - MapKit
  - Combine

### Backend (API)
- **Framework**: FastAPI
- **Language**: Python 3.8+
- **Architecture**: RESTful API with dependency injection
- **Dependencies**:
  - Firebase Admin SDK
  - Pydantic (data validation)
  - Uvicorn (ASGI server)

### Infrastructure
- **Authentication**: Firebase Authentication
- **Database**: Firebase Firestore
- **Deployment**: Vercel (Backend)
- **Hosting**: Apple App Store (iOS App)

## Detailed Architecture

### 1. iOS Application Architecture

#### MVVM Pattern Implementation

```
┌─────────────────────────────────────────────────────────────────┐
│                           VIEW LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ AuthenticationView│  │   ContentView   │  │   FinderView    │  │
│  │                 │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   RenterView    │  │ SpotDetailView  │  │   ProfileView   │  │
│  │                 │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ @EnvironmentObject
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        VIEW MODEL LAYER                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ParkingSpotViewModel│  │  FirebaseService │  │ LocationManager │  │
│  │                 │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ API Calls
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SERVICE LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Firebase      │  │   HTTP          │  │   Location      │  │
│  │   Services      │  │   Client        │  │   Services      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

#### Key Components

**Views (Presentation Layer)**
- `AuthenticationView`: Handles user login/signup
- `ContentView`: Main tab navigation container
- `FinderView`: Parking spot discovery and booking
- `RenterView`: Parking spot management for owners
- `SpotDetailView`: Detailed parking spot information
- `ProfileView`: User profile and settings

**ViewModels (Business Logic Layer)**
- `ParkingSpotViewModel`: Main business logic for parking operations
- `FirebaseService`: Firebase integration and API communication
- `LocationManager`: Location services and permissions

**Models (Data Layer)**
- `User`: User profile and authentication data
- `ParkingSpot`: Parking spot information and metadata
- `Booking`: Booking request and status management

### 2. Backend API Architecture

#### FastAPI Application Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                      FASTAPI APPLICATION                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Main App      │  │   Middleware    │  │   Dependencies  │  │
│  │   (main.py)     │  │   (CORS, Auth)  │  │   (Firebase)    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ Router Registration
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         ROUTER LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Auth Router   │  │   Users Router  │  │   Spots Router  │  │
│  │   (/api/auth)   │  │   (/api/users)  │  │   (/api/spots)  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐                                            │
│  │ Bookings Router │                                            │
│  │ (/api/bookings) │                                            │
│  └─────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ Service Calls
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SERVICE LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ FirebaseService │  │   Validation    │  │   Error         │  │
│  │                 │  │   Service       │  │   Handling      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ Firestore Operations
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FIRESTORE DATABASE                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Users         │  │   Parking Spots │  │   Bookings      │  │
│  │   Collection    │  │   Collection    │  │   Collection    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

#### API Endpoints Structure

**Authentication Endpoints**
```
POST   /api/auth/register     - User registration
POST   /api/auth/login        - User login
GET    /api/auth/me           - Get current user
DELETE /api/auth/logout       - User logout
```

**User Management Endpoints**
```
GET    /api/users/profile     - Get user profile
PUT    /api/users/profile     - Update user profile
DELETE /api/users/profile     - Delete user profile
```

**Parking Spots Endpoints**
```
GET    /api/parking-spots/           - Get all parking spots
GET    /api/parking-spots/nearby     - Get nearby spots
GET    /api/parking-spots/my-spots   - Get user's spots
GET    /api/parking-spots/{id}       - Get specific spot
POST   /api/parking-spots/           - Create new spot
PUT    /api/parking-spots/{id}       - Update spot
DELETE /api/parking-spots/{id}       - Delete spot
```

**Booking Endpoints**
```
GET    /api/bookings/my-bookings        - Get user's bookings
GET    /api/bookings/pending-requests   - Get pending requests
GET    /api/bookings/{id}               - Get specific booking
POST   /api/bookings/                   - Create booking request
PUT    /api/bookings/{id}/approve       - Approve booking
PUT    /api/bookings/{id}/reject        - Reject booking
PUT    /api/bookings/{id}/cancel        - Cancel booking
DELETE /api/bookings/{id}               - Delete booking
```

### 3. Data Flow Architecture

#### Authentication Flow

```
1. User opens app
   ↓
2. FirebaseService checks authentication state
   ↓
3. If not authenticated → AuthenticationView
   ↓
4. User enters credentials
   ↓
5. FirebaseService.signIn() called
   ↓
6. Firebase Authentication validates credentials
   ↓
7. Backend API login endpoint called
   ↓
8. User profile fetched from Firestore
   ↓
9. App transitions to ContentView
```

#### Booking Request Flow

```
1. User selects parking spot
   ↓
2. SpotDetailView shows booking form
   ↓
3. User fills booking details (time, message)
   ↓
4. ParkingSpotViewModel.sendBookingRequest() called
   ↓
5. FirebaseService.createBookingRequest() called
   ↓
6. Backend API validates request
   ↓
7. Booking created in Firestore
   ↓
8. Spot owner receives notification
   ↓
9. Owner can approve/reject in RenterView
```

#### Data Synchronization Flow

```
1. App starts or user action triggers refresh
   ↓
2. FirebaseService makes API calls
   ↓
3. Backend validates Firebase token
   ↓
4. Backend queries Firestore
   ↓
5. Data returned to iOS app
   ↓
6. ViewModels update @Published properties
   ↓
7. SwiftUI views automatically update
   ↓
8. UI reflects latest data
```

### 4. Security Architecture

#### Authentication Security

**Firebase Authentication**
- Email/password authentication
- Secure token management
- Automatic session persistence
- Token refresh handling

**API Security**
- Firebase ID token validation
- CORS configuration
- Rate limiting (can be added)
- Input validation with Pydantic

#### Data Security

**Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // Parking spots: read by all, write by owner
    match /parking_spots/{spotId} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.owner_id;
    }
    
    // Bookings: access by finder or spot owner
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.finder_id || 
         request.auth.uid == resource.data.owner_id);
    }
  }
}
```

### 5. Deployment Architecture

#### iOS App Deployment
- **Build System**: Xcode
- **Distribution**: Apple App Store
- **Code Signing**: Apple Developer Certificates
- **Environment**: Development/Production configurations

#### Backend Deployment
- **Platform**: Vercel
- **Runtime**: Python 3.8+
- **Environment Variables**: Firebase credentials
- **Domain**: Custom domain or Vercel subdomain

#### Infrastructure Deployment
- **Firebase Project**: Google Cloud Platform
- **Database**: Firestore (serverless)
- **Authentication**: Firebase Auth
- **Monitoring**: Firebase Console

### 6. Scalability Considerations

#### Horizontal Scaling
- **Backend**: Vercel automatically scales
- **Database**: Firestore scales automatically
- **Authentication**: Firebase handles scaling

#### Performance Optimization
- **Caching**: Implement client-side caching
- **Pagination**: API supports pagination
- **Lazy Loading**: Images and data loaded on demand
- **Background Refresh**: Periodic data updates

#### Future Scalability Features
- **CDN**: For static assets
- **Redis**: For session management
- **Message Queues**: For async processing
- **Microservices**: Split backend into services

### 7. Error Handling Architecture

#### Client-Side Error Handling
```swift
// FirebaseService error handling
enum APIError: Error, LocalizedError {
    case registrationFailed
    case loginFailed
    case fetchFailed
    case createFailed
    case updateFailed
    case deleteFailed
    
    var errorDescription: String? {
        // User-friendly error messages
    }
}
```

#### Server-Side Error Handling
```python
# FastAPI error handling
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )
```

#### Error Recovery Strategies
- **Network Errors**: Retry with exponential backoff
- **Authentication Errors**: Redirect to login
- **Validation Errors**: Show user-friendly messages
- **Server Errors**: Graceful degradation

### 8. Testing Architecture

#### Client Testing
- **Unit Tests**: ViewModels and Services
- **UI Tests**: SwiftUI view interactions
- **Integration Tests**: API communication
- **Mock Data**: For offline development

#### Backend Testing
- **Unit Tests**: Service layer functions
- **Integration Tests**: API endpoints
- **Database Tests**: Firestore operations
- **Authentication Tests**: Token validation

### 9. Monitoring and Analytics

#### Application Monitoring
- **Firebase Analytics**: User behavior tracking
- **Crashlytics**: Error reporting
- **Performance Monitoring**: App performance metrics
- **Custom Events**: Business-specific analytics

#### Infrastructure Monitoring
- **Vercel Analytics**: API performance
- **Firebase Console**: Database usage
- **Error Tracking**: Centralized error logging
- **Uptime Monitoring**: Service availability

## Development Workflow

### 1. Local Development
```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py

# iOS App
open parking.xcodeproj
# Build and run in Xcode
```

### 2. Testing
```bash
# Backend tests
cd backend
pytest

# iOS tests
# Run in Xcode Test navigator
```

### 3. Deployment
```bash
# Backend deployment
cd backend
vercel --prod

# iOS deployment
# Archive and upload to App Store Connect
```

## Conclusion

This architecture provides a robust, scalable foundation for the Parking App with:

- **Separation of Concerns**: Clear layers and responsibilities
- **Scalability**: Cloud-native infrastructure
- **Security**: Multi-layer security implementation
- **Maintainability**: Clean code structure and documentation
- **Performance**: Optimized data flow and caching
- **Reliability**: Comprehensive error handling and monitoring

The system is designed to handle growth from MVP to production scale while maintaining code quality and developer productivity.
