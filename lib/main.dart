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
      title: '遲延利息計算工具',
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
  final _moneyController = TextEditingController();

  DateTime? _originalDate;
  DateTime? _actualDate;
  DateTime? _borrowRenovationDate;

  // 固定：每日萬分之五（0.05%/日）單利
  static const double _dailyRate = 0.0005;

  // 計算結果
  int? _daysTotal; // 原始交屋 -> 真正交屋
  int? _daysToBorrow; // 原始交屋 -> 借屋裝修日期（若有）
  double? _interestTotal;
  double? _interestFromBorrow;

  final DateFormat _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    // 預設原始交屋：2023-10-31
    _originalDate = DateTime(2023, 10, 31);
    // 真正交屋：預設今天（去除時間）
    final now = DateTime.now();
    _actualDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _moneyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final principal =
        double.tryParse(_moneyController.text.replaceAll(',', '')) ?? 0.0;

    if (_originalDate == null || _actualDate == null) {
      _showSnack('請選擇「原始交屋日期」與「真正交屋日期」');
      return;
    }

    final original = DateTime(
      _originalDate!.year,
      _originalDate!.month,
      _originalDate!.day,
    );
    final actual = DateTime(
      _actualDate!.year,
      _actualDate!.month,
      _actualDate!.day,
    );

    final daysTotal = actual.difference(original).inDays;

    int daysToBorrow = 0;
    if (_borrowRenovationDate != null) {
      final borrow = DateTime(
        _borrowRenovationDate!.year,
        _borrowRenovationDate!.month,
        _borrowRenovationDate!.day,
      );
      daysToBorrow = borrow.difference(original).inDays;
      if (daysToBorrow < 0) daysToBorrow = 0; // 借屋日早於原始交屋 => 視為 0
    }

    // 單利：I = P * r(每日) * days
    final safeDaysTotal = daysTotal < 0 ? 0 : daysTotal;
    final interestTotal = principal * _dailyRate * safeDaysTotal;
    final interestFromBorrow = daysToBorrow > 0
        ? principal * _dailyRate * daysToBorrow
        : 0.0;

    setState(() {
      _daysTotal = safeDaysTotal;
      _daysToBorrow = daysToBorrow;
      _interestTotal = interestTotal;
      _interestFromBorrow = interestFromBorrow;
    });
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _fmtMoney(double? v) => v == null ? '-' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('預售屋遲延利息計算工具')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '輸入資料',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _moneyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '已繳價款（本金，NT）',
                  hintText: '例如：5000000',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '請輸入已繳價款';
                  if (double.tryParse(v.replaceAll(',', '')) == null) {
                    return '金額格式錯誤';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DatePickerTile(
                    label: '原始交屋日期',
                    date: _originalDate,
                    onTap: () => _pickDate(
                      context,
                      _originalDate,
                      (d) => setState(() => _originalDate = d),
                    ),
                  ),
                  _DatePickerTile(
                    label: '真正交屋日期',
                    date: _actualDate,
                    onTap: () => _pickDate(
                      context,
                      _actualDate,
                      (d) => setState(() => _actualDate = d),
                    ),
                  ),
                  _DatePickerTile(
                    label: '借屋/裝修日期（可選）',
                    date: _borrowRenovationDate,
                    onTap: () => _pickDate(
                      context,
                      _borrowRenovationDate,
                      (d) => setState(() => _borrowRenovationDate = d),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate),
                    label: const Text('計算'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _moneyController.clear();
                        // 還原日期預設
                        _originalDate = DateTime(2023, 10, 31);
                        final now = DateTime.now();
                        _actualDate = DateTime(now.year, now.month, now.day);
                        _borrowRenovationDate = null;
                        _daysTotal = null;
                        _daysToBorrow = null;
                        _interestTotal = null;
                        _interestFromBorrow = null;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重設'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                '計算結果',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '原始交屋日期: ${_originalDate == null ? '-' : _df.format(_originalDate!)}',
                      ),
                      Text(
                        '真正交屋日期: ${_actualDate == null ? '-' : _df.format(_actualDate!)}',
                      ),
                      Text(
                        '借屋/裝修日期: ${_borrowRenovationDate == null ? '-' : _df.format(_borrowRenovationDate!)}',
                      ),
                      const SizedBox(height: 8),
                      Text('逾期天數（原始 -> 真正）: ${_daysTotal ?? '-'} 天'),
                      Text('逾期天數（原始 -> 借屋/裝修）: ${_daysToBorrow ?? '-'} 天'),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        '依全部逾期天數計算的遲延利息（單利、日利 0.05%）: NT\$ ${_fmtMoney(_interestTotal)}',
                      ),
                      if (_daysToBorrow != null && _daysToBorrow! > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '依借屋/裝修起算天數計算的遲延利息（單利、日利 0.05%）: NT\$ ${_fmtMoney(_interestFromBorrow)}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        '備註：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('• 本工具固定以「每日萬分之五（0.05%/日）」單利計算。'),
                      const Text('• 若契約有特別約定（每日違約金、固定違約金等），請以契約為準。'),
                      const Text('• 本工具為簡單利息，未考慮複利。'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                '使用範例',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '範例：本金 NT5,000,000，契約約定每日萬分之五（0.05%/日），原始交屋日 2025-01-01，真正交屋日 2025-04-01（90 天）。',
              ),
              const SizedBox(height: 6),
              const Text('輸入：本金 5000000。按「計算」查看結果。'),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return InkWell(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 1.8,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  date == null ? '未選擇' : df.format(date!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}
