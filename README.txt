# FinDuo - Backend + Flutter App (MVP)

Este zip contiene:

- `finduo_backend/`: Backend en FastAPI + SQLite (listo para subir a Railway).
- `finduo_app/`: Código principal de Flutter (carpeta `lib/` y `pubspec.yaml`).

## Backend

1. Crear entorno:

```bash
cd finduo_backend
python -m venv .venv
source .venv/bin/activate  # en Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

2. Configurar variables de entorno para el correo:

```bash
export EMAIL_USER="tu_correo@gmail.com"
export EMAIL_PASSWORD="tu_app_password_o_clave"
```

3. Ejecutar servidor local:

```bash
uvicorn app.main:app --reload
```

4. Probar:

- http://localhost:8000/health
- http://localhost:8000/transactions

Para Railway, simplemente conecta tu repo y usa el `Dockerfile`.

## Flutter

1. Crea un nuevo proyecto base (si quieres estructura completa de Android/iOS):

```bash
flutter create finduo_app
```

2. Reemplaza el `pubspec.yaml` y la carpeta `lib/` generadas por las que vienen en este zip.

3. Edita `lib/config/api_config.dart` y pon la URL real del backend:

```dart
class ApiConfig {
  static const String baseUrl = 'https://TU-PROYECTO.up.railway.app';
}
```

4. Corre la app:

```bash
cd finduo_app
flutter pub get
flutter run
```

Conecta tu celular Android por USB para instalarla.

Esto es un MVP; faltan detalles de autenticación real, manejo de errores avanzado y parsing más robusto de correos, pero te deja la base funcional de FinDuo.
