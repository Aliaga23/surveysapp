class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;

  LoginResponse({required this.accessToken, required this.tokenType});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
    );
  }
}

class User {
  final String id;
  final String email;
  final String rol;
  final DateTime creadoEn;
  final String tipo;
  final String nombre;
  final String telefono;
  final String estado;

  User({
    required this.id,
    required this.email,
    required this.rol,
    required this.creadoEn,
    required this.tipo,
    required this.nombre,
    required this.telefono,
    required this.estado,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      rol: json['rol'],
      creadoEn: DateTime.parse(json['creado_en']),
      tipo: json['tipo'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      estado: json['estado'],
    );
  }
}
