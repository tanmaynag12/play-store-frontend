import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';
import 'package:play_store_app/config/api_config.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  List<String> screenshots = [];
  bool loadingScreenshots = true;

  bool installed = false;
  bool wishlisted = false;
  bool bookmarked = false;

  @override
  void initState() {
    super.initState();
    fetchScreenshots();
  }

  Future<void> fetchScreenshots() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/apps/${widget.app.id}"),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
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

  Future<void> deleteApp() async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/api/admin/apps/${widget.app.id}"),
      headers: {"x-api-key": "apikey123"},
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete app")));
    }
  }

  void fakeInstall() {
    setState(() => installed = !installed);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          installed ? "Installing... (demo only)" : "Uninstalled (demo only)",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.app.name,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: deleteApp),
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
                "${ApiConfig.baseUrl}${widget.app.iconUrl}",
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 100),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.app.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.app.developer ?? "Unknown Developer",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Version: ${widget.app.version ?? 'N/A'}"),
                  Text("Size: ${widget.app.size ?? 'N/A'}"),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: fakeInstall,
              child: Text(
                installed ? "Uninstall" : "Install",
                style: const TextStyle(fontSize: 16),
              ),
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
              icon: Icon(
                bookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => bookmarked = !bookmarked),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _StatItem(label: "4.5★", sub: "1K reviews"),
            _StatItem(label: "10K+", sub: "Downloads"),
            _StatItem(label: "3+", sub: "Rated for"),
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
          const Center(child: CircularProgressIndicator())
        else if (screenshots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "No screenshots available",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 48),

        const Text(
          "About this app",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(widget.app.description, style: const TextStyle(fontSize: 16)),
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
