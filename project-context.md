# Sahayog - Project Context Documentation

## 🧱 Project Overview

**Sahayog** is a Flutter-based mobile application that connects people who need help with those willing to provide assistance. It's a peer-to-peer service platform where:

- **Requesters** can post requests for help with specific tasks, offering compensation
- **Helpers** can browse available requests and offer their services
- The app facilitates the connection between requesters and helpers through a structured offer system

**Tech Stack:**
- Frontend: Flutter (Dart)
- Backend: Firebase (Firestore, Auth, Storage, Functions)
- State Management: Provider pattern
- Web Support: Enabled with URL strategy

## 📁 Folder Structure

```
sahayog/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase configuration
│   ├── providers/                   # State management
│   │   └── user_provider.dart       # User data provider
│   ├── screens/                     # UI screens
│   │   ├── welcome_screen.dart      # Landing/auth screen
│   │   ├── sign_in_screen.dart      # Authentication
│   │   ├── sign_up_screen.dart      # User registration
│   │   ├── home_screen.dart         # Main navigation hub
│   │   └── profile_screen.dart      # User profile management
│   ├── widgets/                     # Reusable UI components
│   │   ├── create_request_tab.dart  # Request creation form
│   │   ├── view_offers_tab.dart     # Browse requests (Helper view)
│   │   ├── requester_inbox.dart     # Requester's dashboard
│   │   ├── helper_inbox.dart        # Helper's dashboard
│   │   ├── incoming_offers_tab.dart # Offer management
│   │   ├── inbox_tab.dart          # Role-based inbox router
│   │   ├── user_avatar.dart        # Profile picture component
│   │   └── user_status_widget.dart # Online/offline indicator
│   └── services/                   # Business logic & utilities
│       ├── firebase_service.dart   # Firebase initialization
│       ├── user_status_service.dart # Online presence tracking
│       └── notification_service.dart # Push notifications
├── android/                        # Android-specific code
├── web/                            # Web deployment assets
└── functions/                      # Firebase Cloud Functions (planned)
```

## 🧩 Key Components/Modules

### Core Screens
- **WelcomeScreen**: Entry point with authentication options
- **SignInScreen**: Username/email + password authentication with token-based login
- **SignUpScreen**: User registration with role selection (Requester/Helper)
- **HomeScreen**: Role-based navigation hub with tab switching
- **ProfileScreen**: User profile management with image upload capabilities

### Core Widgets
- **UserAvatar**: Cached network image component with retry logic and error handling
- **UserStatusWidget**: Real-time online/offline status indicator
- **CreateRequestTab**: Form for creating help requests with location services
- **ViewOffersTab**: Helper interface to browse and respond to requests
- **RequesterInbox**: Dashboard for managing requests and incoming offers
- **HelperInbox**: Dashboard for tracking sent offers and status updates

### State Management
- **UserProvider**: Centralized user state with change detection to prevent unnecessary rebuilds
- Uses Provider pattern for reactive UI updates

## 🔧 Core Functions/Utilities

### Services
- **FirebaseService**: Handles Firebase app initialization across platforms
- **UserStatusService**: Manages user online/offline presence with app lifecycle tracking
- **NotificationService**: Creates and manages in-app notifications for offer updates

### Key Utilities
- **User Authentication**: Username or email-based login with Firebase Auth
- **Image Handling**: Profile picture upload with platform-specific handling (Web/Mobile)
- **Location Services**: GPS-based location capture for requests
- **Real-time Updates**: Firestore snapshots for live data synchronization
- **Error Handling**: Comprehensive error management with user-friendly messages

## 🔌 APIs or Data Sources

### Firebase Services
- **Firebase Auth**: User authentication and session management
- **Firestore Database**: 
  - Collections: `users`, `requests`, `offers`, `usernames`, `notifications`
  - Real-time subscriptions for live updates
- **Firebase Storage**: Profile picture storage with direct URL access
- **Firebase Functions**: Planned proxy service for image downloads

### External Integrations
- **Geolocator**: GPS location services for request positioning
- **Image Picker**: Camera and gallery access for profile pictures
- **URL Strategy**: Web routing configuration

## ⚙️ Configuration & Environment

### Key Configuration Files
- **`firebase_options.dart`**: Multi-platform Firebase configuration (Web, Android, iOS)
- **`android/app/src/main/kotlin/...MainActivity.kt`**: Android app entry point
- **`pubspec.yaml`**: Flutter dependencies and asset configuration
- **Firebase Console Settings**: 
  - Storage CORS configuration required
  - Firestore security rules for user data access
  - Authentication providers setup

### Environment-Specific Setup
- Web: Custom URL strategy for clean URLs
- Android: Standard Flutter configuration
- Firebase: Separate configs per platform with proper API keys

## 🧪 Testing Overview

**Current State**: No formal testing framework implemented yet.

**Planned Testing Structure**:
- Unit tests for services and utilities
- Widget tests for UI components
- Integration tests for Firebase operations
- Mock services for offline testing

**Debug Features**:
- Extensive `debugPrint` logging throughout the application
- Test user functionality with fallback IDs
- Error state visualization in UI components

## 🗂 Naming Conventions & Patterns

### File Naming
- **Screens**: `[name]_screen.dart` (snake_case)
- **Widgets**: `[name]_widget.dart` or `[name]_tab.dart`
- **Services**: `[name]_service.dart`
- **Providers**: `[name]_provider.dart`

### Code Patterns
- **State Management**: Provider pattern with ChangeNotifier
- **Async Operations**: Future-based with proper error handling
- **UI Structure**: StatefulWidget for complex screens, StatelessWidget for simple displays
- **Data Flow**: Unidirectional data flow with provider updates triggering UI rebuilds

### Database Schema
- **Users**: `uid`, `username`, `email`, `role`, `profileImageUrl`, `isOnline`, `lastSeen`
- **Requests**: `userId`, `title`, `description`, `price`, `location`, `status`, `createdAt`
- **Offers**: `requestId`, `helperId`, `helperName`, `requesterId`, `status`, `createdAt`

## 🚧 Work In Progress / TODOs

### Immediate Priority
- **Image Loading Issues**: Firebase Storage CORS problems causing "statusCode: 0" errors
- **Performance Optimization**: UserProvider excessive notifications resolved but monitoring needed
- **Cloud Functions**: Proxy service for image downloads partially implemented

### Planned Features
- **Chat System**: Direct messaging between requesters and helpers
- **Rating System**: User feedback and reputation tracking  
- **Payment Integration**: Secure transaction processing
- **Advanced Search**: Location-based request filtering
- **Push Notifications**: Firebase Cloud Messaging integration

### Technical Debt
- **Error Boundaries**: Need comprehensive error handling UI
- **Offline Support**: Cache management for offline functionality
- **Testing Coverage**: Complete test suite implementation
- **Code Documentation**: API documentation for services
- **Security Audit**: Review Firebase security rules and data access patterns

### Known Issues
- Web platform Firebase Storage connectivity issues
- Username mapping system needs optimization for large scale
- Location services permission handling could be improved
- Image caching strategy needs refinement

---

*Last Updated: August 06, 2025*
*Project Status: Active Development*