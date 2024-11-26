import 'package:flutter/services.dart';

class ApiKeyProvider {
  static const _channel = MethodChannel('com.example.genie/api_key');

  static Future<String?> getApiKey() async {
    try {
      final apiKey = await _channel.invokeMethod<String>('getApiKey');
      return apiKey;
    } catch (e) {
      print("Failed to get API key: $e");
      return null;
    }
  }
}
