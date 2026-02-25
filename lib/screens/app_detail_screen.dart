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

  bool installed = false;
  bool wishlisted = false;
  bool bookmarked = false;

  @override
  void initState() {
    super.initState();
    currentApp = widget.app;
    fetchAppDetails();
    fetchRatings();
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

  Future<void> fetchRatings() async {
    try {
      final result = await _ratingService.getRatings(currentApp.id);

      if (!mounted) return;

      setState(() {
        ratings = result;
        loadingRatings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingRatings = false);
    }
  }

  Future<void> deleteApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete App"),
        content: const Text(
          "Are you sure you want to delete this app? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/api/admin/apps/${widget.app.id}"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      Navigator.pop(context, true);
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
            IconButton(icon: const Icon(Icons.delete), onPressed: deleteApp),
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
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() => installed = !installed);
              },
              child: Text(installed ? "Uninstall" : "Install"),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                wishlisted ? Icons.favorite : Icons.favorite_border,
                color: wishlisted ? Colors.red : Colors.grey,
              ),
              onPressed: () => setState(() => wishlisted = !wishlisted),
            ),
            IconButton(
              icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => setState(() => bookmarked = !bookmarked),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: currentApp.averageRating != null
                  ? "${currentApp.averageRating}★"
                  : "0★",
              sub: "${currentApp.totalReviews} reviews",
            ),
            const _StatItem(label: "10K+", sub: "Downloads"),
            const _StatItem(label: "3+", sub: "Rated for"),
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
