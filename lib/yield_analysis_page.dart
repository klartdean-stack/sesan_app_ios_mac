import 'package:flutter/material.dart';
import 'dart:math';

class YieldAnalysisPage extends StatefulWidget {
  const YieldAnalysisPage({super.key});

  @override
  State<YieldAnalysisPage> createState() => _YieldAnalysisPageState();
}

class _YieldAnalysisPageState extends State<YieldAnalysisPage> {
  // --- Controllers សម្រាប់ Tab ទី១ (ដំណាំប្រចាំឆ្នាំ) ---
  final _annualWeightCtrl = TextEditingController();
  final _annualRowCtrl = TextEditingController();
  final _annualPlantCtrl = TextEditingController();
  final _annualAreaCtrl = TextEditingController();
  final _aCtrl = TextEditingController(); // ជ្រុង A
  final _bCtrl = TextEditingController(); // ជ្រុង B
  final _cCtrl = TextEditingController(); // ជ្រុង C
  final _dCtrl = TextEditingController(); // ជ្រុង D

  // --- Controllers សម្រាប់ Tab ទី២ (ដំណាំអចិន្ត្រៃយ៍) ---
  final _perenManualCountCtrl = TextEditingController(); // បញ្ចូលចំនួនដើមផ្ទាល់
  final _perenDailyWeightCtrl = TextEditingController(); // ទិន្នផល/ដើម/ថ្ងៃ
  final _perenHarvestDaysCtrl =
      TextEditingController(); // រយៈពេលប្រមូលផល (ថ្ងៃ)
  final _perenRowSpaceCtrl = TextEditingController(); // ចន្លោះជួរ (m)
  final _perenPlantSpaceCtrl = TextEditingController(); // ចន្លោះដើម (m)

  // លទ្ធផលបង្ហាញ
  String _resPlants = "0";
  String _resDaily = "0";
  String _resTotal = "0";

  // Logic គណនាផ្ទៃដី ៤ ជ្រុងមិនស្មើ (Bretschneider's formula approximation)
  double _getArea() {
    double areaHectare = double.tryParse(_annualAreaCtrl.text) ?? 0;
    if (areaHectare > 0) return areaHectare * 10000;

    double a = double.tryParse(_aCtrl.text) ?? 0;
    double b = double.tryParse(_bCtrl.text) ?? 0;
    double c = double.tryParse(_cCtrl.text) ?? 0;
    double d = double.tryParse(_dCtrl.text) ?? 0;
    if (a > 0 && b > 0 && c > 0 && d > 0) {
      double s = (a + b + c + d) / 2;
      return sqrt((s - a) * (s - b) * (s - c) * (s - d));
    }
    return 0;
  }

  // ១. គណនាដំណាំប្រចាំឆ្នាំ (ដំឡូងមី, ពោត...)
  void _calcAnnual() {
    double area = _getArea();
    double row = (double.tryParse(_annualRowCtrl.text) ?? 1) / 100;
    double plant = (double.tryParse(_annualPlantCtrl.text) ?? 1) / 100;
    double avgW = double.tryParse(_annualWeightCtrl.text) ?? 0;

    setState(() {
      double count = area / (row * plant);
      _resPlants = count.toInt().toString();
      _resTotal = ((count * avgW) / 1000).toStringAsFixed(2); // តោន
    });
  }

  // ២. គណនាដំណាំអចិន្ត្រៃយ៍ (ចន្ទី, ស្វាយ...)
  void _calcPerennial() {
    // ១. ទាញយកផ្ទៃដីជា ម៉ែត្រការ៉េ
    double areaM2 = _getArea();

    // ២. ទាញយកចន្លោះដាំដុះ (គិតជាម៉ែត្រ)
    double rowS = double.tryParse(_perenRowSpaceCtrl.text) ?? 1;
    double plantS = double.tryParse(_perenPlantSpaceCtrl.text) ?? 1;

    // ៣. រកចំនួនដើម៖ បើមានវាយបញ្ចូល "ចំនួនដើមសរុប" គឺយកតាមហ្នឹង
    // បើអត់ទេ គឺ App រកឱ្យតាមរយៈ (ផ្ទៃដី / (ចន្លោះជួរ * ចន្លោះដើម))
    double totalPlants = double.tryParse(_perenManualCountCtrl.text) ?? 0;
    if (totalPlants == 0 && areaM2 > 0) {
      totalPlants = areaM2 / (rowS * plantS);
    }

    // ៤. ទាញយកទិន្នផលមធ្យម និងចំនួនថ្ងៃ
    double dailyW = double.tryParse(_perenDailyWeightCtrl.text) ?? 0;
    double days = double.tryParse(_perenHarvestDaysCtrl.text) ?? 0;

    setState(() {
      _resPlants = totalPlants.toInt().toString(); // លទ្ធផល ១៖ ចំនួនដើមសរុប
      _resDaily = (totalPlants * dailyW).toStringAsFixed(
        2,
      ); // លទ្ធផល ២៖ គីឡូ/ថ្ងៃ
      _resTotal = ((totalPlants * dailyW * days) / 1000).toStringAsFixed(
        2,
      ); // លទ្ធផល ៣៖ តោន/រដូវ
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("វិភាគទិន្នផលរំពឹងទុក"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "ដំណាំប្រចាំឆ្នាំ", icon: Icon(Icons.grass)),
              Tab(text: "ដំណាំអចិន្ត្រៃយ៍", icon: Icon(Icons.park)),
            ],
          ),
        ),
        body: TabBarView(children: [_buildAnnualPage(), _buildPerennialPage()]),
      ),
    );
  }

  // --- UI ផ្នែកដំណាំប្រចាំឆ្នាំ ---
  Widget _buildAnnualPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _inputCard("១. ទិន្នផលមធ្យម", [
            _field(_annualWeightCtrl, "ទម្ងន់មធ្យមក្នុង ១ គុម្ភ (kg)"),
          ]),
          _inputCard("២. បច្ចេកទេសដាំដុះ", [
            Row(
              children: [
                Expanded(child: _field(_annualRowCtrl, "ចន្លោះជួរ (cm)")),
                const SizedBox(width: 10),
                Expanded(child: _field(_annualPlantCtrl, "ចន្លោះដើម (cm)")),
              ],
            ),
          ]),
          _areaInput(),
          const SizedBox(height: 20),
          _btn("គណនាទិន្នផល", _calcAnnual),
          _resultBox(
            "ចំនួនដើមសរុប",
            _resPlants,
            "ដើម",
            "ទិន្នផលសរុប",
            _resTotal,
            "តោន",
            "",
            "",
            "", // ជួរទី៣ ទុកទំនេរ បើមេមិនចង់បង្ហាញ
          ),
        ],
      ),
    );
  }

  // --- UI ផ្នែកដំណាំអចិន្ត្រៃយ៍ ---
  Widget _buildPerennialPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _inputCard("១. ចំនួនដើម", [
            _field(_perenManualCountCtrl, "បញ្ចូលចំនួនដើមសរុប (បើស្គាល់)"),
            const Text("ឬ បញ្ចូលទំហំដី និងចន្លោះដាំនៅផ្នែកខាងក្រោម"),
            _inputCard("បច្ចេកទេសដាំដុះ (សម្រាប់រកចំនួនដើម)", [
              Row(
                children: [
                  Expanded(
                    child: _field(_perenRowSpaceCtrl, "ចន្លោះជួរ (ម៉ែត្រ)"),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(_perenPlantSpaceCtrl, "ចន្លោះដើម (ម៉ែត្រ)"),
                  ),
                ],
              ),
            ]),
          ]),
          _inputCard("២. ទិន្នផល និងរយៈពេល", [
            _field(_perenDailyWeightCtrl, "ទិន្នផលមធ្យម/ដើម/ថ្ងៃ (kg)"),
            _field(_perenHarvestDaysCtrl, "រយៈពេលប្រមូលផលសរុប (ថ្ងៃ)"),
          ]),
          _areaInput(), // ប្រើសម្រាប់ករណីកសិករមិនដឹងចំនួនដើម
          const SizedBox(height: 20),
          _btn("គណនាទិន្នផល", _calcPerennial),
          _resultBox(
            "១. ចំនួនដើមសរុប",
            _resPlants,
            "ដើម",
            "២. ទិន្នផលសរុប/ថ្ងៃ",
            _resDaily,
            "kg",
            "៣. ទិន្នផលសរុប/រដូវ",
            _resTotal,
            "តោន",
          ),
        ],
      ),
    );
  }

  // --- Widget ជំនួយ ---
  Widget _inputCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _areaInput() {
    return _inputCard("៣. ផ្ទៃដី", [
      _field(_annualAreaCtrl, "ផ្ទៃដី (ហិតតា)"),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text("ឬ បញ្ចូលជ្រុងទាំង ៤ (ម៉ែត្រ)"),
      ),
      Row(
        children: [
          Expanded(child: _field(_aCtrl, "A")),
          const SizedBox(width: 5),
          Expanded(child: _field(_bCtrl, "B")),
          const SizedBox(width: 5),
          Expanded(child: _field(_cCtrl, "C")),
          const SizedBox(width: 5),
          Expanded(child: _field(_dCtrl, "D")),
        ],
      ),
    ]);
  }

  Widget _btn(String txt, VoidCallback press) {
    return ElevatedButton(
      onPressed: press,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.green,
      ),
      child: Text(txt, style: const TextStyle(color: Colors.white)),
    );
  }

  // កូដថ្មីដែលរក្សា String ច្រើនដូចកូដចាស់មេ (String 6)
  Widget _resultBox(
    String t1,
    String v1,
    String u1, // ជួរទី១ (ចំណងជើង, តម្លៃ, ឯកតា)
    String t2,
    String v2,
    String u2, // ជួរទី២
    String t3,
    String v3,
    String u3, // ជួរទី៣
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          _resRow(t1, v1, u1), // បង្ហាញជួរទី១
          const Divider(),
          _resRow(t2, v2, u2), // បង្ហាញជួរទី២
          const Divider(),
          if (t3.isNotEmpty) ...[
            const Divider(),
            _resRow(t3, v3, u3, isHighlight: true),
          ],
        ],
      ),
    );
  }

  // Widget បង្ហាញជួរនីមួយៗ
  Widget _resRow(
    String label,
    String val,
    String unit, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Row(
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: isHighlight ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.green : Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
