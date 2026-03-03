// ignore_for_file: unnecessary_underscores, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'app_detail_screen.dart';
import 'admin_upload_screen.dart';
import 'login_screen.dart';
import 'package:play_store_app/config/api_config.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _debounce;
  List<AppModel> apps = [];
  bool loading = true;
  String error = "";

  @override
  void initState() {
    super.initState();
    fetchApps();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchApps({String? query}) async {
    try {
      final data = await ApiService.fetchApps(search: query);

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

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        fetchApps();
      } else {
        fetchApps(query: value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: fetchApps, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 30,
          title: Row(
            children: [
              const Icon(Icons.store, color: Colors.green, size: 26),
              const SizedBox(width: 10),
              const Text(
                "BOCK STORE",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search apps...",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            auth.isLoggedIn
                ? PopupMenuButton(
                    icon: const Icon(Icons.account_circle, color: Colors.black),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        child: const Text('Logout'),
                        onTap: () => auth.logout(),
                      ),
                    ],
                  )
                : TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            if (auth.isAdmin)
              IconButton(
                icon: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.black,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminUploadScreen(),
                    ),
                  );
                  fetchApps();
                },
              ),
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: isDesktop
              ? GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 1500
                        ? 5
                        : width > 1200
                        ? 4
                        : 3,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 30,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 20,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      color: Colors.grey.shade100,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: Image.network(
                                        "${ApiConfig.baseUrl}${app.iconUrl}",
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.image, size: 40),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    app.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  if (app.averageRating != null)
                                    Text(
                                      "⭐ ${app.averageRating!.toStringAsFixed(1)}  (${app.totalReviews})",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    )
                                  else
                                    const Text(
                                      "No ratings yet",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: Text(
                                      app.description,
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : RefreshIndicator(
                  onRefresh: fetchApps,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              "${ApiConfig.baseUrl}${app.iconUrl}",
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                            ),
                          ),
                          title: Text(app.name),
                          subtitle: Text(
                            app.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
