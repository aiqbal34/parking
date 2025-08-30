# ParkingApp - "DoorDash for Parking" 🚗

A Swift iOS app MVP for a platform where people can find and rent out parking spots near stadiums or event areas.

## Features

### For Finders (People looking for parking)
- **Map View**: Interactive map showing nearby available parking spots with pins
- **Spot Details**: View address, hourly rate, availability window, distance, and description
- **Booking Flow**: Mock booking system with time selection and price calculation
- **List View**: Alternative scrollable list of spots sorted by distance or price

### For Renters (People listing their spots)
- **Add Parking Spot**: Easy form with auto-fill current address using GPS
- **Manage Spots**: Edit price, availability, description, and toggle availability
- **View Bookings**: See mock bookings from people who reserved your spots
- **Earnings Overview**: Track income from your parking spots

## Technical Details

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM pattern
- **Location Services**: CoreLocation for GPS and address geocoding
- **Maps**: MapKit for interactive map with custom annotations
- **Data**: Mock data service (ready for Firebase integration)

## Project Structure

```
ParkingApp/
├── Models/
│   ├── ParkingSpot.swift      # Core parking spot data model
│   ├── User.swift             # User data model
│   └── Booking.swift          # Booking data model
├── Views/
│   ├── ContentView.swift      # Main tab navigation
│   ├── FinderView.swift       # Map view for finding spots
│   ├── MapView.swift          # MapKit integration
│   ├── SpotDetailView.swift   # Detailed spot view with booking
│   ├── RenterView.swift       # Renter dashboard
│   ├── AddSpotView.swift      # Add new parking spot form
│   └── ManageSpotsView.swift  # Edit/manage existing spots
├── ViewModels/
│   └── ParkingSpotViewModel.swift  # Main view model with business logic
└── Services/
    ├── LocationManager.swift      # GPS and geocoding services
    └── MockDataService.swift      # Mock data for testing
```

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Device with GPS capability (for location features)

### Installation
1. Open `ParkingApp.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on simulator or device

### Location Permissions
The app requires location permissions to:
- Show nearby parking spots
- Auto-fill current address when adding spots
- Calculate distances to parking spots

## Key Features Implemented

### ✅ Core MVP Features
- [x] Tab-based navigation (Finder/Renter)
- [x] Interactive map with parking spot pins
- [x] Spot details with booking flow
- [x] Add/edit/delete parking spots
- [x] Location services integration
- [x] Mock data service
- [x] Price calculations
- [x] Availability management

### 🎯 User Flows
- [x] **Finder Flow**: Map → Spot Selection → Details → Mock Booking
- [x] **Renter Flow**: Add Spot → Manage Spots → View Mock Bookings

### 📱 UI/UX
- [x] Clean, modern SwiftUI interface
- [x] Responsive design for iPhone/iPad
- [x] Intuitive navigation patterns
- [x] Visual feedback for user actions

## Future Enhancements (Stretch Goals)

### Ready for Implementation
- **Firebase Integration**: Replace mock data with real backend
- **Authentication**: Email/password login with Firebase Auth
- **Photo Upload**: Add parking spot photos
- **Push Notifications**: New booking alerts
- **Payment Integration**: Stripe or Apple Pay
- **Reviews System**: Rate parking spots and renters
- **Advanced Filters**: Price range, distance, vehicle size
- **Real-time Updates**: Live availability status

### Architecture Benefits
- **MVVM Pattern**: Clean separation of concerns, easy to test
- **SwiftUI**: Modern, declarative UI framework
- **Combine Framework**: Reactive programming for data flow
- **Protocol-Oriented**: Easy to swap mock data for real services

## Demo Data

The app includes realistic mock data:
- 5 parking spots around San Francisco stadium areas
- Various price points ($8-20/hour)
- Different vehicle size accommodations
- Mock booking history
- Sample user profiles

## Development Notes

### Location Services
- Uses CoreLocation for GPS positioning
- Implements forward and reverse geocoding
- Handles location permission requests gracefully
- Falls back to default location if GPS unavailable

### Map Integration
- Custom MapKit annotations for parking spots
- User location tracking
- Interactive spot selection
- Smooth region updates based on user location

### Data Management
- Reactive data binding with Combine
- Thread-safe UI updates
- Optimistic UI updates for better UX
- Easy transition path to real backend

## Testing

The app works best on a physical device for location testing, but also functions in the iOS Simulator with simulated locations.

### Simulator Testing
1. In Simulator, go to Device → Location → Custom Location
2. Enter coordinates: Latitude 37.7749, Longitude -122.4194 (San Francisco)
3. The app will show nearby mock parking spots

## Support

This is an MVP demonstrating core functionality. The codebase is well-commented and structured for easy expansion into a full production app.

---

Built with ❤️ using Swift and SwiftUI