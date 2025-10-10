/// Helper para debug e logging no POS2
class POS2DebugHelper {
  static const bool _debugMode = true; // Alterar para true durante desenvolvimento
  
  /// Log de informações gerais
  static void log(String message) {
    if (_debugMode) {
      // ignore: avoid_print
      print('[POS2] $message');
    }
  }
  
  /// Log de chamadas de API
  static void logApi(String endpoint, int statusCode, {String? body}) {
    if (_debugMode) {
      // ignore: avoid_print
      print('[POS2 API] $endpoint - Status: $statusCode');
      if (body != null && body.length < 200) {
        // ignore: avoid_print
        print('[POS2 API] Response: $body');
      }
    }
  }
  
  /// Log de erros
  static void logError(String message, {dynamic error}) {
    if (_debugMode) {
      // ignore: avoid_print
      print('[POS2 ERROR] $message');
      if (error != null) {
        // ignore: avoid_print
        print('[POS2 ERROR] Details: $error');
      }
    }
  }
  
  /// Log de eventos de cart
  static void logCart(String action, {dynamic data}) {
    if (_debugMode) {
      // ignore: avoid_print
      print('[POS2 CART] $action');
      if (data != null) {
        // ignore: avoid_print
        print('[POS2 CART] Data: $data');
      }
    }
  }
}