import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _selectedImage;
  Map<String, dynamic>? _ocrResult;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90, // Aumentar calidad para mejor OCR
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _ocrResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _ocrResult = null;
    });

    final result = await _ocrService.processImage(_selectedImage!);

    setState(() {
      _isProcessing = false;
      _ocrResult = result;
    });

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la imagen. '),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Imagen procesada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seleccionar Imagen',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    isTablet: isTablet,
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galería',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    isTablet: isTablet,
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 24 : 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: isTablet ? 48 : 40,
              color: const Color(0xFF1565C0),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOCRResultCard(Map<String, dynamic> result, bool isTablet) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Color(0xFF1565C0),
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Resultado del Procesamiento OCR',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),

            // Información de la entrega
            if (result['entrega_id'] != null) ...[
              _buildInfoSection(
                'ID de Entrega',
                result['entrega_id'].toString(),
                isTablet,
              ),
              SizedBox(height: isTablet ? 16 : 12),
            ],

            // Respuestas procesadas
            if (result['ocr_result'] != null &&
                result['ocr_result']['respuestas_preguntas'] != null) ...[
              Text(
                'Respuestas Detectadas:',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1565C0),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),

              ...List.generate(
                result['ocr_result']['respuestas_preguntas'].length,
                    (index) {
                  final respuesta = result['ocr_result']['respuestas_preguntas'][index];
                  return Container(
                    margin: EdgeInsets.only(bottom: isTablet ? 12.0 : 8.0),
                    padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respuesta ${index + 1}',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isTablet ? 8 : 4),
                        if (respuesta['texto'] != null)
                          Text('Texto: ${respuesta['texto']}'),
                        if (respuesta['numero'] != null)
                          Text('Número: ${respuesta['numero']}'),
                        if (respuesta['opcion_id'] != null)
                          Text('Opción ID: ${respuesta['opcion_id']}'),
                        Text('Tipo: ${respuesta['tipo_pregunta_id']}'),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 16 : 12),
            ],

            // Plantilla usada
            if (result['plantilla_usada'] != null) ...[
              Text(
                'Plantilla Utilizada:',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1565C0),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),

              if (result['plantilla_usada']['preguntas'] != null)
                ...List.generate(
                  result['plantilla_usada']['preguntas'].length,
                      (index) {
                    final pregunta = result['plantilla_usada']['preguntas'][index];
                    return Container(
                      margin: EdgeInsets.only(bottom: isTablet ? 8.0 : 6.0),
                      padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pregunta['orden']}. ${pregunta['texto']}',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (pregunta['opciones'] != null &&
                              pregunta['opciones'].isNotEmpty) ...[
                            SizedBox(height: isTablet ? 6 : 4),
                            ...List.generate(
                              pregunta['opciones'].length,
                                  (optIndex) {
                                final opcion = pregunta['opciones'][optIndex];
                                return Padding(
                                  padding: EdgeInsets.only(left: isTablet ? 16.0 : 12.0),
                                  child: Text(
                                    '• ${opcion['texto']}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],

            // URL de la imagen procesada
            if (result['image_url'] != null) ...[
              SizedBox(height: isTablet ? 16 : 12),
              _buildInfoSection(
                'Imagen Procesada',
                result['image_url'].toString(),
                isTablet,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1565C0),
          ),
        ),
        SizedBox(height: isTablet ? 6 : 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesamiento OCR'),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 800 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del servicio
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.document_scanner,
                        size: isTablet ? 64 : 48,
                        color: const Color(0xFF1565C0),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        'Procesamiento OCR Inteligente',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        'Selecciona una imagen de encuesta para extraer y procesar automáticamente las respuestas usando IA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),

              // Imagen seleccionada
              if (_selectedImage != null) ...[
                Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: isTablet ? 300 : 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),
              ],

              // Botones de acción
              SizedBox(
                height: isTablet ? 56 : 48,
                child: ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(
                    _selectedImage == null
                        ? 'Seleccionar Imagen'
                        : 'Cambiar Imagen',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
              ),

              if (_selectedImage != null) ...[
                SizedBox(height: isTablet ? 16 : 12),
                SizedBox(
                  height: isTablet ? 56 : 48,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    icon: _isProcessing
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.analytics),
                    label: Text(
                      _isProcessing ? 'Procesando...' : 'Procesar con OCR',
                      style: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                  ),
                ),
              ],

              // Resultado OCR
              if (_ocrResult != null) ...[
                SizedBox(height: isTablet ? 24 : 20),
                _buildOCRResultCard(_ocrResult!, isTablet),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
