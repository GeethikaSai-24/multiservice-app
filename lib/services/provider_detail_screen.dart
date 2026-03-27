import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'booking_screen.dart';
import 'package:flutter/foundation.dart'; // 🔥 IMPORTANT
import 'package:url_launcher/url_launcher.dart';

class ProviderDetailScreen extends StatefulWidget {
  final Map provider;

  const ProviderDetailScreen({super.key, required this.provider});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  List reviews = [];
  double rating = 0;
  TextEditingController reviewController = TextEditingController();

  List<String> mediaUrls = [];
  int? editingReviewId;

  final int currentUserId = 1; // TEMP USER

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  // 🔹 FETCH REVIEWS
  Future<void> fetchReviews() async {
    final response = await http.get(
      Uri.parse(
        "http://127.0.0.1:8000/api/reviews/?provider=${widget.provider['id']}",
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        reviews = jsonDecode(response.body);
      });
    }
  }

  // 🔹 ADD / UPDATE REVIEW
  Future<void> submitReview() async {
    if (rating == 0 || reviewController.text.isEmpty) return;

    final isEdit = editingReviewId != null;

    final url = isEdit
        ? "http://127.0.0.1:8000/api/reviews/$editingReviewId/update/"
        : "http://127.0.0.1:8000/api/reviews/add/";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "provider": widget.provider['id'],
        "rating": rating,
        "comment": reviewController.text,
        "user": currentUserId, // 🔥 MEDIA IN REVIEW
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        editingReviewId = null;
        rating = 0;
        reviewController.clear();
        mediaUrls.clear();
      });

      fetchReviews();
    }
  }

  // 🔹 DELETE REVIEW
  Future<void> deleteReview(int id) async {
    await http.delete(
      Uri.parse("http://127.0.0.1:8000/api/reviews/$id/delete/"),
    );

    fetchReviews();
  }

  // 🔹 EDIT REVIEW
  void editReview(Map review) {
    setState(() {
      editingReviewId = review['id'];
      rating = review['rating'].toDouble();
      reviewController.text = review['comment'];
      mediaUrls = List<String>.from(review['media'] ?? []);
    });
  }

  // 🔹 PICK IMAGE
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          mediaUrls.add("data:image/png;base64,$base64Image");
        });
      } else {
        setState(() {
          mediaUrls.add(picked.path);
        });
      }

      print("Image added. Count: ${mediaUrls.length}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final isDoctor = provider['category_name'] == "DOCTOR";
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
              // 🔵 PROVIDER IMAGE
              Container(
                width: double.infinity,
                height: 220, // 🔥 controls size
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

              Text("$location • $experience yrs"),

              const SizedBox(height: 8),
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

              // 🔵 PROVIDER GALLERY
              // 🔵 PROVIDER GALLERY
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
              // 🔵 DESCRIPTION
              const Text(
                "About",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(description),

              const SizedBox(height: 20),

              // 🔵 REVIEWS
              const Text(
                "Reviews",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Column(
                children: reviews.map((r) {
                  return Card(
                    child: ListTile(
                      title: Text(r['user_name'] ?? "User"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['comment'] ?? ""),

                          Row(
                            children: List.generate(
                              (r['rating'] ?? 0).toInt(),
                              (i) => const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ),
                          ),

                          // 🔥 REVIEW MEDIA
                          if (r['media'] != null)
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: r['media'].length,
                                itemBuilder: (context, i) {
                                  return Image.network(
                                    r['media'][i] ?? '',
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),

                      trailing: r['user'] == currentUserId
                          ? PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'edit') editReview(r);
                                if (value == 'delete') deleteReview(r['id']);
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

              // 🔵 ADD REVIEW
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
                onPressed: pickImage,
                child: const Text("Add Image"),
              ),

              // 🔥 SELECTED MEDIA PREVIEW
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaUrls.length,
                  itemBuilder: (context, i) {
                    return Stack(
                      children: [
                        kIsWeb
                            ? Image.network(
                                mediaUrls[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(mediaUrls[i]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                mediaUrls.removeAt(i);
                              });
                            },
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: submitReview,
                child: Text(
                  editingReviewId == null ? "Submit Review" : "Update Review",
                ),
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 15),

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
              // 🔵 BOOK BUTTON
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
