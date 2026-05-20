import 'package:flutter/material.dart';

class CompostCalcPage extends StatefulWidget {
  const CompostCalcPage({super.key});
  @override
  State<CompostCalcPage> createState() => _CompostCalcPageState();
}

class _CompostCalcPageState extends State<CompostCalcPage> {
  // ១. ប្តូរឈ្មោះរូបមន្តឱ្យត្រូវតាមឯកសារបច្ចេកទេស (cite: 1000058068.jpg, 1000058069.jpg)
  final Map<String, Map<String, dynamic>> formulas = {
    "រូបមន្តផលិតជីកំប៉ុស្តគោក": {
      'cow': 50.0,
      'husk': 10.0,
      'chicken': 30.0,
      'leaf': 10.0,
      'ph': 5.93,
      'n': 2.28,
      'p': 4.58,
      'k': 0.97,
    },
    "រូបមន្តផលិតជីកំប៉ុស្តទឹក": {
      'cow': 40.0,
      'husk': 0.0,
      'chicken': 50.0,
      'leaf': 10.0,
      'ph': 8.20,
      'n': 3.30,
      'p': 2.44,
      'k': 2.08,
    },
  };

  String _selectedFormula = "រូបមន្តផលិតជីកំប៉ុស្តគោក";

  // Controller សម្រាប់គ្រប់គ្រង Input
  final _cowCtrl = TextEditingController();
  final _huskCtrl = TextEditingController();
  final _chickenCtrl = TextEditingController();
  final _leafCtrl = TextEditingController();

  // variable សម្រាប់បង្ហាញលទ្ធផល
  double _resPH = 0, _resN = 0, _resP = 0, _resK = 0;

  void _updateValues(String field, String value) {
    double inputVal = double.tryParse(value) ?? 0;
    var f = formulas[_selectedFormula]!;

    // ការពារការគាំង (ទាល់តែលេខធំជាង ០ ទើបគណនា)
    if (inputVal <= 0 || f[field] == 0) return;

    // គណនាសមមាត្រ (Ratio)
    double ratio = inputVal / f[field];

    setState(() {
      if (field != 'cow' && f['cow'] > 0)
        _cowCtrl.text = (f['cow'] * ratio).toStringAsFixed(1);
      if (field != 'husk' && f['husk'] > 0)
        _huskCtrl.text = (f['husk'] * ratio).toStringAsFixed(1);
      if (field != 'chicken' && f['chicken'] > 0)
        _chickenCtrl.text = (f['chicken'] * ratio).toStringAsFixed(1);
      if (field != 'leaf' && f['leaf'] > 0)
        _leafCtrl.text = (f['leaf'] * ratio).toStringAsFixed(1);

      // បង្ហាញសារធាតុចិញ្ចឹមរំពឹងទុក (cite: 1000058068.jpg, 1000058069.jpg)
      _resPH = f['ph'];
      _resN = f['n'];
      _resP = f['p'];
      _resK = f['k'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ម៉ាស៊ីនគណនាជីកំប៉ុស្ត"),
        backgroundColor: Colors.brown.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedFormula,
              items: formulas.keys
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedFormula = v!;
                _cowCtrl.clear();
                _huskCtrl.clear();
                _chickenCtrl.clear();
                _leafCtrl.clear();
              }),
              decoration: const InputDecoration(
                labelText: "រើសប្រភេទរូបមន្ត",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _buildInput(_cowCtrl, "លាមកគោស្ងួត (គីឡូ)", 'cow'),
            _buildInput(_huskCtrl, "អង្កាម/កន្ទក់ (គីឡូ)", 'husk'),
            _buildInput(_chickenCtrl, "លាមកមាន់/ជ្រូក (គីឡូ)", 'chicken'),
            _buildInput(_leafCtrl, "ស្លឹកឈើស្រស់ (គីឡូ)", 'leaf'),
            if (_resN > 0) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        onChanged: (v) => _updateValues(field, v),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    // គណនាទម្ងន់សរុបនៃគ្រឿងផ្សំទាំងអស់
    double totalWeight =
        (double.tryParse(_cowCtrl.text) ?? 0) +
        (double.tryParse(_huskCtrl.text) ?? 0) +
        (double.tryParse(_chickenCtrl.text) ?? 0) +
        (double.tryParse(_leafCtrl.text) ?? 0);

    // គណនាទម្ងន់សាច់សារធាតុចិញ្ចឹមពិតប្រាកដ (គីឡូក្រាម)
    double weightN = (totalWeight * _resN) / 100;
    double weightP = (totalWeight * _resP) / 100;
    double weightK = (totalWeight * _resK) / 100;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade50, Colors.white]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          Text(
            "លទ្ធផលសម្រាប់ជីសរុប៖ ${totalWeight.toStringAsFixed(1)} គីឡូ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const Divider(),

          // បង្ហាញជាចំនួនគីឡូក្រាមដែលទទួលបាន (លេខនេះនឹងរត់តាមទម្ងន់ដែលមេវាយបញ្ចូល)
          _resItem(
            "អាសូត (N) ទទួលបាន៖",
            "${weightN.toStringAsFixed(2)} គីឡូ",
            Colors.orange,
          ),
          _resItem(
            "ផូស្វ័រ (P) ទទួលបាន៖",
            "${weightP.toStringAsFixed(2)} គីឡូ",
            Colors.blue,
          ),
          _resItem(
            "ប៉ូតាស្យូម (K) ទទួលបាន៖",
            "${weightK.toStringAsFixed(2)} គីឡូ",
            Colors.red,
          ),

          const Divider(),
          Text(
            "កម្រិត pH: $_resPH",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _resItem(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
