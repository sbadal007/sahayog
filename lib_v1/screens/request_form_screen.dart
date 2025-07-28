import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _location = '';
  double _price = 0;
  String _role = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _role = doc['role'];
      _loading = false;
    });
  }

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (_role != 'consumer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only consumers can create requests.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('requests').add({
      'userId': user.uid,
      'title': _title,
      'description': _description,
      'location': _location,
      'price': _price,
      'status': 'open',
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request submitted!')),
    );
    _formKey.currentState!.reset();
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $_role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onSaved: (val) => _title = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (val) => _description = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                onSaved: (val) => _location = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _price = double.tryParse(val ?? '') ?? 0,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _formKey.currentState!.save();
                  _submitRequest();
                },
                child: const Text('Submit Request'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
