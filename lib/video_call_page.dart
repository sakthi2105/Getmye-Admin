import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VideoCallPage extends StatefulWidget {
  final String dpId;
  const VideoCallPage({required this.dpId, super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  Map<String, dynamic>? dpDetails;
  bool isLoading = true;
  bool checkbox1 = false; // Profile
  bool checkbox2 = false; // Aadhar
  bool checkbox3 = false; // Pancard
  String? selectedImageBase64;
  bool isActionTaken = false; // To disable buttons after action
  bool isSubmitting = false; // New: Loading state during submission

  @override
  void initState() {
    super.initState();
    fetchDpDetails();
  }

  Future<void> fetchDpDetails() async {
    // Updated URL to match backend route: /api/:dp_id
    final url = 'http://192.168.29.182:5000/api/getPendingKYC/${widget.dpId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          if (decoded is Map<String, dynamic>) {
            dpDetails = decoded;
          } else if (decoded is List<dynamic> && decoded.isNotEmpty) {
            dpDetails = decoded[0] as Map<String, dynamic>;
          } else {
            dpDetails = null;
          }
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

  Future<void> approveOrReject(bool isApprove) async {
    // Check if all checkboxes are checked for approval
    if (isApprove && !(checkbox1 && checkbox2 && checkbox3)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please check all verification boxes before approving.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => isSubmitting = true); // Start loading

    final url = 'http://192.168.29.182:5000/api/getPendingKYC/updateKYCStatus';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dpId': widget.dpId,
          'status': isApprove ? 'approved' : 'rejected',
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          isActionTaken = true; // Disable buttons
          isSubmitting = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(isApprove ? 'KYC Approved successfully!' : 'KYC Rejected successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() => isSubmitting = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to update status. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Network error. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget imageFromBase64(String? base64String, {double height = 200}) {
    if (base64String == null) return const SizedBox();
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImageBase64 = base64String;
        });
      },
      child: Image.memory(base64Decode(base64String), height: height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Person Details'),
        backgroundColor: Colors.amber,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dpDetails == null
              ? const Center(child: Text('No details found'))
              : Row(
                  children: [
                    // Left side: Video call area (half page) - unchanged
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Video Call Area'),
                            Expanded(
                              child: Container(
                                color: Colors.grey[300],
                                child: const Center(child: Text('Video Call Placeholder')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right side: Details area or selected image (half page)
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedImageBase64 == null) ...[
                              // Show full details when no image selected
                              Text('Name: ${dpDetails!['name'] ?? ''}'),
                              Text('Mobile: ${dpDetails!['mobile_number'] ?? ''}'),
                              Text('Email: ${dpDetails!['email'] ?? ''}'),
                              const SizedBox(height: 10),
                              const Text('Profile Picture:'),
                              imageFromBase64(dpDetails!['profile_picture']),
                              const SizedBox(height: 10),
                              const Text('Aadhar Proof:'),
                              imageFromBase64(dpDetails!['aadhar_proof_picture']),
                              const SizedBox(height: 10),
                              const Text('Pancard Proof:'),
                              imageFromBase64(dpDetails!['pancard_proof_picture']),
                              const SizedBox(height: 20),
                            ] else ...[
                              // Show selected image larger size when clicked
                              Center(
                                child: Image.memory(
                                  base64Decode(selectedImageBase64!),
                                  height: 400,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedImageBase64 = null;
                                  });
                                },
                                child: const Text('Back to Details'),
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Checkboxes always visible
                            const Text('Checkboxes:'),
                            CheckboxListTile(
                              title: const Text('Profile'),
                              value: checkbox1,
                              activeColor: Colors.amber,
                              onChanged: (value) {
                                setState(() {
                                  checkbox1 = value ?? false;
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Aadhar'),
                              value: checkbox2,
                              activeColor: Colors.amber,
                              onChanged: (value) {
                                setState(() {
                                  checkbox2 = value ?? false;
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Pancard'),
                              value: checkbox3,
                              activeColor: Colors.amber,
                              onChanged: (value) {
                                setState(() {
                                  checkbox3 = value ?? false;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            // Approved and Rejected buttons - disabled after action or during submission
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: (isActionTaken || isSubmitting) ? null : () => approveOrReject(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActionTaken ? Colors.grey : Colors.green,
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white),
                                        )
                                      : const Text('Approved'),
                                ),
                                ElevatedButton(
                                  onPressed: (isActionTaken || isSubmitting) ? null : () => approveOrReject(false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActionTaken ? Colors.grey : Colors.red,
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white),
                                        )
                                      : const Text('Rejected'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}