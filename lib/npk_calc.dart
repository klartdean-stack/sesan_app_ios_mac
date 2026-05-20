import 'package:flutter/material.dart';

class NPKCalcPage extends StatefulWidget {
  const NPKCalcPage({super.key});

  @override
  State<NPKCalcPage> createState() => _NPKCalcPageState();
}

class _NPKCalcPageState extends State<NPKCalcPage> {
  // Controller សម្រាប់បញ្ចូលរូបមន្តដីដែលចង់បាន (Target N-P-K)
  final _nCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _kCtrl = TextEditingController();

  double _urea = 0; // 46-0-0
  double _dap = 0; // 18-46-0
  double _mop = 0; // 0-0-60

  void _calculateNPK() {
    // ទាញយកតម្លៃពីការបញ្ជូល
    double targetN = double.tryParse(_nCtrl.text) ?? 0;
    double targetP = double.tryParse(_pCtrl.text) ?? 0;
    double targetK = double.tryParse(_kCtrl.text) ?? 0;

    setState(() {
      // ១. គណនាជីប៉ូតាស្យូម (MOP): រូបមន្ត = (K ចង់បាន / 60) * 100
      _mop = (targetK / 60) * 100;

      // ២. គណនាជីដេអាប៉េ (DAP): រូបមន្ត = (P ចង់បាន / 46) * 100
      _dap = (targetP / 46) * 100;

      // ៣. គណនាជីអ៊ុយរ៉េ (Urea): រូបមន្ត = (N ចង់បាន - (DAP * 0.18)) / 46 * 100
      // ព្រោះក្នុង DAP មានអាសូត (N) ១៨% រួចស្រាប់
      double nInDap = _dap * 0.18;
      double remainingN = targetN - nInDap;

      _urea = remainingN > 0 ? (remainingN / 46) * 100 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "គណនាជី N-P-K",
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        backgroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "បញ្ចូលរូបមន្តដីដែលចង់បាន (គីឡូ/ហិកតា)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInputBox(_nCtrl, "N", Colors.orange),
                const SizedBox(width: 10),
                _buildInputBox(_pCtrl, "P", Colors.blue),
                const SizedBox(width: 10),
                _buildInputBox(_kCtrl, "K", Colors.red),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _calculateNPK,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text("គណនាបរិមាណបាវជី"),
            ),
            if (_urea > 0 || _dap > 0 || _mop > 0) _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(TextEditingController ctrl, String label, Color color) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          const Text(
            "បរិមាណជីដែលកសិករត្រូវប្រើសរុប៖",
            style: TextStyle(fontSize: 15),
          ),
          const Divider(height: 30),
          _resultItem("ជីអ៊ុយរ៉េ (46-0-0)", _urea),
          _resultItem("ជីដេអាប៉េ (18-46-0)", _dap),
          _resultItem("ជីប៉ូតាស្យូម (0-0-60)", _mop),
        ],
      ),
    );
  }

  Widget _resultItem(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "${value.toStringAsFixed(1)} គីឡូក្រាម",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
