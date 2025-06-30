# SurveysApp 

*App móvil multiplataforma para responder y administrar **Encuestas IA Multicanal**. Construido con **Flutter 3** y pensado para funcionar *offline‑first*, escanear formularios en papel con OCR y grabar respuestas de voz.*

---

## Índice

1. [Características](#características)
2. [Capturas de pantalla](#capturas-de-pantalla)
3. [Arquitectura y stack](#arquitectura-y-stack)
4. [Estructura del proyecto](#estructura-del-proyecto)
5. [Primeros pasos](#primeros-pasos)
6. [Variables de configuración](#variables-de-configuración)
7. [Scripts útiles de Flutter](#scripts-útiles-de-flutter)

---

## Características

* **Login JWT** contra el backend SurveySaaS.
* **Dashboard dinámico** con servicios disponibles según rol (OCR, encuestas por audio, estadísticas, perfil) ([raw.githubusercontent.com](https://raw.githubusercontent.com/Aliaga23/surveysapp/main/lib/screens/dashboard_screen.dart))
* **OCR de formularios**: toma foto o selecciona imagen, envía a microservicio Whisper‑OCR y recibe JSON de respuestas. ([raw.githubusercontent.com](https://raw.githubusercontent.com/Aliaga23/surveysapp/main/lib/services/ocr_service.dart))

  * Reconoce PNG/JPG/GIF/BMP/WEBP y ajusta automáticamente el *MIME type*.
* **Encuestas por Audio**: lista campañas activas, descarga guión y graba respuesta record+WAV → envía al backend. ([raw.githubusercontent.com](https://raw.githubusercontent.com/Aliaga23/surveysapp/main/lib/screens/audio_campaigns_screen.dart))
* **Modo Offline**: caché de peticiones en SQLite; indicador de pendientes y sincronización automática al reconectar.
* **UI Material 3** personalizable (colores corporativos azul `#1565C0`).
* **Multi‑plataforma**: Android, iOS, Web, macOS, Windows y Linux.
* **100 % Flutter/Dart** con *provider* para *state‑management*.

---

## Capturas de pantalla

> *Próximamente* (sube tus screenshots a `/assets/images/` y enlázalas aquí).

---

## Arquitectura y stack

| Capa                 | Paquetes / Tecnologías                                          |
| -------------------- | --------------------------------------------------------------- |
| UI / State           | **Flutter 3**, Material, `provider`                             |
| Almacenamiento local | `shared_preferences`, `flutter_secure_storage`, `path_provider` |
| HTTP & Networking    | `http`, `http_parser`, `cached_network_image`                   |
| Multimedia           | `image_picker`, `record`, `audioplayers`                        |
| Animaciones          | `flutter_staggered_animations`, `shimmer`                       |
| Fonts & SVG          | `google_fonts`, `flutter_svg`                                   |
| Utils                | `intl`, `path`, `permission_handler`                            |

> Todas las dependencias están listadas en **pubspec.yaml**. ([raw.githubusercontent.com](https://raw.githubusercontent.com/Aliaga23/surveysapp/main/pubspec.yaml))

---

## Estructura del proyecto

```text
surveysapp/
├── android/         # Proyecto nativo Android (Gradle)
├── ios/             # Xcode / CocoaPods
├── macos/ | linux/ | windows/ | web/  # Targets de escritorio & web
├── lib/
│   ├── models/      # DTOs (Auth, Campaign, Survey, ...)
│   ├── services/    # HTTP, OCR, Audio, OfflineSync
│   ├── screens/     # UI: Login, Dashboard, OCRScreen, AudioSurveys, Profile
│   ├── widgets/     # Componentes reutilizables (cards, loadings)
│   └── main.dart    # Arranque + theming + rutas
├── assets/
│   └── images/      # Imágenes estáticas y screenshots
├── test/            # Tests unit & widget
├── pubspec.yaml     # Dependencias y configuración Flutter
└── README.md        # (este archivo)
```

---

## Primeros pasos

### 1. Pre‑requisitos

* **Flutter ≥ 3.19** (`flutter doctor` para verificar)
* Android Studio o Xcode (para compilar en dispositivos físicos o emuladores)

### 2. Clona y levanta

```bash
# Clonar
$ git clone https://github.com/Aliaga23/surveysapp.git
$ cd surveysapp

# Instalar dependencias
$ flutter pub get

# Ejecutar en dispositivo/emulador
$ flutter run -d <device>
```

### 3. Endpoints de backend

El `AuthService.baseUrl` apunta por defecto a la instancia de Railway en producción (`https://surveysbackend-production.up.railway.app`).
Si corres el backend localmente, cambia la constante en `lib/services/auth_service.dart`.

---

## Variables de configuración

| Archivo              | Clave          | Descripción                    |
| -------------------- | -------------- | ------------------------------ |
| `auth_service.dart`  | `baseUrl`      | URL del backend FastAPI        |
| `ocr_service.dart`   | `ocrUrl`       | Microservicio OCR/Whisper      |
| `audio_service.dart` | `audioBaseUrl` | Endpoints de campañas de audio |

Para **builds CI** puedes sobrescribir con `--dart-define` (ejemplo):

```bash
flutter run --dart-define=BASE_URL=https://api.miempresa.com \
           --dart-define=OCR_URL=https://ocr.miempresa.com/ocr
```

En el código lee estas variables con `const String.fromEnvironment()`.

---

## Scripts útiles de Flutter

| Comando                       | Descripción                 |
| ----------------------------- | --------------------------- |
| `flutter analyze`             | Linter con `flutter_lints`  |
| `flutter test`                | Ejecuta pruebas unit/widget |
| `flutter build apk --release` | Build Android producción    |
| `flutter build ios --release` | Build iOS (requiere Xcode)  |
| `flutter build web --release` | Build Web SPA               |

---



