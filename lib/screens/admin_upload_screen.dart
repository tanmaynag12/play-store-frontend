import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:play_store_app/config/api_config.dart';
import '../providers/auth_provider.dart';
import '../models/app_model.dart';

class AdminUploadScreen extends StatefulWidget {
  final AppModel? app; // null = create, not null = edit

  const AdminUploadScreen({super.key, this.app});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final versionController = TextEditingController();
  final sizeController = TextEditingController();
  final developerController = TextEditingController();

  File? icon;
  List<File> screenshots = [];

  final picker = ImagePicker();
  bool uploading = false;

  bool get isEdit => widget.app != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      nameController.text = widget.app!.name;
      descController.text = widget.app!.description;
      versionController.text = widget.app!.version ?? "";
      sizeController.text = widget.app!.size ?? "";
      developerController.text = widget.app!.developer ?? "";
    }
  }

  Future<void> pickImages() async {
    final pickedIcon = await picker.pickImage(source: ImageSource.gallery);
    final pickedScreens = await picker.pickMultiImage();

    if (pickedIcon != null) {
      setState(() {
        icon = File(pickedIcon.path);
        screenshots = pickedScreens.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> submit() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null) return;

    setState(() => uploading = true);

    final uri = isEdit
        ? Uri.parse("${ApiConfig.baseUrl}/api/admin/apps/${widget.app!.id}")
        : Uri.parse("${ApiConfig.baseUrl}/api/admin/apps");

    final request = http.MultipartRequest(isEdit ? "PUT" : "POST", uri);

    request.headers["Authorization"] = "Bearer $token";

    request.fields["name"] = nameController.text;
    request.fields["description"] = descController.text;
    request.fields["version"] = versionController.text;
    request.fields["size"] = sizeController.text;
    request.fields["developer"] = developerController.text;

    if (icon != null) {
      request.files.add(await http.MultipartFile.fromPath("icon", icon!.path));
    }

    for (final file in screenshots) {
      request.files.add(
        await http.MultipartFile.fromPath("screenshots", file.path),
      );
    }

    final response = await request.send();

    setState(() => uploading = false);

    if (!mounted) return;

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? "App updated successfully" : "App uploaded successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Operation failed: ${response.statusCode}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit App (Admin)" : "Upload App (Admin)"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "App Name"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: versionController,
              decoration: const InputDecoration(labelText: "Version"),
            ),
            TextField(
              controller: sizeController,
              decoration: const InputDecoration(labelText: "Size"),
            ),
            TextField(
              controller: developerController,
              decoration: const InputDecoration(labelText: "Developer"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploading ? null : pickImages,
              child: const Text("Pick Icon & Screenshots"),
            ),
            if (icon != null) const Text("New icon selected ✔"),
            if (screenshots.isNotEmpty)
              Text("${screenshots.length} new screenshots selected ✔"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploading ? null : submit,
              child: uploading
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? "Update App" : "Upload App"),
            ),
          ],
        ),
      ),
    );
  }
}
