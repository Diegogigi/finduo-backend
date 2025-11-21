import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/duo_service.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = DuoService();
  final _transactionService = TransactionService();
  String? _name;
  String? _email;
  String? _inviteCode;
  String? _role;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userInfo = await _service.fetchMe();
      setState(() {
        _name = userInfo.name;
        _email = userInfo.email;
        _inviteCode = userInfo.duo?.inviteCode;
        _role = userInfo.duo?.role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncData() async {
    if (!mounted) return;
    
    // Mostrar mensaje de inicio con indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Sincronizando correo...'),
          ],
        ),
        duration: Duration(seconds: 60),
      ),
    );

    try {
      print('Iniciando sincronización...');
      // Sincronizar en modo individual (puedes cambiarlo según necesites)
      final imported = await _transactionService.syncEmail(mode: 'individual');
      
      if (!mounted) return;
      
      // Cerrar el SnackBar anterior
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Mostrar mensaje de éxito con cantidad de correos importados
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Sincronización completada\n$imported correo(s) importado(s)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      
      print('Sincronización completada exitosamente. Importados: $imported');
    } catch (e) {
      print('Error en _syncData: $e');
      
      if (!mounted) return;
      
      // Cerrar el SnackBar anterior
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Mostrar mensaje de error con más detalles
      String errorMessage = 'Error al sincronizar';
      if (e.toString().contains('Timeout')) {
        errorMessage = 'La sincronización está tomando demasiado tiempo. Intenta de nuevo.';
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
        errorMessage = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _createInvite() async {
    try {
      setState(() => _isLoading = true);
      final code = await _service.createInvite();
      setState(() {
        _inviteCode = code;
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de invitación creado')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      _buildUserInfo(),
                      const SizedBox(height: 24),
                      if (_inviteCode != null || _role != null) ...[
                        _buildDuoSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildActions(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFE3ECFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              'F',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: Color(0xFF2255FF),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name ?? 'Usuario',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email ?? 'diegogigi@gmail.com',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.email_outlined, 'Correo', _email ?? 'diegogigi@gmail.com'),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, 'Nombre', _name ?? 'Usuario FinDuo'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2255FF)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2255FF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFF2255FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'FinDuo en Pareja',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_role != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _role == 'owner' 
                        ? const Color(0xFF2255FF).withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _role == 'owner' ? 'Creador' : 'Pareja',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _role == 'owner' 
                          ? const Color(0xFF2255FF)
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_inviteCode != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Código de invitación',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _inviteCode!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Código copiado al portapapeles'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createInvite,
              icon: const Icon(Icons.add),
              label: const Text('Crear código de invitación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2255FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuenta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.edit_outlined,
          title: 'Editar perfil',
          subtitle: 'Cambiar nombre y correo',
          onTap: _editProfile,
        ),
        const SizedBox(height: 8),
        _actionTile(
          icon: Icons.sync_rounded,
          title: 'Sincronizar datos',
          subtitle: 'Actualizar transacciones desde el correo',
          onTap: _syncData,
        ),
        const SizedBox(height: 24),
        const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.notifications_outlined,
          title: 'Notificaciones',
          subtitle: 'Gestionar alertas y recordatorios',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad próximamente disponible')),
            );
          },
        ),
        const SizedBox(height: 8),
        _actionTile(
          icon: Icons.lock_outline,
          title: 'Privacidad y seguridad',
          subtitle: 'Configurar privacidad de datos',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad próximamente disponible')),
            );
          },
        ),
        const SizedBox(height: 8),
        _actionTile(
          icon: Icons.language_outlined,
          title: 'Idioma',
          subtitle: 'Español',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad próximamente disponible')),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Información',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.help_outline,
          title: 'Ayuda y soporte',
          subtitle: 'Preguntas frecuentes y contacto',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Ayuda y Soporte'),
                content: const Text(
                  '¿Necesitas ayuda?\n\n'
                  'Para soporte técnico, contacta a:\n'
                  'soporte@finduo.app\n\n'
                  'O visita nuestra documentación en GitHub.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _actionTile(
          icon: Icons.info_outline_rounded,
          title: 'Acerca de FinDuo',
          subtitle: 'Versión 0.1.0',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('FinDuo'),
                content: const Text(
                  'Control de gastos individual y en pareja.\n\n'
                  'Versión: 0.1.0\n'
                  'Desarrollado con Flutter y FastAPI\n\n'
                  '© 2025 FinDuo',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _actionTile(
          icon: Icons.logout_outlined,
          title: 'Cerrar sesión',
          subtitle: 'Salir de tu cuenta',
          onTap: _showLogoutDialog,
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              enabled: false, // El correo no se puede cambiar por ahora
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2255FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Por ahora solo actualizamos localmente
      // En el futuro se conectará con el backend
      setState(() {
        _name = nameController.text.trim();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Perfil actualizado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authService = AuthService();
                await authService.logout();
                if (!mounted) return;
                
                // Limpiar todo el stack de navegación y volver al LoginScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cerrar sesión: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.shade50
              : const Color(0xFFF1F4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF2255FF),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDestructive ? Colors.red.shade700 : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

