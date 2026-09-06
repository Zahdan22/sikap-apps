import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';

class AttendanceService {
  Future<Map<String, dynamic>> _sendAttendance(
    String endpoint,
    double lat,
    double lng,
    File foto,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/attendance/$endpoint'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.files.add(await http.MultipartFile.fromPath('foto', foto.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, ...data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Gagal absen'};
    }
  }

  Future<Map<String, dynamic>> absenMasuk(double lat, double lng, File foto) {
    return _sendAttendance('masuk', lat, lng, foto);
  }

  Future<Map<String, dynamic>> absenPulang(double lat, double lng, File foto) {
    return _sendAttendance('pulang', lat, lng, foto);
  }
  Future<Map<String, dynamic>> getTodayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/attendance/today'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'ada_jadwal': false};
  }
}