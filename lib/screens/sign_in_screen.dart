import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'sign_up_screen.dart';
import '../providers/user_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdentifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _isEmail(String text) {
    return text.contains('@') && text.contains('.');
  }

  Future<String?> _getEmailFromUsername(String username) async {
    try {
      debugPrint('SignInScreen: Looking up email for username: $username');
      
      // Query the usernames collection for the mapping
      final usernameDoc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      
      if (usernameDoc.exists) {
        final email = usernameDoc.data()?['email'] as String?;
        debugPrint('SignInScreen: Found email $email for username $username');
        return email;
      }
      
      debugPrint('SignInScreen: No email found for username: $username');
      return null;
    } catch (e) {
      debugPrint('SignInScreen: Error looking up username: $e');
      return null;
    }
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final userIdentifier = _userIdentifierController.text.trim();
      final password = _passwordController.text;
      String email = userIdentifier;

      // If not an email, try to get email from username
      if (!_isEmail(userIdentifier)) {
        debugPrint('SignInScreen: Input is username, looking up email...');
        final foundEmail = await _getEmailFromUsername(userIdentifier);
        
        if (foundEmail == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Username not found. Please check your username or try using your email address.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        email = foundEmail;
      }

      debugPrint('SignInScreen: Attempting to sign in with email: $email');

      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('SignInScreen: Authentication successful for user: ${authResult.user?.uid}');

      if (mounted) {
        // Check if user document exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user!.uid)
            .get();

        if (!userDoc.exists) {
          debugPrint('SignInScreen: User document not found, creating one');
          // Create user document if it doesn't exist
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authResult.user!.uid)
              .set({
            'uid': authResult.user!.uid,
            'email': authResult.user!.email ?? '',
            'username': authResult.user!.displayName ?? 'User${authResult.user!.uid.substring(0, 6)}',
            'role': 'Requester', // Default role
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'isVerified': false,
            'profileImageUrl': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Update online status for existing user
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authResult.user!.uid)
              .update({
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Load user data from Firestore with error handling
        try {
          await Provider.of<UserProvider>(context, listen: false)
              .loadUserFromFirestore(authResult.user!.uid);
        } catch (e) {
          debugPrint('SignInScreen: Error loading user provider: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('SignInScreen: FirebaseAuth error: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address. Please sign up first.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Incorrect email or password. Please check your credentials and try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Sign in failed: ${e.message ?? 'Unknown error'}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('SignInScreen: General error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _userIdentifierController,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter your email or username',
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email or username is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Password is required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Forgot password feature coming soon!'),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdentifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}