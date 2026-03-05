import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/app_model.dart';
import '../config/api_config.dart';

class MyAppsScreen extends StatefulWidget {
  const MyAppsScreen({super.key});

  @override
  State<MyAppsScreen> createState() => _MyAppsScreenState();
}

class _MyAppsScreenState extends State<MyAppsScreen> {
  List<AppModel> apps = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadApps();
  }

  Future<void> loadApps() async {
    final auth = context.read<AuthProvider>();

    final data = await ApiService.fetchMyApps(auth.token!);

    setState(() {
      apps = data.map((e) => AppModel.fromJson(e)).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Apps")),
      body: apps.isEmpty
          ? const Center(child: Text("No installed apps"))
          : ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];

                return ListTile(
                  leading: Image.network(
                    "${ApiConfig.baseUrl}${app.iconUrl}",
                    width: 50,
                    height: 50,
                  ),
                  title: Text(app.name),
                  subtitle: Text("${app.downloadCount} downloads"),
                );
              },
            ),
    );
  }
}
