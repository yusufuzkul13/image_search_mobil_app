import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String url = "https://picarta.ai/classify";
  static const String apiToken =
      "NOEUL5SXWU8W9BWMBP81"; // Replace with your API token

  Future<Map<String, dynamic>> classifyImage(Uint8List imageData) async {
    String imgPath = base64Encode(imageData);

    Map<String, dynamic> payload = {
      "TOKEN": apiToken,
      "IMAGE": imgPath,
      "TOP_K": 3,
      "Center_LATITUDE": null,
      "Center_LONGITUDE": null,
      "RADIUS": null,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Request failed with status code: ${response.statusCode}");
    }
  }
}
