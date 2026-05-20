import 'package:flutter/material.dart';

class ProfitCalcPage extends StatefulWidget {
  const ProfitCalcPage({super.key});

  @override
  State<ProfitCalcPage> createState() => _ProfitCalcPageState();
}

class _ProfitCalcPageState extends State<ProfitCalcPage> {
  // Controller សម្រាប់ចំណាយ
  final _seedCostCtrl = TextEditingController();
  final _laborCostCtrl = TextEditingController();
  final _fertilizerCostCtrl = TextEditingController();
  final _otherCostCtrl = TextEditingController();

  // Controller សម្រាប់ចំណូល
  final _harvestAmountCtrl = TextEditingController();
  final _pricePerUnitCtrl = TextEditingController();

  double _totalCost = 0;
  double _totalIncome = 0;
  double _profit = 0;

  void _calculate() {
    setState(() {
      // គណនាចំណាយសរុប
      double seeds = double.tryParse(_seedCostCtrl.text) ?? 0;
      double labor = double.tryParse(_laborCostCtrl.text) ?? 0;
      double fertilizer = double.tryParse(_fertilizerCostCtrl.text) ?? 0;
      double others = double.tryParse(_otherCostCtrl.text) ?? 0;
      _totalCost = seeds + labor + fertilizer + others;

      // គណនាចំណូលសរុប
      double harvest = double.tryParse(_harvestAmountCtrl.text) ?? 0;
      double price = double.tryParse(_pricePerUnitCtrl.text) ?? 0;
      _totalIncome = harvest * price;

      // គណនាចំណេញ/ខាត
      _profit = _totalIncome - _totalCost;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ប៉ាន់ស្មានចំណូល-ចំណាយ",
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("💰 ចំណាយប៉ាន់ស្មាន (ដើមទុន)", Colors.red),
            _buildInput(_seedCostCtrl, "ថ្លៃគ្រាប់ពូជ/កូនដាំ", Icons.grass),
            _buildInput(
              _fertilizerCostCtrl,
              "ថ្លៃជី និងថ្នាំកសិកម្ម",
              Icons.science,
            ),
            _buildInput(_laborCostCtrl, "ថ្លៃឈ្នួលពលកម្ម", Icons.groups),
            _buildInput(_otherCostCtrl, "ចំណាយផ្សេងៗ", Icons.more_horiz),

            const SizedBox(height: 25),
            _buildSectionTitle("📈 ចំណូលប៉ាន់ស្មាន (លក់ចេញ)", Colors.green),
            _buildInput(
              _harvestAmountCtrl,
              "បរិមាណផលដែលទទួលបាន (Kg/តោន)",
              Icons.inventory,
            ),
            _buildInput(
              _pricePerUnitCtrl,
              "តម្លៃលក់ចេញក្នុង ១ ឯកតា",
              Icons.sell,
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text("គណនាផលចំណេញ", style: TextStyle(fontSize: 18)),
            ),

            if (_totalCost > 0 || _totalIncome > 0) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    bool isProfit = _profit >= 0;
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isProfit
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isProfit ? Colors.green : Colors.red),
      ),
      child: Column(
        children: [
          _resultRow(
            "ចំណាយសរុប៖",
            "- \$${_totalCost.toStringAsFixed(2)}",
            Colors.red,
          ),
          _resultRow(
            "ចំណូលសរុប៖",
            "+ \$${_totalIncome.toStringAsFixed(2)}",
            Colors.green,
          ),
          const Divider(),
          _resultRow(
            isProfit ? "ចំណេញសុទ្ធ៖" : "ខាតបង់៖",
            "\$${_profit.abs().toStringAsFixed(2)}",
            isProfit ? Colors.green.shade800 : Colors.red.shade800,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
