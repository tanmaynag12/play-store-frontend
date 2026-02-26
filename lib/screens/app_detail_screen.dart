import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import '../providers/auth_provider.dart';
import 'admin_upload_screen.dart';
import 'package:play_store_app/config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  late AppModel currentApp;

  final RatingService _ratingService = RatingService();

  List<String> screenshots = [];
  bool loadingScreenshots = true;

  List<RatingModel> ratings = [];
  bool loadingRatings = true;

  RatingModel? userRating;

  bool installed = false;
  bool wishlisted = false;
  bool bookmarked = false;

  int selectedRating = 0;
  TextEditingController reviewController = TextEditingController();
  bool submittingRating = false;

  @override
  void initState() {
    super.initState();
    currentApp = widget.app;
    fetchAppDetails();
    fetchRatings();
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Future<void> fetchAppDetails() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/apps/${widget.app.id}"),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          currentApp = AppModel.fromJson(data);
          screenshots = (data["screenshots"] as List)
              .map((e) => "${ApiConfig.baseUrl}$e")
              .toList();
          loadingScreenshots = false;
        });
      } else {
        loadingScreenshots = false;
      }
    } catch (_) {
      setState(() => loadingScreenshots = false);
    }
  }

  Future<void> installApp() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/apps/${currentApp.id}/download",
    );

    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!launched) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not start download")));
      return;
    }

    await Future.delayed(const Duration(seconds: 1));
    await fetchAppDetails();
  }

  Future<void> fetchRatings() async {
    try {
      final result = await _ratingService.getRatings(currentApp.id);
      final auth = context.read<AuthProvider>();

      RatingModel? existing;

      if (auth.user?.id != null) {
        try {
          existing = result.firstWhere((r) => r.userId == auth.user!.id);
        } catch (_) {}
      }

      setState(() {
        ratings = result;
        userRating = existing;

        if (existing != null) {
          selectedRating = existing.rating;
          reviewController.text = existing.reviewText ?? "";
        }

        loadingRatings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingRatings = false);
    }
  }

  Widget _buildStarPicker() {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            starIndex <= selectedRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              selectedRating = starIndex;
            });
          },
        );
      }),
    );
  }

  Future<void> submitRating() async {
    if (selectedRating == 0) return;

    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login to rate.")));
      return;
    }

    setState(() => submittingRating = true);

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/apps/${currentApp.id}/rate"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${auth.token}",
      },
      body: jsonEncode({
        "rating": selectedRating,
        "review_text": reviewController.text.trim(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await fetchAppDetails();
      await fetchRatings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userRating != null ? "Review updated." : "Review submitted.",
          ),
        ),
      );
    }

    setState(() => submittingRating = false);
  }

  Future<void> deleteRating() async {
    final auth = context.read<AuthProvider>();

    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/api/apps/${currentApp.id}/rate"),
      headers: {"Authorization": "Bearer ${auth.token}"},
    );

    if (response.statusCode == 200) {
      await fetchAppDetails();
      await fetchRatings();

      setState(() {
        selectedRating = 0;
        reviewController.clear();
        userRating = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Review deleted.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          currentApp.name,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          if (auth.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUploadScreen(app: currentApp),
                  ),
                );

                if (result == true && mounted) {
                  fetchAppDetails();
                  fetchRatings();
                }
              },
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _leftPanel(),
                  const SizedBox(height: 40),

                  const Text(
                    "Rate this app",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _buildStarPicker(),

                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Write a review (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: submittingRating ? null : submitRating,
                    child: submittingRating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            userRating != null
                                ? "Update Review"
                                : "Submit Review",
                          ),
                  ),

                  if (userRating != null)
                    TextButton(
                      onPressed: deleteRating,
                      child: const Text(
                        "Delete Review",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 48),
                  const Divider(thickness: 1),
                  const SizedBox(height: 48),

                  _rightPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                "${ApiConfig.baseUrl}${currentApp.iconUrl}",
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentApp.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentApp.developer ?? "Unknown Developer",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Version: ${currentApp.version ?? 'N/A'}"),
                  Text("Size: ${currentApp.size ?? 'N/A'}"),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: installApp,
                    child: const Text("Install"),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: currentApp.averageRating != null
                  ? "${currentApp.averageRating}★"
                  : "0★",
              sub: "${currentApp.totalReviews} reviews",
            ),
            _StatItem(
              label: "${currentApp.downloadCount ?? 0}",
              sub: "Downloads",
            ),
            _StatItem(label: currentApp.ratedFor ?? "N/A", sub: "Rated for"),
          ],
        ),
      ],
    );
  }

  Widget _rightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Screenshots",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (loadingScreenshots)
          const CircularProgressIndicator()
        else if (screenshots.isNotEmpty)
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: screenshots.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Image.network(
                    screenshots[index],
                    width: 160,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 48),
        const Text(
          "About this app",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(currentApp.description),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String sub;

  const _StatItem({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}
