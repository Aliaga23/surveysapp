import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campaign_models.dart';
import 'package:http_parser/http_parser.dart';

class AudioService {
  static const String baseUrl = 'https://surveysbackend-production.up.railway.app';
  static const String sttUrl = 'https://sttopenai-production.up.railway.app';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<Campaign>> getAudioCampaigns() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/campanas'),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Filtrar solo las campañas de audio (canal_id = 5)
      final audioCampaigns = data
          .where((campaign) => campaign['canal_id'] == 5)
          .map((campaign) => Campaign.fromJson(campaign))
          .toList();
      return audioCampaigns;
    } else {
      throw Exception('Failed to load campaigns: ${response.statusCode}');
    }
  }

  Future<List<AudioSurvey>> getAudioSurveys(String campaignId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/public/entregas/audio?campana_id=$campaignId'),
      headers: {
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((survey) => AudioSurvey.fromJson(survey)).toList();
    } else {
      throw Exception('Failed to load audio surveys: ${response.statusCode}');
    }
  }

  Future<AudioTranscriptionResponse> transcribeAudio(String entregaId, File audioFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$sttUrl/stt'),
      );

      request.headers.addAll({
        'accept': 'application/json',
      });

      // Crear el archivo con el nombre de la entrega_id y especificar el tipo MIME correcto
      final fileName = '$entregaId.wav';

      // Leer los bytes del archivo
      final bytes = await audioFile.readAsBytes();

      // Crear el MultipartFile con el tipo de contenido específico
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType('audio', 'wav'), // Especificar tipo MIME correcto
        ),
      );

      print('Enviando audio para transcripción...');
      print('Archivo: $fileName');
      print('Tamaño: ${bytes.length} bytes');
      print('Content-Type: audio/wav');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Respuesta STT: ${response.statusCode}');
      print('Cuerpo: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AudioTranscriptionResponse.fromJson(data);
      } else {
        throw Exception('Error en transcripción: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en transcribeAudio: $e');
      throw Exception('Error al transcribir audio: $e');
    }
  }
}
