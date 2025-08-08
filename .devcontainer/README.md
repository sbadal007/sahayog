# Sahayog Flutter Project - Codespaces

This devcontainer provides a complete Flutter development environment with:

- ✅ Flutter SDK (latest stable)
- ✅ Dart SDK  
- ✅ VS Code extensions for Flutter/Dart
- ✅ Node.js for Firebase CLI
- ✅ GitHub CLI
- ✅ Port forwarding for web preview (8080, 3000, 5000)

## Quick Start in Codespaces

1. **Open in Codespaces**: Click the green "Code" button → "Codespaces" → "Create codespace"
2. **Wait for setup**: The environment will automatically install Flutter and dependencies
3. **Verify setup**: Run `flutter doctor` in the terminal
4. **Install Firebase CLI**: 
   ```bash
   npm install -g firebase-tools
   firebase login --no-localhost
   ```
5. **Run the app**:
   ```bash
   flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
   ```

## Testing Profile Pictures

The profile picture functionality should work better in Codespaces since:
- ✅ No CORS issues (running on server)
- ✅ Full Firebase integration
- ✅ Real browser environment

## Firebase Setup

Your Firebase configuration files are already included:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

## Port Access

- **8080**: Flutter web app
- **3000**: Development server (if needed)
- **5000**: Firebase emulator (if used)

Codespaces will automatically forward these ports and provide URLs for testing.
