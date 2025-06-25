// lib/models/campaign_models.dart
class Campaign {
  final String id;
  final String nombre;
  final int canalId;
  final int estadoId;
  final String? programadaEn;   // ← nullable
  final String? creadoEn;       // ← nullable

  Campaign({
    required this.id,
    required this.nombre,
    required this.canalId,
    required this.estadoId,
    this.programadaEn,
    this.creadoEn,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id          : json['id']        as String,
    nombre      : json['nombre']    as String,
    canalId     : json['canal_id']  as int,
    estadoId    : json['estado_id'] as int,
    programadaEn: json['programada_en'] as String?,   // ← cast opcional
    creadoEn    : json['creado_en']     as String?,
  );
}


class AudioSurvey {
  final String id;
  final SurveyTemplate plantilla;
  final String? destinatario;          // ← ya era nullable
  final String? creadoEn;              // ← por si tu endpoint lo manda
  final String? respondidoEn;

  AudioSurvey({
    required this.id,
    required this.plantilla,
    this.destinatario,
    this.creadoEn,
    this.respondidoEn,
  });

  factory AudioSurvey.fromJson(Map<String, dynamic> json) => AudioSurvey(
    id           : json['id']            as String,
    plantilla    : SurveyTemplate.fromJson(json['plantilla']),
    destinatario : json['destinatario']  as String?,
    creadoEn     : json['creado_en']     as String?,
    respondidoEn : json['respondido_en'] as String?,
  );
}

class SurveyTemplate {
  final String id;
  final String nombre;
  final String? descripcion;           // ← nullable
  final List<Question> preguntas;

  SurveyTemplate({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.preguntas,
  });

  factory SurveyTemplate.fromJson(Map<String, dynamic> json) => SurveyTemplate(
    id          : json['id']       as String,
    nombre      : json['nombre']   as String,
    descripcion : json['descripcion'] as String?,   // ←
    preguntas   : (json['preguntas'] as List)
        .map((q) => Question.fromJson(q))
        .toList(),
  );
}

class Question {
  final String id;
  final int orden;
  final String texto;
  final int tipoPreguntaId;
  final bool obligatorio;
  final List<QuestionOption> opciones;

  Question({
    required this.id,
    required this.orden,
    required this.texto,
    required this.tipoPreguntaId,
    required this.obligatorio,
    required this.opciones,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      orden: json['orden'],
      texto: json['texto'],
      tipoPreguntaId: json['tipo_pregunta_id'],
      obligatorio: json['obligatorio'],
      opciones: (json['opciones'] as List)
          .map((o) => QuestionOption.fromJson(o))
          .toList(),
    );
  }
}

class QuestionOption {
  final String id;
  final String? texto;                 // ← a veces nulo según tu BD
  final String? valor;                 // ← puede ser null / int

  QuestionOption({
    required this.id,
    this.texto,
    this.valor,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
    id    : json['id']    as String,
    texto : json['texto'] as String?,
    valor : json['valor']?.toString(),               // cast seguro
  );
}
class AudioTranscriptionResponse {
  final String entregaId;
  final String transcripcion;
  final Map<String, dynamic> payloadEnviado;
  final Map<String, dynamic> respuestaBackend;

  AudioTranscriptionResponse({
    required this.entregaId,
    required this.transcripcion,
    required this.payloadEnviado,
    required this.respuestaBackend,
  });

  factory AudioTranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return AudioTranscriptionResponse(
      entregaId: json['entrega_id'],
      transcripcion: json['transcripcion'],
      payloadEnviado: json['payload_enviado'],
      respuestaBackend: json['respuesta_backend'],
    );
  }
}
