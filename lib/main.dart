import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const LateInterestApp());
}

class LateInterestApp extends StatelessWidget {
  const LateInterestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '延遲利息與新青安補助試算',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LateInterestHome(),
    );
  }
}

class LateInterestHome extends StatefulWidget {
  const LateInterestHome({Key? key}) : super(key: key);

  @override
  State<LateInterestHome> createState() => _LateInterestHomeState();
}

class _LateInterestHomeState extends State<LateInterestHome> {
  final _formKey = GlobalKey<FormState>();
  final _paidBeforeController = TextEditingController();
  final _totalPaidController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _loanLostDayController = TextEditingController();

  static const double _dailyRate = 0.0005;

  DateTime? _permitDueDate;
  DateTime? _permitActualDate;
  DateTime? _notifyDate;
  DateTime? _loanDate;

  double? _violation1;
  double? _violation2;
  double? _violation3;
  double? _greenLoss;
  int? _delay1;
  int? _delay2;
  int? _delay3;
  DateTime? _shouldNotifyDate;

  String? _greenProcess; // 顯示計算過程

  final DateFormat _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _permitDueDate = DateTime(2024, 1, 31);
    _permitActualDate = DateTime(2025, 1, 3);
    _notifyDate = DateTime(2025, 10, 9);
    _loanDate = DateTime(2025, 09, 25);

    _loanLostDayController.text = '365';
    _loanAmountController.text = '10000000';
  }

  void _setBuilding(String building) {
    setState(() {
      if (building == '星悅館') {
        _permitDueDate = DateTime(2024, 1, 31);
        _permitActualDate = DateTime(2024, 12, 24);
      } else if (building == '星辰館') {
        _permitDueDate = DateTime(2023, 10, 31);
        _permitActualDate = DateTime(2025, 1, 22);
      }
      _notifyDate = DateTime(2025, 10, 9);
      _loanDate = DateTime(2025, 09, 25);
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final paidBefore =
        double.tryParse(_paidBeforeController.text.replaceAll(',', '')) ?? 0;
    final totalPaid =
        double.tryParse(_totalPaidController.text.replaceAll(',', '')) ?? 0;
    final loanAmount =
        double.tryParse(_loanAmountController.text.replaceAll(',', '')) ?? 0;

    final loanLostDay =
        double.tryParse(_loanLostDayController.text.replaceAll(',', '')) ?? 0;

    final paidAfter = totalPaid - paidBefore;

    // 1️⃣ 延遲取得使用執照
    final delay1 = _permitActualDate!.difference(_permitDueDate!).inDays;
    final violation1 = paidBefore * _dailyRate * delay1;

    // 2️⃣ 延遲通知交屋（貸款前）
    final shouldNotifyDate = DateTime(
      _permitActualDate!.year,
      _permitActualDate!.month + 6,
      _permitActualDate!.day,
    );
    final delay2 = _loanDate!.difference(shouldNotifyDate).inDays;
    final delay2Safe = delay2 < 0 ? 0 : delay2;
    final violation2 = paidBefore * _dailyRate * delay2Safe;

    // 3️⃣ 延遲通知交屋（貸款後）
    final delay3 = DateTime.now().difference(_loanDate!).inDays;
    final delay3Safe = delay3 < 0 ? 0 : delay3;
    final violation3 = paidAfter * _dailyRate * delay3Safe;

    // 4️⃣ 新青安補助
    final greenDays = loanLostDay;
    const double greenRate = 0.00375; // 0.375%
    final greenLoss = loanAmount * greenRate * greenDays / 365;
    final greenProcess =
        '本金：$loanAmount\n補貼利率：${greenRate * 100}%\n補助天數：$greenDays 天\n計算公式：$loanAmount × $greenRate × ($greenDays / 365)\n補助金額 ≈ ${greenLoss.toStringAsFixed(0)} 元';

    setState(() {
      _delay1 = delay1;
      _delay2 = delay2Safe;
      _delay3 = delay3Safe;
      _violation1 = violation1;
      _violation2 = violation2;
      _violation3 = violation3;
      _greenLoss = greenLoss;
      _shouldNotifyDate = shouldNotifyDate;
      _greenProcess = greenProcess;
    });
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) onPicked(picked);
  }

  String _fmt(double? v) => v == null ? '-' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('預售屋遲延與新青安補助試算')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _setBuilding('星悅館'),
                    child: const Text('星悅館'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _setBuilding('星辰館'),
                    child: const Text('星辰館'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildMoneyField('貸款前已繳金額', _paidBeforeController),
              _buildMoneyField(
                '總已繳金額（已繳金額+貸款(一般貸款+新青安)）',
                _totalPaidController,
              ),
              const SizedBox(height: 40),
              _buildMoneyField('新青安損失天數', _loanLostDayController),
              _buildMoneyField('貸款金額（新青安）', _loanAmountController),
              const SizedBox(height: 20),

              _buildDateTile(
                '約定使用執照日期',
                _permitDueDate,
                (d) => setState(() => _permitDueDate = d),
              ),
              _buildDateTile(
                '核准使用執照日期',
                _permitActualDate,
                (d) => setState(() => _permitActualDate = d),
              ),
              if (_permitActualDate != null)
                ListTile(
                  title: Text(
                    '最遲通知交屋日期（使照+6個月）：${_df.format(_permitActualDate!.add(const Duration(days: 180)))}',
                  ),
                ),
              _buildDateTile(
                '通知交屋日期',
                _notifyDate,
                (d) => setState(() => _notifyDate = d),
              ),
              _buildDateTile(
                '貸款日',
                _loanDate,
                (d) => setState(() => _loanDate = d),
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('開始試算'),
              ),
              const SizedBox(height: 20),

              if (_violation1 != null) ...[
                Text('延遲取得使用執照：$_delay1 天 → NT\$${_fmt(_violation1)}'),
                Text('延遲通知交屋（貸款前）：$_delay2 天 → NT\$${_fmt(_violation2)}'),
                Text('延遲通知交屋（貸款後）：$_delay3 天 → NT\$${_fmt(_violation3)}'),
                const SizedBox(height: 8),
                Text('新青安補貼金額（截至貸款日）：NT\$${_fmt(_greenLoss)}'),
                Text('計算過程：\n$_greenProcess'),
                const SizedBox(height: 8),
                Text(
                  '總計：NT\$${_fmt((_violation1 ?? 0) + (_violation2 ?? 0) + (_violation3 ?? 0))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '總計包含新青安：NT\$${_fmt((_violation1 ?? 0) + (_violation2 ?? 0) + (_violation3 ?? 0) + (_greenLoss ?? 0))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
              Image.asset('assets/images/1.png'),
              Image.asset('assets/images/2.png'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoneyField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.isEmpty) ? '請輸入金額' : null,
      ),
    );
  }

  Widget _buildDateTile(
    String label,
    DateTime? date,
    ValueChanged<DateTime> onPick,
  ) {
    return ListTile(
      title: Text('$label：${date == null ? '-' : _df.format(date)}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () => _pickDate(context, date, onPick),
    );
  }
}
