import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:5000/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "message": message,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "No reply from backend.";
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Connection error: $e";
    }
  }
}
