import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class CreateRequestTab extends StatefulWidget {
  const CreateRequestTab({super.key});

  @override
  State<CreateRequestTab> createState() => _CreateRequestTabState();
}

class _CreateRequestTabState extends State<CreateRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _preferredDate;
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a preferred date')),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required. Please enable location services.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // final user = FirebaseAuth.instance.currentUser;
      // if (user == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Please sign in to create a request')),
      //   );
      //   return;
      // }

      await FirebaseFirestore.instance.collection('requests').add({
        'userId': 'test-user', // temporary test user id
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'location': _locationController.text,
        'preferredDate': Timestamp.fromDate(_preferredDate!),
        'createdAt': Timestamp.now(),
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'status': 'open',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request created successfully!')),
        );
        _formKey.currentState?.reset();
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _locationController.clear();
        setState(() => _preferredDate = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating request: $e')),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Location is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Offered Price',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Price is required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_preferredDate == null 
                ? 'Select Preferred Date' 
                : 'Date: ${_preferredDate.toString().split(' ')[0]}'),
              tileColor: Colors.grey[100],
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() => _preferredDate = date);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitRequest,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
              label: Text(_isLoading ? 'Submitting...' : 'Submit Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
