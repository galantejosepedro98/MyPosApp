// Arquivo temporário para testar a API diretamente
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiDirectTestPage extends StatefulWidget {
  static const routeName = '/api-direct-test';
  
  const ApiDirectTestPage({super.key});

  @override
  State<ApiDirectTestPage> createState() => _ApiDirectTestPageState();
}

class _ApiDirectTestPageState extends State<ApiDirectTestPage> {
  bool _isLoading = false;
  String _resultMessage = '';
  String _responseJson = '';
  final int _orderId = 22680; // Usar o mesmo ID de pedido

  // Testar chamada direta à API
  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _resultMessage = 'Chamando API diretamente para o pedido #$_orderId...';
      _responseJson = '';
    });

    try {
      // Obter token da mesma forma que o aplicativo
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('Token não encontrado. Faça login primeiro.');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      
      // Chamar API diretamente
      final url = 'https://events.essenciacompany.com/api/app/pos2/vendus/print/$_orderId';
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      // Analisar resposta
      setState(() {
        _resultMessage = 'Status: ${response.statusCode}';
        
        // Analisar corpo da resposta
        try {
          final jsonResponse = jsonDecode(response.body);
          _responseJson = const JsonEncoder.withIndent('  ').convert(jsonResponse);
          
          // Verificar estrutura específica
          final success = jsonResponse['success'] ?? false;
          if (success && jsonResponse['data'] != null) {
            final data = jsonResponse['data'];
            final printData = data['print_data_base64'];
            
            if (printData == null || printData.isEmpty) {
              _resultMessage += '\n\nPROBLEMA: print_data_base64 está vazio ou não existe na resposta!';
            } else {
              _resultMessage += '\n\nSUCESSO: print_data_base64 encontrado com ${printData.length} caracteres';
            }
          }
        } catch (e) {
          _resultMessage += '\n\nErro ao analisar resposta JSON: $e';
          _responseJson = response.body;
        }
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Erro: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Direto da API'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TESTE DIRETO DA API DO VENDUS:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'OrderID: $_orderId',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testApi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 60),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('TESTAR API DIRETAMENTE'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resultado:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _resultMessage,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (_responseJson.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resposta da API:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          _responseJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}