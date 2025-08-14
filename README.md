# VIVORA - Salon Booking Mobile App

A Flutter-based mobile application that allows users to discover, book, and manage salon appointments with location-based search and mapping functionality.

## Features

### 🏠 Home & Discovery
- **Location-based salon search** - Find salons near your current location
- **Interactive map view** - Visualize salon locations with markers
- **Real-time search** - Search salons by name with live results
- **Distance calculation** - See how far salons are from your location
- **Salon ratings** - View average ratings for each salon

### 👤 User Management
- **User authentication** - Secure login and signup
- **User profiles** - Manage personal information
- **Profile customization** - Update user details and preferences

### 📅 Booking System
- **Appointment booking** - Schedule salon appointments
- **Booking confirmation** - Receive confirmation for appointments
- **Current bookings** - View active appointments
- **Booking history** - Track past appointments
- **Booking management** - Cancel or modify appointments

### 💎 Salon Features
- **Salon profiles** - Detailed salon information and services
- **Service listings** - Browse available salon services
- **Salon ratings** - Rate and review salon experiences
- **Contact information** - Access salon details and location

## Technology Stack

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: StatefulWidget
- **Maps**: flutter_map with OpenStreetMap
- **Location Services**: geolocator
- **HTTP Client**: Built-in Dart HTTP

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── config/
│   └── api_constants.dart            # API configuration
├── screens/
│   ├── home_screen.dart              # Main home screen with map
│   ├── salon_profile.dart            # Salon details screen
│   ├── booking_screen.dart           # Appointment booking
│   ├── booking_confirmation_screen.dart
│   ├── current_booking.dart          # Active bookings
│   ├── booking_history.dart          # Past bookings
│   ├── user_profile.dart             # User profile management
│   ├── rate_us.dart                  # Rating screen
│   ├── start_screen.dart             # Welcome screen
│   └── auth/
│       ├── login_screen.dart         # User login
│       └── signup_screen.dart        # User registration
├── services/
│   ├── auth_service.dart             # Authentication logic
│   ├── salon_service.dart            # Salon data management
│   ├── booking_service.dart          # Booking operations
│   ├── booking_storage_service.dart  # Local booking storage
│   ├── profile_service.dart          # User profile management
│   └── review_service.dart           # Rating and review system
├── utils/
│   ├── colors.dart                   # App color scheme
│   └── styles.dart                   # Common styling
└── widgets/
    ├── custom_button.dart            # Reusable button component
    ├── custom_textfield.dart         # Reusable input component
    └── salon_card.dart               # Salon display component
```

## Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK for Android development
- Xcode for iOS development (macOS only)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Vivora-Solutions/mobile.git
   cd mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoints**
   - Update `lib/config/api_constants.dart` with your backend API URLs

4. **Run the application**
   ```bash
   flutter run
   ```

## Configuration

### API Configuration
Update the API constants in `lib/config/api_constants.dart` with the backend URL:
```dart
class ApiConstants {
  static const String baseUrl = 'your-api-base-url';
  // Add other API endpoints
}
```

### Location Permissions
The app requires location permissions to function properly. Ensure the following permissions are added:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby salons.</string>
```

## Dependencies

Key dependencies used in this project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^6.0.0      # Interactive maps
  latlong2: ^0.8.1         # Latitude/longitude calculations
  geolocator: ^10.0.0      # Location services
  http: ^1.0.0            # HTTP requests
  shared_preferences: ^2.0.0  # Local storage
```

## Features Implementation

### Location-Based Search
- Uses device GPS to determine current location
- Calculates distances between user and salons
- Displays salons within configurable radius (default: 10km)
- Fallback to show all salons if location unavailable

### Map Integration
- Interactive map using OpenStreetMap tiles
- Custom markers for user location and salons
- Tap-to-navigate functionality to salon profiles
- Real-time marker updates based on search results

### Booking System
- Multi-step booking process
- Date and time selection
- Service selection
- Confirmation and storage
- Local and remote data synchronization

## API Integration

The app integrates with a backend API for:
- User authentication
- Salon data retrieval
- Booking management
- Review and rating system
- Location-based searches

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run tests using:
```bash
flutter test
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **Location Permission Denied**
   - Ensure location permissions are properly configured
   - Check device location settings

2. **Map Not Loading**
   - Verify internet connection
   - Check OpenStreetMap tile server status

3. **API Connection Issues**
   - Verify API endpoints in configuration
   - Check network connectivity
   - Ensure backend services are running

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team

## Acknowledgments

- OpenStreetMap for map tiles
- Flutter community for excellent packages
- Contributors and testers
