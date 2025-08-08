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
│   ├── models/                      # Data models
│   │   ├── user.dart               # User data model
│   │   ├── request.dart            # Request data model with pricing
│   │   ├── message.dart            # Enhanced message model for chat system
│   │   ├── conversation.dart       # Chat conversation data model
│   │   ├── rating.dart             # Rating/review data model
│   │   ├── user_rating_summary.dart # Aggregated rating statistics
│   │   └── offer.dart              # Enhanced offer model with custom terms & chat link
│   ├── providers/                   # State management
│   │   └── user_provider.dart       # User data provider
│   ├── screens/                     # UI screens
│   │   ├── welcome_screen.dart      # Landing/auth screen
│   │   ├── sign_in_screen.dart      # Authentication
│   │   ├── sign_up_screen.dart      # User registration
│   │   ├── home_screen.dart         # Main navigation hub with chat tab
│   │   ├── profile_screen.dart      # User profile with rating display
│   │   ├── conversation_list_screen.dart # Chat conversations list
│   │   └── chat_screen.dart         # Real-time chat interface
│   ├── widgets/                     # Reusable UI components
│   │   ├── create_request_tab.dart  # Request creation form
│   │   ├── view_offers_tab.dart     # Browse requests (Helper view)
│   │   ├── requester_inbox.dart     # Requester's dashboard with chat integration
│   │   ├── helper_inbox.dart        # Helper's dashboard with chat integration
│   │   ├── incoming_offers_tab.dart # Offer management
│   │   ├── inbox_tab.dart          # Role-based inbox router
│   │   ├── offer_dialog.dart       # Interactive offer creation dialog
│   │   ├── rating_dialog.dart      # Interactive rating submission
│   │   ├── rating_display_widget.dart # Rating summary display
│   │   ├── message_bubble.dart     # Chat message UI component
│   │   ├── typing_indicator.dart   # Real-time typing animation
│   │   ├── user_avatar.dart        # Profile picture component
│   │   └── user_status_widget.dart # Online/offline indicator
│   └── services/                   # Business logic & utilities
│       ├── firebase_service.dart   # Firebase initialization
│       ├── user_status_service.dart # Online presence tracking
│       ├── notification_service.dart # Push notifications
│       ├── rating_service.dart     # Rating/review operations
│       └── chat_service.dart       # Real-time chat functionality
├── android/                        # Android-specific code
├── web/                            # Web deployment assets
├── functions/                      # Firebase Cloud Functions (chat archiving)
└── firestore_chat.rules           # Enhanced security rules with chat permissions
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
- **ViewOffersTab**: Helper interface to browse and respond to requests with enhanced offer dialog
- **OfferDialog**: Interactive dialog for creating offers with custom messages and alternative pricing
- **RequesterInbox**: Dashboard for managing requests and incoming offers with custom terms display
- **HelperInbox**: Dashboard for tracking sent offers and status updates with offer details
- **IncomingOffersTab**: Enhanced offer management with custom message and pricing display

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
- **Enhanced Offer Management**: Custom messaging and alternative pricing in offers
- **Interactive Offer Creation**: Guided dialog system for personalized offers

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

### Models & Data Structures
- **Offer Model**: Complete offer data structure with custom messaging and pricing
- **Request Model**: Enhanced with price field for better offer comparison
- **Message Model**: Basic messaging infrastructure for future chat system
- **User Model**: Comprehensive user profile with role-based features

### Code Patterns
- **State Management**: Provider pattern with ChangeNotifier
- **Async Operations**: Future-based with proper error handling
- **UI Structure**: StatefulWidget for complex screens, StatelessWidget for simple displays
- **Data Flow**: Unidirectional data flow with provider updates triggering UI rebuilds
- **Dialog-based Interactions**: Modal dialogs for complex user inputs
- **Conditional UI Rendering**: Dynamic content based on data availability

### Database Schema
- **Users**: `uid`, `username`, `email`, `role`, `profileImageUrl`, `isOnline`, `lastSeen`
- **Requests**: `userId`, `title`, `description`, `price`, `location`, `status`, `createdAt`
- **Offers**: `requestId`, `helperId`, `helperName`, `requesterId`, `status`, `createdAt`, `customMessage`, `alternativePrice`, `conversationId`
- **Conversations**: `offerId`, `participants`, `lastMessageAt`, `lastMessageText`, `unreadCount`, `isArchived`
- **Messages**: `conversationId`, `senderId`, `senderName`, `text`, `createdAt`, `readBy`, `type`
- **ArchivedConversations**: Same as conversations with `archivedAt` timestamp
- **Ratings**: `requestId`, `offerId`, `reviewerId`, `revieweeId`, `rating`, `review`, `reviewType`, `createdAt`
- **UserRatingSummaries**: `userId`, `averageRating`, `totalRatings`, `ratingBreakdown`
- **Notifications**: `userId`, `title`, `message`, `type`, `createdAt`, `isRead`

## � Recent Updates & Features

### Two-Way Chat System (August 2025)
- **Real-time Messaging**: Bidirectional chat between Requesters and Helpers
  - Messages linked to specific offers for contextual communication
  - Real-time message delivery with Firestore streams
  - Message read receipts and unread count tracking
  - Typing indicators with debounced status updates
- **Conversation Management**: 
  - Automatic conversation creation when offers are accepted
  - Conversation list with active and archived sections
  - Chat integration directly from inbox screens
- **Message Features**:
  - Text messages with timestamp formatting
  - System messages for offer-related events
  - Read status tracking per message
  - Message history preservation
- **Security & Privacy**:
  - Participant-only access to conversations
  - Secure message creation and reading permissions
  - Archive system for completed offer conversations

### Enhanced Rating/Review System (August 2025)
- **Comprehensive Rating Models**: Rating and UserRatingSummary data structures
- **Interactive Rating Dialog**: Star-based rating with optional review text
- **Profile Integration**: Rating display in user profiles with recent reviews
- **Real-time Updates**: Stream-based rating data synchronization
- **Bidirectional Reviews**: Both helpers and requesters can rate each other

### Enhanced Offer Management System (August 2025)
- **Custom Messages**: Helpers can now add personalized messages with their offers
  - 500 character limit with validation
  - Helps build trust and communication
  - Displayed across all offer interfaces
- **Alternative Pricing**: Option to propose different prices than requested
  - Input validation for positive numbers only
  - Clear visual indicators with orange-themed containers
  - Original vs. proposed price comparison
- **Improved UI/UX**: 
  - Interactive offer creation dialog
  - Color-coded display (blue for messages, orange for pricing)
  - Enhanced notification system with custom terms mention
  - Responsive design across all screen sizes

### Technical Implementation
- **New Models**: Enhanced Message, Conversation, Rating, and UserRatingSummary models
- **Chat Service**: Comprehensive ChatService for real-time messaging operations
- **UI Components**: MessageBubble, TypingIndicator, and conversation management screens
- **Database Integration**: New Firestore collections with proper security rules
- **Real-time Streams**: Live updates for messages, conversations, and typing indicators
- **Archive System**: Automatic conversation archiving when offers are completed

## �🚧 Work In Progress / TODOs

### Immediate Priority
- **Image Loading Issues**: Firebase Storage CORS problems causing "statusCode: 0" errors
- **Performance Optimization**: UserProvider excessive notifications resolved but monitoring needed
- **Cloud Functions**: Proxy service for image downloads partially implemented

### Recently Completed ✅
- **Two-Way Chat System**: Real-time messaging between Requesters and Helpers
- **Enhanced Offer Management**: Custom messages and alternative pricing in offers
- **Rating/Review System**: User feedback and reputation tracking with UI integration
- **Interactive Offer Dialog**: User-friendly interface for creating personalized offers
- **Improved Offer Display**: Visual indicators for custom terms across all interfaces
- **Data Model Updates**: Enhanced models with new fields for chat and rating systems
- **Security Rules**: Comprehensive Firestore rules for chat, ratings, and existing features
- **Centralized Error Handling System**: Comprehensive error management with debugging
- **Automatic Index Management**: Smart handling of Firestore index creation and building states

### Planned Features
- **Chat Archiving Cloud Function**: Automated conversation archiving when offers complete
- **Push Notifications**: Firebase Cloud Messaging for chat notifications
- **Advanced Chat Features**: File attachments, message reactions, and message search
- **Payment Integration**: Secure transaction processing
- **Advanced Search**: Location-based request filtering
- **Offline Chat Support**: Message queuing and offline functionality

### Technical Debt
- **Firestore Index Creation**: Automatic index creation fails due to permission restrictions
- **Review Section Index Issues**: Rating/review queries need proper indexing
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

*Last Updated: August 07, 2025*
*Project Status: Active Development*
*Latest Feature: Two-Way Real-time Chat System with Rating Integration*