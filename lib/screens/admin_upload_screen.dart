import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

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

  Future<void> uploadApp() async {
    if (icon == null || screenshots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pick icon and screenshots first")),
      );
      return;
    }

    setState(() => uploading = true);

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://10.0.2.2:3000/api/admin/apps"),
    );

    request.headers["x-api-key"] = "apikey123";

    request.fields["name"] = nameController.text;
    request.fields["description"] = descController.text;
    request.fields["version"] = versionController.text;
    request.fields["size"] = sizeController.text;
    request.fields["developer"] = developerController.text;

    request.files.add(await http.MultipartFile.fromPath("icon", icon!.path));

    for (final file in screenshots) {
      request.files.add(
        await http.MultipartFile.fromPath("screenshots", file.path),
      );
    }

    final response = await request.send();

    setState(() => uploading = false);

    if (!mounted) return;

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("App uploaded successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload App (Admin)")),
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

            if (icon != null) const Text("Icon selected ✔"),
            if (screenshots.isNotEmpty)
              Text("${screenshots.length} screenshots selected ✔"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: uploading ? null : uploadApp,
              child: uploading
                  ? const CircularProgressIndicator()
                  : const Text("Upload App"),
            ),
          ],
        ),
      ),
    );
  }
}
