import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pos2_debug_helper.dart';

class POS2PermissionHelper {
  /// Verificar se o usuário tem permissões para usar tickets (POS2)
  static Future<bool> hasTicketPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString == null) return false;
      
      final user = jsonDecode(userString);
      final permissions = user['pos']?['permissions'];
      
      if (permissions == null) return false;
      
      // Verificar na imagem que foi anexada - o checkbox "Tickets" deve estar marcado
      // No backend, isto seria algo como permissions['tickets'] == true
      final hasTickets = permissions['tickets'] == true || permissions['tickets'] == 1;
      
      POS2DebugHelper.log('Permission Check: hasTickets = $hasTickets, permissions = $permissions');
      
      return hasTickets;
    } catch (e) {
      POS2DebugHelper.logError('Erro ao verificar permissões POS2', error: e);
      return false;
    }
  }
  
  /// Verificar permissões de extras (sistema atual)
  static Future<bool> hasExtrasPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString == null) return false;
      
      final user = jsonDecode(userString);
      final permissions = user['pos']?['permissions'];
      
      if (permissions == null) return false;
      
      // Na imagem, o checkbox "Extras" está marcado
      final hasExtras = permissions['extras'] == true || permissions['extras'] == 1;
      
      return hasExtras;
    } catch (e) {
      POS2DebugHelper.logError('Erro ao verificar permissões extras', error: e);
      return false;
    }
  }
  
  /// Decidir qual sistema usar
  static Future<String> decidePOSSystem() async {
    final hasTickets = await hasTicketPermissions();
    
    if (hasTickets) {
      POS2DebugHelper.log('✅ Usuário tem permissão para tickets - usando POS2');
      return '/pos2/modern';
    } else {
      POS2DebugHelper.log('ℹ️ Usuário sem permissão para tickets - usando sistema atual');
      return '/pos/shop';
    }
  }
  
  /// Get user data for debugging
  static Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString == null) return {};
      
      return jsonDecode(userString);
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar dados do usuário', error: e);
      return {};
    }
  }
}