# FinDuo Flutter App

## Configuración inicial

1. **Instalar dependencias:**
   ```powershell
   flutter pub get
   ```

2. **Configurar URL del backend:**
   Edita `lib/config/api_config.dart`:
   - **Para emulador Android**: Usa `http://10.0.2.2:8000` (ya configurado)
   - **Para dispositivo físico**: Usa la IP local de tu PC, ejemplo: `http://192.168.1.100:8000`
     - Encuentra tu IP con: `ipconfig` (Windows) o `ifconfig` (Linux/Mac)
   - **Para producción**: Usa la URL de Railway: `https://tu-backend-finduo.up.railway.app`

## Ejecutar en Android por USB

### Requisitos previos:
1. Conecta tu dispositivo Android por USB
2. Habilita "Depuración USB" en las opciones de desarrollador
3. Acepta el diálogo de autorización de depuración USB en el dispositivo

### Pasos:

**Opción 1: Usar el script (recomendado)**
```powershell
.\run_android.ps1
```

**Opción 2: Comandos manuales**
```powershell
# Ver dispositivos conectados
flutter devices

# Ejecutar la app
flutter run

# O especificar un dispositivo específico
flutter run -d <device-id>
```

## Solución de problemas

### El dispositivo no aparece:
- Verifica que la depuración USB esté habilitada
- Prueba desconectar y reconectar el USB
- Ejecuta `flutter doctor` para diagnosticar problemas

### No se conecta al backend:
- Verifica que el backend esté corriendo localmente
- Si usas dispositivo físico, asegúrate de usar la IP local de tu PC (no localhost)
- Verifica que el dispositivo y la PC estén en la misma red WiFi
- Revisa el firewall de Windows

### Error de permisos:
- Asegúrate de haber aceptado la autorización de depuración USB en el dispositivo
- Algunos dispositivos requieren autorización cada vez que se conectan
