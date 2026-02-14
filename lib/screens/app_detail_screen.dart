import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';

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
        Uri.parse("http://10.0.2.2:3000/api/apps/${widget.app.id}"),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          screenshots = (data["screenshots"] as List)
              .map((e) => "http://10.0.2.2:3000$e")
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
      Uri.parse("http://10.0.2.2:3000/api/admin/apps/${widget.app.id}"),
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
      appBar: AppBar(
        title: Text(widget.app.name),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: deleteApp),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "http://10.0.2.2:3000${widget.app.iconUrl}",
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image, size: 80),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.app.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(widget.app.developer ?? "Unknown Developer"),
                      const SizedBox(height: 8),
                      Text("Version: ${widget.app.version ?? 'N/A'}"),
                      Text("Size: ${widget.app.size ?? 'N/A'}"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: fakeInstall,
                    child: Text(installed ? "Uninstall" : "Install"),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    wishlisted ? Icons.favorite : Icons.favorite_border,
                    color: wishlisted ? Colors.red : null,
                  ),
                  onPressed: () {
                    setState(() => wishlisted = !wishlisted);
                  },
                ),
                IconButton(
                  icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  onPressed: () {
                    setState(() => bookmarked = !bookmarked);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Screenshots",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (loadingScreenshots)
              const Center(child: CircularProgressIndicator())
            else if (screenshots.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: screenshots.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          screenshots[index],
                          width: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Text("No screenshots available"),

            const SizedBox(height: 24),

            const Text(
              "About this app",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.app.description),
          ],
        ),
      ),
    );
  }
}
