# Sahayog - Peer-to-Peer Help Platform

A Flutter-based mobile application that connects people who need help with those willing to provide assistance. Built with Firebase backend for real-time features.

## 🚀 Features

### Core Platform Features
- **User Authentication**: Secure sign-up/sign-in with role-based access (Requester/Helper)
- **Request Management**: Create, browse, and manage help requests with location services
- **Offer System**: Enhanced offer creation with custom messages and alternative pricing
- **Rating & Reviews**: Comprehensive user feedback system with profile integration

### Two-Way Chat System ✨
- **Real-time Messaging**: Instant communication between Requesters and Helpers
- **Conversation Management**: 
  - Automatic chat creation when offers are accepted
  - Active and archived conversation lists
  - Chat integration directly from inbox screens
- **Advanced Chat Features**:
  - Message read receipts and unread count tracking
  - Real-time typing indicators
  - Message history preservation
  - System messages for offer-related events
- **Security & Privacy**: Participant-only access with secure permissions

### User Experience
- **Responsive Design**: Material Design components with smooth animations
- **Real-time Updates**: Live data synchronization across all features
- **Role-based Navigation**: Customized interface for Requesters vs Helpers
- **Profile Management**: User profiles with rating display and profile pictures

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Firestore (Real-time database)
  - Firebase Auth (Authentication)
  - Firebase Storage (File uploads)
  - Cloud Functions (Server-side logic)
- **State Management**: Provider pattern
- **Real-time Features**: Firestore streams for live updates

## 📱 App Structure

### For Requesters
1. **Create Requests**: Post help requests with details and pricing
2. **Manage Offers**: Review and accept/reject helper offers
3. **Chat with Helpers**: Direct communication after accepting offers
4. **Rate Helpers**: Provide feedback after request completion

### For Helpers  
1. **Browse Requests**: View available help requests
2. **Send Offers**: Create personalized offers with custom messages/pricing
3. **Chat with Requesters**: Communicate directly about request details
4. **Rate Requesters**: Share feedback about the experience

## 🔧 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase account and project setup
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/sbadal007/sahayog.git
   cd sahayog
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add your Android/iOS app to the project
   - Download and place configuration files:
     - `android/app/google-services.json` (Android)
     - `ios/Runner/GoogleService-Info.plist` (iOS)
   - Enable Authentication, Firestore, and Storage

4. **Configure Firestore Security Rules**
   ```bash
   # Copy the enhanced security rules from firestore_chat.rules
   firebase deploy --only firestore:rules
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 🔐 Firebase Configuration

### Required Firebase Services
- **Authentication**: Email/Password authentication
- **Firestore**: Real-time database with collections:
  - `users`, `requests`, `offers`, `conversations`, `messages`
  - `ratings`, `userRatingSummaries`, `archived_conversations`
- **Storage**: Profile image uploads
- **Cloud Functions**: Conversation archiving (optional)

### Required Firestore Indexes
The app will prompt you to create composite indexes. Required indexes include:
- **conversations**: `participants` (array-contains) + `lastMessageAt` (desc)
- **messages**: `conversationId` + `createdAt` (asc)
- **ratings**: `revieweeId` + `createdAt` (desc)

## 🏗 Project Architecture

```
lib/
├── models/          # Data models (User, Request, Offer, Conversation, Message, Rating)
├── services/        # Business logic (Firebase, Chat, Rating services)
├── screens/         # UI screens (Home, Chat, Profile, etc.)
├── widgets/         # Reusable UI components
└── providers/       # State management
```

## 🧪 Testing

```bash
# Run tests
flutter test

# Analyze code
flutter analyze
```

## 📋 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

For support or questions:
- Create an issue on GitHub
- Check the [project documentation](project-context.md)

---

**Current Version**: 2.0.0  
**Latest Update**: Two-Way Real-time Chat System with Rating Integration  
**Status**: Active Development
