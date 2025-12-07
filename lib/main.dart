import 'dart:convert';
import 'package:flutter/material.dart';
import 'video_call_page.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AdminDeliveryPersonListPage(),
  ));
}

class AdminDeliveryPersonListPage extends StatefulWidget {
  const AdminDeliveryPersonListPage({super.key});

  @override
  State<AdminDeliveryPersonListPage> createState() =>
      _AdminDeliveryPersonListPageState();
}

class _AdminDeliveryPersonListPageState
    extends State<AdminDeliveryPersonListPage> {
  List<dynamic> deliveryPersons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDeliveryPersons();
  }

  Future<void> fetchDeliveryPersons() async {
    final url =
        'http://192.168.29.182:5000/api/getPendingKYC/pendingkyc'; // adjust IP
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          deliveryPersons = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('Failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Delivery Persons')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: deliveryPersons.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final person = deliveryPersons[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(person['name'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile: ${person['mobile_number'] ?? ''}'),
                        Text('Email: ${person['email'] ?? ''}'),
                        Text('Aadhar: ${person['aadhar_number'] ?? ''}'),
                        Text('Pancard: ${person['pancard_number'] ?? ''}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VideoCallPage(dpId: person['DP_id']),
                          ),
                        );
                      },
                      child: const Text('Video Call'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
