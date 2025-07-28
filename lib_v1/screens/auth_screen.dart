import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'consumer';
  bool _isLogin = true;

  Future<void> _submit() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      UserCredential userCredential;
      if (_isLogin) {
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': _emailController.text.trim(),
          'role': _role,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sahayog Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            if (!_isLogin)
              DropdownButton<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'consumer', child: Text('Consumer')),
                  DropdownMenuItem(value: 'provider', child: Text('Provider')),
                ],
                onChanged: (value) => setState(() => _role = value!),
              ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(_isLogin ? 'Login' : 'Register')),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Create new account' : 'Already have an account? Login'),
            )
          ],
        ),
      ),
    );
  }
}
