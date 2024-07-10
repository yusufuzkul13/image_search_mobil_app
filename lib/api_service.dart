import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String url = "https://picarta.ai/classify";
  static const String apiToken =
      "NOEUL5SXWU8W9BWMBP81"; // Replace with your API token

  /**
   * Use this method to get mock data for example.
   */
  Future<Map<String, dynamic>> classifyImageMock(Uint8List imageData) async {
    return Future.value(jsonDecode(
        "{\"ai_confidence\":0.12877894937992096,\"ai_country\":\"Japan\",\"ai_lat\":35.88306695439695,\"ai_lon\":139.81819617247422,\"camera_maker\":null,\"camera_model\":null,\"city\":\"Yoshikawa\",\"province\":\"Saitama\",\"timestamp\":null,\"topk_predictions_dict\":{\"1\":{\"address\":{\"city\":\"Yoshikawa\",\"country\":\"Japan\",\"province\":\"Saitama\"},\"confidence\":0.12877894937992096,\"gps\":[35.88306695439695,139.81819617247422]},\"2\":{\"address\":{\"city\":\"Sunshine North\",\"country\":\"Australia\",\"province\":\"Victoria\"},\"confidence\":0.10975244641304016,\"gps\":[-37.76406576096502,144.81579973250263]},\"3\":{\"address\":{\"city\":\"Wako\",\"country\":\"Japan\",\"province\":\"Saitama\"},\"confidence\":0.0687853991985321,\"gps\":[35.81309865912471,139.64389751856444]}}}"));
  }

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
