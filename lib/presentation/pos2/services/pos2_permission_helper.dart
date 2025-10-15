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
      final pos = user['pos'];
      if (pos == null) return false;
      
      // IMPORTANTE: Campo é "permission" (singular)
      final permissions = pos['permission'] ?? pos['permissions'];
      
      if (permissions == null) return false;
      
      final hasTickets = permissions['tickets'] == true || permissions['tickets'] == 1;
      
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
      final pos = user['pos'];
      if (pos == null) return false;
      
      final permissions = pos['permission'] ?? pos['permissions'];
      
      if (permissions == null) return false;
      
      // Na imagem, o checkbox "Extras" está marcado
      final hasExtras = permissions['extras'] == true || permissions['extras'] == 1;
      
      return hasExtras;
    } catch (e) {
      POS2DebugHelper.logError('Erro ao verificar permissões extras', error: e);
      return false;
    }
  }
  
  /// Verificar permissão de scanner
  static Future<bool> hasScanPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString == null) return false;
      
      final user = jsonDecode(userString);
      final pos = user['pos'];
      if (pos == null) return false;
      
      final permissions = pos['permission'] ?? pos['permissions'];
      
      if (permissions == null) return false;
      
      final hasScan = permissions['scan'] == true || permissions['scan'] == 1;
      
      return hasScan;
    } catch (e) {
      POS2DebugHelper.logError('Erro ao verificar permissão scan', error: e);
      return false;
    }
  }
  
  /// Verificar permissão de relatórios/vendas recentes
  static Future<bool> hasReportPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString == null) return false;
      
      final user = jsonDecode(userString);
      final pos = user['pos'];
      if (pos == null) return false;
      
      final permissions = pos['permission'] ?? pos['permissions'];
      
      if (permissions == null) return false;
      
      final hasReport = permissions['report'] == true || permissions['report'] == 1;
      
      return hasReport;
    } catch (e) {
      POS2DebugHelper.logError('Erro ao verificar permissão report', error: e);
      return false;
    }
  }
  
  /// Verificar permissão de withdraw (levantar extras automaticamente ao vender)
  static Future<bool> hasWithdrawPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString == null) return false;
      
      final user = jsonDecode(userString);
      final pos = user['pos'];
      if (pos == null) return false;
      
      final permissions = pos['permission'] ?? pos['permissions'];
      
      if (permissions == null) return false;
      
      final hasWithdraw = permissions['withdraw'] == true || permissions['withdraw'] == 1;
      
      return hasWithdraw;
    } catch (e) {
      POS2DebugHelper.logError('Erro ao verificar permissão withdraw', error: e);
      return false;
    }
  }
  
  /// Obter todas as permissions de uma vez (cache para performance)
  static Future<Map<String, bool>> getAllPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString == null) {
        return {
          'tickets': false,
          'extras': false,
          'scan': false,
          'report': false,
          'withdraw': false,
        };
      }
      
      final user = jsonDecode(userString);
      
      // CORRIGIDO: Permissions vêm do POS, não do user diretamente
      final pos = user['pos'];
      
      if (pos == null) {
        return {
          'tickets': false,
          'extras': false,
          'scan': false,
          'report': false,
          'withdraw': false,
        };
      }
      
      // IMPORTANTE: O campo é "permission" (singular), não "permissions" (plural)!
      // Fallback: tentar "permissions" plural também
      dynamic permissions = pos['permission'] ?? pos['permissions'];
      
      if (permissions == null) {
        return {
          'tickets': false,
          'extras': false,
          'scan': false,
          'report': false,
          'withdraw': false,
        };
      }
      
      // Se vier como String JSON, fazer parse
      if (permissions is String) {
        try {
          permissions = jsonDecode(permissions);
        } catch (e) {
          POS2DebugHelper.logError('Erro ao fazer parse das permissions JSON', error: e);
          return {
            'tickets': false,
            'extras': false,
            'scan': false,
            'report': false,
            'withdraw': false,
          };
        }
      }
      
      return {
        'tickets': permissions['tickets'] == true || permissions['tickets'] == 1 || permissions['tickets'] == '1',
        'extras': permissions['extras'] == true || permissions['extras'] == 1 || permissions['extras'] == '1',
        'scan': permissions['scan'] == true || permissions['scan'] == 1 || permissions['scan'] == '1',
        'report': permissions['report'] == true || permissions['report'] == 1 || permissions['report'] == '1',
        'withdraw': permissions['withdraw'] == true || permissions['withdraw'] == 1 || permissions['withdraw'] == '1',
      };
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar permissions', error: e);
      return {
        'tickets': false,
        'extras': false,
        'scan': false,
        'report': false,
        'withdraw': false,
      };
    }
  }
  
  /// Decidir qual sistema usar
  static Future<String> decidePOSSystem() async {
    final hasTickets = await hasTicketPermissions();
    
    if (hasTickets) {
      return '/pos2/modern';
    } else {
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