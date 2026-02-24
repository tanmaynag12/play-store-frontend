import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:play_store_app/config/api_config.dart';

class ApiService {
  static Future<List<dynamic>> fetchApps() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/apps'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load apps');
    }
  }
}
