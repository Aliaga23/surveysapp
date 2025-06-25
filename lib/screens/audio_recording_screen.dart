import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/campaign_models.dart';
import '../services/audio_service.dart';

class AudioRecordingScreen extends StatefulWidget {
  final AudioSurvey survey;
  final int surveyNumber;

  const AudioRecordingScreen({
    super.key,
    required this.survey,
    required this.surveyNumber,
  });

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioService _audioService = AudioService();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  bool _isProcessing = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestPermissions();
    _setupAudioPlayer();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _playbackDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _playbackPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await Permission.microphone.isGranted;
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requiere permiso de micrófono'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${widget.survey.id}.wav';
      final filePath = '${directory.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingPath = filePath;
        _recordingDuration = Duration.zero;
      });

      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar grabación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });

      _pulseController.stop();
      _waveController.stop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al detener grabación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
      return _isRecording;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordingPath!));
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reproducir audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendRecording() async {
    if (_recordingPath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final audioFile = File(_recordingPath!);
      final response = await _audioService.transcribeAudio(
        widget.survey.id,
        audioFile,
      );

      if (mounted) {
        _showTranscriptionResult(response);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showTranscriptionResult(AudioTranscriptionResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Transcripción Completada'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Transcripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  response.transcripcion,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Respuestas procesadas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (response.payloadEnviado['respuestas_preguntas'] != null)
                ...((response.payloadEnviado['respuestas_preguntas'] as List)
                    .map((respuesta) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${respuesta['texto'] ?? respuesta['numero'] ?? 'Opción seleccionada'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _resetRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
      _playbackDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _isPlaying = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encuesta ${widget.surveyNumber}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Información de la encuesta
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.survey.plantilla.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.survey.plantilla.descripcion?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Preguntas: ${widget.survey.plantilla.preguntas.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Área de grabación centrada (ocupa el espacio principal)
              Expanded(
                flex: 3,
                child: _buildRecordingArea(),
              ),

              // Controles en la parte inferior
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Micrófono animado centrado
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : const Color(0xFF1565C0),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : const Color(0xFF1565C0))
                              .withOpacity(0.3),
                          blurRadius: 25,
                          spreadRadius: _isRecording ? 15 : 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Estado y duración centrados
          Text(
            _isRecording
                ? 'Grabando...'
                : _hasRecording
                ? 'Grabación lista'
                : 'Toca para grabar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _isRecording ? Colors.red : const Color(0xFF1565C0),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _formatDuration(_recordingDuration),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),

          // Ondas de sonido animadas centradas
          if (_isRecording)
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 24),
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (index) {
                      final delay = index * 0.15;
                      final animationValue = (_waveAnimation.value + delay) % 1.0;
                      return Container(
                        width: 5,
                        height: 15 + (25 * animationValue),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_isProcessing) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Procesando audio...'),
        ],
      );
    }

    if (!_hasRecording) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Reproductor
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _playRecording,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _playbackDuration.inMilliseconds > 0
                                ? _playbackPosition.inMilliseconds /
                                _playbackDuration.inMilliseconds
                                : 0.0,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_playbackPosition),
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                _formatDuration(_playbackDuration),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetRecording,
                icon: const Icon(Icons.refresh),
                label: const Text('Grabar de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sendRecording,
                icon: const Icon(Icons.send),
                label: const Text('Enviar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
