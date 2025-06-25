import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class OCRService {
  static const String ocrUrl = 'https://ocr-micro.up.railway.app/ocr';

  Future<Map<String, dynamic>?> processImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ocrUrl));

      // Headers
      request.headers['accept'] = 'application/json';

      // Obtener la extensión del archivo
      String fileName = path.basename(imageFile.path);
      String fileExtension = path.extension(fileName).toLowerCase();

      // Determinar el tipo MIME correcto
      String mimeType;
      switch (fileExtension) {
        case '.png':
          mimeType = 'image/png';
          break;
        case '.jpg':
        case '.jpeg':
          mimeType = 'image/jpeg';
          break;
        case '.gif':
          mimeType = 'image/gif';
          break;
        case '.bmp':
          mimeType = 'image/bmp';
          break;
        case '.webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Por defecto
      }

      // Crear el archivo multipart con el tipo MIME correcto
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: fileName,
        // Especificar el tipo de contenido
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      print('Enviando archivo: $fileName');
      print('Tipo MIME: $mimeType');
      print('Tamaño: ${await imageFile.length()} bytes');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Código de respuesta: ${response.statusCode}');
      print('Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print('Error en OCR: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error procesando imagen: $e');
      return null;
    }
  }
}
