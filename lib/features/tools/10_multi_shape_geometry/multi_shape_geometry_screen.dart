import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../geometry/screens/geometry_hub_screen.dart';

class MultiShapeGeometryScreen extends StatefulWidget {
  const MultiShapeGeometryScreen({super.key});

  @override
  State<MultiShapeGeometryScreen> createState() => _MultiShapeGeometryScreenState();
}

class _MultiShapeGeometryScreenState extends State<MultiShapeGeometryScreen> {
  String _selectedShape = 'আয়তক্ষেত্র';

  // Controllers
  final _inputA = TextEditingController(text: '120');
  final _inputB = TextEditingController(text: '80');
  final _inputC = TextEditingController(text: '60');

  double _areaSqFt = 0.0;

  final List<String> _shapes = [
    'আয়তক্ষেত্র',
    'বর্গক্ষেত্র',
    'ত্রিভুজ (৩ বাহু)',
    'ত্রিভুজ (ভূমি × উচ্চতা)',
    'ট্রাপিজিয়াম',
    'সামান্তরিক / রম্বস',
    'বৃত্ত (Circle)',
    'উপবৃত্ত (Ellipse)',
  ];

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void dispose() {
    _inputA.dispose();
    _inputB.dispose();
    _inputC.dispose();
    super.dispose();
  }

  void _compute() {
    final a = double.tryParse(_inputA.text) ?? 0.0;
    final b = double.tryParse(_inputB.text) ?? 0.0;
    final c = double.tryParse(_inputC.text) ?? 0.0;

    double area = 0.0;
    switch (_selectedShape) {
      case 'আয়তক্ষেত্র':
        area = a * b;
        break;
      case 'বর্গক্ষেত্র':
        area = a * a;
        break;
      case 'ত্রিভুজ (৩ বাহু)':
        if (a + b > c && a + c > b && b + c > a) {
          final s = (a + b + c) / 2.0;
          area = math.sqrt(s * (s - a) * (s - b) * (s - c));
        }
        break;
      case 'ত্রিভুজ (ভূমি × উচ্চতা)':
        area = 0.5 * a * b;
        break;
      case 'ট্রাপিজিয়াম':
        area = ((a + b) / 2.0) * c;
        break;
      case 'সামান্তরিক / রম্বস':
        area = a * b; // Base * Perpendicular Height
        break;
      case 'বৃত্ত (Circle)':
        area = math.pi * a * a; // a is radius
        break;
      case 'উপবৃত্ত (Ellipse)':
        area = math.pi * a * b; // semi-major a * semi-minor b
        break;
    }

    setState(() => _areaSqFt = area);
  }

  void _copyReport() {
    final dec = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;
    final bigha = dec / 33.00;

    final report = '''
=== জমি পরিমাপ রিপোর্ট ($_selectedShape) ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
আকৃতি: $_selectedShape
মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_areaSqFt)} বর্গফুট
মোট শতাংশ: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক
মোট কাঠা: ${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা
মোট বিঘা: ${BanglaFormatter.formatNumber(bigha, fractionDigits: 4)} বিঘা
বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(_areaSqFt)}
অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ
''';
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('পরিমাপ রিপোর্ট কপি করা হয়েছে!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dec = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;

    return Scaffold(
      appBar: AppBar(
        title: const Text('যেকোনো আকৃতির জমি পরিমাপ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'জ্যামিতি হাব',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GeometryHubScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি',
            onPressed: _copyReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Shape selector dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedShape,
                  decoration: const InputDecoration(
                    labelText: 'জ্যামিতিক আকৃতি নির্বাচন করুন',
                    prefixIcon: Icon(Icons.category, color: AppColors.primaryGreen),
                  ),
                  items: _shapes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedShape = val;
                        _compute();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Dynamic Inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInputTile('১ম মাপ (ফুট):', _inputA),
                    if (_selectedShape != 'বর্গক্ষেত্র' && _selectedShape != 'বৃত্ত (Circle)') ...[
                      const SizedBox(height: 12),
                      _buildInputTile('২য় মাপ (ফুট):', _inputB),
                    ],
                    if (_selectedShape == 'ত্রিভুজ (৩ বাহু)' || _selectedShape == 'ট্রাপিজিয়াম') ...[
                      const SizedBox(height: 12),
                      _buildInputTile(_selectedShape == 'ট্রাপিজিয়াম' ? 'লম্ব উচ্চতা (ফুট):' : '৩য় বাহু (ফুট):', _inputC),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Output Result Card
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মোট শতাংশ (শতক):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primaryGreenDark)),
                      ],
                    ),
                    const Divider(height: 18),
                    _buildRow('কাঠা', '${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা'),
                    _buildRow('বর্গফুট', '${BanglaFormatter.formatNumber(_areaSqFt)} ft²'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text('বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(_areaSqFt)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTile(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (_) => _compute(),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
