import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/chat/chat_screen.dart';
import 'api_service.dart';
import 'booking_screen.dart';
import 'session_service.dart';

class ProviderDetailScreen extends StatefulWidget {
  final Map provider;

  const ProviderDetailScreen({super.key, required this.provider});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  List reviews = [];
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();
  int? editingReviewId;
  int? currentUserId;
  String currentUsername = 'Customer';

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    fetchReviews();
  }

  Future<void> loadCurrentUser() async {
    final currentUser = await SessionService.getCurrentUser();
    if (!mounted || currentUser == null) return;

    setState(() {
      currentUserId = currentUser['id'] as int?;
      currentUsername = currentUser['name']?.toString().isNotEmpty == true
          ? currentUser['name'].toString()
          : currentUser['username']?.toString() ?? 'Customer';
    });
  }

  Future<void> fetchReviews() async {
    final response = await ApiService.get(
      "/api/reviews/?provider=${widget.provider['id']}",
    );

    if (response.statusCode == 200) {
      setState(() {
        reviews = jsonDecode(response.body);
      });
    }
  }

  Future<void> submitReview() async {
    if (rating == 0 || reviewController.text.trim().isEmpty) return;

    final payload = {
      "provider": widget.provider['id'],
      "rating": rating,
      "comment": reviewController.text.trim(),
    };

    final response = editingReviewId != null
        ? await ApiService.putAuthenticated(
            "/api/reviews/$editingReviewId/update/",
            body: payload,
          )
        : await ApiService.postAuthenticated("/api/reviews/add/", body: payload);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        editingReviewId = null;
        rating = 0;
        reviewController.clear();
      });
      fetchReviews();
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error['detail'] ?? error['error'] ?? 'Unable to submit review',
          ),
        ),
      );
    }
  }

  Future<void> deleteReview(int id) async {
    await ApiService.deleteAuthenticated("/api/reviews/$id/delete/");
    fetchReviews();
  }

  void editReview(Map review) {
    setState(() {
      editingReviewId = review['id'];
      rating = (review['rating'] ?? 0).toDouble();
      reviewController.text = review['comment'] ?? '';
    });
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final name = provider['name'] ?? "No Name";
    final location = provider['location'] ?? "Location not available";
    final experience = provider['experience_years'] ?? 0;
    final ratingValue = provider['rating'] ?? 0;
    final description = provider['description'] ?? "No description available";
    final heroImage = provider['hero_image'];
    final mediaList = provider['media'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: heroImage != null
                      ? Image.network(
                          heroImage,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, 0.3),
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image, size: 50),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 80),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                provider['name'] ?? "",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('$location - $experience yrs'),
              const SizedBox(height: 10),
              Text(
                "Contact: ${provider['phone_number'] ?? 'Not available'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange),
                  Text("$ratingValue"),
                ],
              ),
              const SizedBox(height: 16),
              if (mediaList.isNotEmpty) ...[
                const Text(
                  "Gallery",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mediaList.length,
                    itemBuilder: (context, i) {
                      final item = mediaList[i];

                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[300],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item['file'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                "About",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(description),
              const SizedBox(height: 20),
              const Text(
                "Reviews",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Column(
                children: reviews.map((review) {
                  return Card(
                    child: ListTile(
                      title: Text(review['user_name'] ?? "User"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review['comment'] ?? ""),
                          Row(
                            children: List.generate(
                              (review['rating'] ?? 0).toInt(),
                              (i) => const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: review['user'] == currentUserId
                          ? PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'edit') editReview(review);
                                if (value == 'delete') {
                                  deleteReview(review['id']);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text("Edit"),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text("Delete"),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                "Add Review",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                  );
                }),
              ),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(hintText: "Write review"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: submitReview,
                child: Text(
                  editingReviewId == null ? "Submit Review" : "Update Review",
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final phone = provider['phone_number'];

                    if (phone == null || phone.toString().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No contact available")),
                      );
                      return;
                    }

                    final uri = Uri.parse("tel:$phone");

                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.call),
                  label: const Text("Call Provider"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: currentUserId == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                providerId: provider['id'],
                                providerName: provider['name'] ?? 'Provider',
                                customerId: currentUserId!,
                                customerName: currentUsername,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat With Provider"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                          providerId: provider['id'],
                          providerName: provider['name'],
                          isDoctor:
                              provider['category_name'] != null &&
                              provider['category_name']
                                  .toString()
                                  .replaceAll(RegExp(r'[^a-zA-Z]'), '')
                                  .toUpperCase()
                                  .contains('DOCTOR'),
                        ),
                      ),
                    );
                  },
                  child: const Text("Book Now"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
