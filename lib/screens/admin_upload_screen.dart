import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:play_store_app/config/api_config.dart';
import '../providers/auth_provider.dart';
import '../models/app_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class AdminUploadScreen extends StatefulWidget {
  final AppModel? app;

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
  final ratedForController = TextEditingController();
  final packageController = TextEditingController();

  PlatformFile? iconFile;
  List<PlatformFile> screenshotFiles = [];
  PlatformFile? apkFile;

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
      ratedForController.text = widget.app!.ratedFor ?? "";
      packageController.text = widget.app!.packageName;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    versionController.dispose();
    sizeController.dispose();
    developerController.dispose();
    ratedForController.dispose();
    packageController.dispose();
    super.dispose();
  }

  Future<void> pickIcon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        iconFile = result.files.first;
      });
    }
  }

  Future<void> pickScreenshots() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        screenshotFiles = result.files;
      });
    }
  }

  Future<void> pickApk() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        apkFile = result.files.first;
      });
    }
  }

  Future<void> submit() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    if (packageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Package name is required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
    request.fields["rated_for"] = ratedForController.text;
    request.fields["package_name"] = packageController.text;
    request.fields["version_code"] = "1";

    if (iconFile != null) {
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "icon",
            iconFile!.bytes!,
            filename: iconFile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath("icon", iconFile!.path!),
        );
      }
    }

    for (final file in screenshotFiles) {
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "screenshots",
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath("screenshots", file.path!),
        );
      }
    }

    if (apkFile != null) {
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "apk",
            apkFile!.bytes!,
            filename: apkFile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath("apk", apkFile!.path!),
        );
      }
    }
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    setState(() => uploading = false);

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
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
      String message = "Operation failed";

      try {
        final data = json.decode(responseBody);
        message = data["error"] ?? message;
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: width > 900 ? 800 : double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 25,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_upload,
                      color: Colors.green,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? "Edit App (Admin)" : "Upload App (Admin)",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: nameController,
                  decoration: _inputDecoration("App Name"),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: descController,
                  decoration: _inputDecoration("Description"),
                  maxLines: 3,
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: versionController,
                        decoration: _inputDecoration("Version"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: sizeController,
                        decoration: _inputDecoration("Size"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: developerController,
                  decoration: _inputDecoration("Developer"),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: ratedForController,
                  decoration: _inputDecoration("Rated For (e.g. 3+, 12+)"),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: packageController,
                  decoration: _inputDecoration(
                    "Package Name (e.g. org.fdroid.fdroid)",
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),

                const Text(
                  "Assets",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: _buttonStyle(),
                        onPressed: uploading ? null : pickIcon,
                        child: const Text("Pick Icon"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: _buttonStyle(),
                        onPressed: uploading ? null : pickScreenshots,
                        child: const Text("Pick Screenshots"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  style: _buttonStyle(),
                  onPressed: uploading ? null : pickApk,
                  child: const Text("Pick APK"),
                ),

                const SizedBox(height: 12),

                if (iconFile != null)
                  const Text(
                    "✔ New icon selected",
                    style: TextStyle(color: Colors.green),
                  ),

                if (screenshotFiles.isNotEmpty)
                  Text(
                    "✔ ${screenshotFiles.length} screenshots selected",
                    style: const TextStyle(color: Colors.green),
                  ),

                if (apkFile != null)
                  const Text(
                    "✔ APK selected",
                    style: TextStyle(color: Colors.green),
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: _buttonStyle(),
                    onPressed: uploading ? null : submit,
                    child: uploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? "Update App" : "Upload App",
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
