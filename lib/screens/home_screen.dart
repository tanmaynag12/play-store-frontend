import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'app_detail_screen.dart';
import 'admin_upload_screen.dart';
import 'login_screen.dart';
import 'package:play_store_app/config/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppModel> apps = [];
  bool loading = true;
  String error = "";

  @override
  void initState() {
    super.initState();
    fetchApps();
  }

  Future<void> fetchApps() async {
    try {
      final data = await ApiService.fetchApps();

      if (!mounted) return;

      setState(() {
        apps = data.map((e) => AppModel.fromJson(e)).toList();
        loading = false;
        error = "";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Network error. Is backend running?";
        loading = false;
      });
    }
  }

  void _requireLogin(BuildContext context, VoidCallback action) {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: fetchApps, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: const Text("Apps"),
        actions: [
          auth.isLoggedIn
              ? PopupMenuButton(
                  icon: const Icon(Icons.account_circle),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      child: const Text('Logout'),
                      onTap: () => auth.logout(),
                    ),
                  ],
                )
              : TextButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
                );
                fetchApps();
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final deleted = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppDetailScreen(app: app),
                            ),
                          );

                          if (deleted == true) {
                            fetchApps();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Image.network(
                                "${ApiConfig.baseUrl}${app.iconUrl}",
                                height: 80,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image, size: 60),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                app.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              if (app.averageRating != null)
                                Text(
                                  "⭐ ${app.averageRating!.toStringAsFixed(1)} (${app.totalReviews} reviews)",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              else
                                const Text(
                                  "No ratings yet",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 6),
                              Text(
                                app.description,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : RefreshIndicator(
                  onRefresh: fetchApps,
                  child: ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];

                      return ListTile(
                        leading: Image.network(
                          "${ApiConfig.baseUrl}${app.iconUrl}",
                          width: 50,
                          height: 50,
                          errorBuilder: (_, _, _) => const Icon(Icons.image),
                        ),
                        title: Text(app.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (app.averageRating != null)
                              Text(
                                "⭐ ${app.averageRating!.toStringAsFixed(1)} (${app.totalReviews} reviews)",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              )
                            else
                              const Text(
                                "No ratings yet",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(app.description),
                          ],
                        ),
                        onTap: () async {
                          final deleted = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppDetailScreen(app: app),
                            ),
                          );

                          if (deleted == true) {
                            fetchApps();
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
