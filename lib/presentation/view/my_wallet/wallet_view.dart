// import 'package:essenciacompany_mobile/core/utils.dart';
import 'package:essenciacompany_mobile/core/utils.dart';
import 'package:essenciacompany_mobile/domain/wallet_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/custom_app_bar.dart';
import 'package:essenciacompany_mobile/presentation/view/scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  String? _deposit;
  String? _refund;
  // String? _totalTransaction;
  Map<String, dynamic>? _user;
  List<dynamic> _transactions = [];
  final TextEditingController _amount = TextEditingController();
  String _withdrawType = 'deposit';

  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await getWalletData(token: token);
    if (res['success']) {
      setState(() {
        _deposit = 'Є${res['data']['deposit'] ?? 0}';
        _refund = 'Є${res['data']['refund'] ?? 0}';
        /* _totalTransaction =
            'Є${(res['data']['deposit'] ?? 0) + (res['data']['refund'] ?? 0)}';
        _transactions = res['data']['transactions']['data']; */
      });
    }
  }

  onScan(code) async {
    Navigator.pop(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var res = await getWalletUser(token: token, code: code);
    if (res['success']) {
      setState(() {
        _user = res['data']['customer'];
        _transactions = res['data']['transactions'];
      });
    }
    Fluttertoast.showToast(
        msg: 'Scan ${res['success'] ? 'Successfull' : 'Failed'}',
        gravity: ToastGravity.CENTER,
        backgroundColor: const Color(0xFFF36A30),
        textColor: Colors.white,
        fontSize: 16.0);
  }

  handleWithdrawType(String type) {
    setState(() {
      _withdrawType = type;
    });
  }

  onCompleteTransaction() async {
    setState(() {
      _isCompleting = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    int? amount = int.tryParse(_amount.text);
    var res = await makeWalletTransaction(
        token: token,
        userId: _user!['id'],
        amount: amount,
        type: _withdrawType);
    if (res['success']) {
      setState(() {
        _user = null;
      });
      _amount.clear();
      loadData();
    }
    Fluttertoast.showToast(
        msg: 'Transaction ${res['success'] ? 'Completed' : 'Failed'}',
        gravity: ToastGravity.CENTER,
        backgroundColor: const Color(0xFFF36A30),
        textColor: Colors.white,
        fontSize: 16.0);
    setState(() {
      _isCompleting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF001232),
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar.showStaffAppBar(context),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  if (_user == null)
                    GestureDetector(
                      onTap: () {
                        // onScan('asffasla');
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ScannerView(onScan: onScan);
                        }));
                      },
                      child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFF2500B),
                                  offset: Offset(5, 5),
                                )
                              ]),
                          child: const SizedBox(
                              height: 160,
                              width: 160,
                              child: Icon(
                                Icons.qr_code_scanner,
                                size: 140,
                              ))),
                    )
                  else
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFF2500B),
                                offset: Offset(5, 5),
                              )
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_user!['name']!.isNotEmpty)
                              Text(
                                '${_user!['name']}',
                                style: const TextStyle(
                                    color: Color(0xFFF2500B), fontSize: 30),
                                textAlign: TextAlign.center,
                              ),
                            /* if (_user!['email']!.isNotEmpty)
                              Text(
                                '${_user!['email']}',
                                style: const TextStyle(
                                    color: Color(0xFF676767), fontSize: 16),
                                textAlign: TextAlign.center,
                              ), */
                            if (_user!['balance'] != null)
                              Text(
                                'Є${_user!['balance']}',
                                style: const TextStyle(
                                    color: Color(0xFFF2500B), fontSize: 26),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(
                              height: 20,
                            ),
                            const Text(
                              'Amount',
                              style: TextStyle(
                                  color: Color(0xFF676767), fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            Container(
                                margin: const EdgeInsets.only(top: 18),
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8)),
                                    border: Border.all(
                                        color: const Color(0xFF676767))),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: const BoxDecoration(
                                            border: Border(
                                                right: BorderSide(
                                                    color: Color(0xFF676767)))),
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Є',
                                            style: TextStyle(
                                                color: Color(0xFF676767),
                                                fontSize: 20),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _amount,
                                          decoration: const InputDecoration(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            border: InputBorder.none,
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF676767),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          handleWithdrawType('refund');
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          color: _withdrawType != 'refund'
                                              ? const Color(0xFFF2500B)
                                              : const Color(0xFF001232),
                                          child: Text(
                                            'Refund',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _withdrawType != 'refund'
                                                  ? const Color(0xFF001232)
                                                  : const Color(0xFFF2500B),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          handleWithdrawType('deposit');
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          color: _withdrawType != 'deposit'
                                              ? const Color(0xFFF2500B)
                                              : const Color(0xFF001232),
                                          child: Text(
                                            'Deposit',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _withdrawType != 'deposit'
                                                  ? const Color(0xFF001232)
                                                  : const Color(0xFFF2500B),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(
                              height: 20,
                            ),
                            if (_isCompleting)
                              const Align(
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF2500B),
                                ),
                              )
                            else
                              IntrinsicHeight(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: onCompleteTransaction,
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        color: const Color(0xFFF2500B),
                                        child: const Text(
                                          'Complete Transaction',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF001232),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 16,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _user = null;
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        color: const Color(0xFFF2500B),
                                        child: const Text(
                                          'Reset',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF001232),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                          ],
                        )),
                  const SizedBox(
                    height: 24,
                  ),
                  if (_user == null)
                    Table(
                      children: [
                        TableRow(children: [
                          TableCell(
                              child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFF2500B),
                                    offset: Offset(5, 5),
                                  )
                                ]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\nDeposit',
                                  style: TextStyle(
                                      color: Color(0xFFBD3D06), fontSize: 16),
                                  textAlign: TextAlign.start,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_deposit ?? 'N/A',
                                      style: const TextStyle(fontSize: 24),
                                      textAlign: TextAlign.end),
                                )
                              ],
                            ),
                          )),
                          TableCell(
                              child: Container(
                            margin: const EdgeInsets.only(left: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFF2500B),
                                    offset: Offset(5, 5),
                                  )
                                ]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\nRefund',
                                  style: TextStyle(
                                      color: Color(0xFFBD3D06), fontSize: 16),
                                  textAlign: TextAlign.start,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_refund ?? 'N/A',
                                      style: const TextStyle(fontSize: 24),
                                      textAlign: TextAlign.end),
                                )
                              ],
                            ),
                          )),
                        ])
                      ],
                    ),
                  /* Container(
                    padding: const EdgeInsets.all(16),
                    decoration:
                        const BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                        color: Color(0xFFF2500B),
                        offset: Offset(5, 5),
                      )
                    ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total\nTransaction',
                          style:
                              TextStyle(color: Color(0xFFBD3D06), fontSize: 16),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(_totalTransaction ?? 'N/A',
                              style: const TextStyle(fontSize: 24),
                              textAlign: TextAlign.end),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ), */
                  if (_user != null)
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFF2500B),
                                offset: Offset(5, 5),
                              )
                            ]),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Transactions',
                                style: TextStyle(
                                    color: Color(0xFFBD3D06), fontSize: 30),
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              _transactions.isEmpty
                                  ? const Text(
                                      'No transactions yet',
                                      style: TextStyle(fontSize: 15),
                                      textAlign: TextAlign.center,
                                    )
                                  : Table(
                                      children:
                                          _transactions.map((transaction) {
                                        return TableRow(children: [
                                          Text(
                                              transaction['amount'] != null
                                                  ? 'Є${transaction['amount']}'
                                                  : 'N/A',
                                              style: const TextStyle(
                                                  fontSize: 15)),
                                          Text(
                                              transaction['description'] ??
                                                  'N/A',
                                              style: const TextStyle(
                                                  fontSize: 15)),
                                          Text(
                                              transaction['created_at'] != null
                                                  ? formatDateTime(
                                                      transaction['created_at'])
                                                  : 'N/A',
                                              style:
                                                  const TextStyle(fontSize: 15))
                                        ]);
                                      }).toList(),
                                    )
                            ]))
                ],
              ),
            ),
          ),
        ));
  }
}
