import 'package:flutter/material.dart';

class LandMeasureScreen extends StatefulWidget {
  @override
  _LandMeasureScreenState createState() => _LandMeasureScreenState();
}

class _LandMeasureScreenState extends State<LandMeasureScreen> {
  // Controller សម្រាប់របៀបទី ១ (៤ ជ្រុង)
  final _w1 = TextEditingController(); // ទទឹងទី១ (ក្បាល)
  final _w2 = TextEditingController(); // ទទឹងទី២ (កន្ទុយ)
  final _l1 = TextEditingController(); // បណ្ដោយទី១ (ឆ្វេង)
  final _l2 = TextEditingController(); // បណ្ដោយទី២ (ស្តាំ)

  // Controller សម្រាប់របៀបទី ២ (២ ជ្រុង)
  final _simpleW = TextEditingController();
  final _simpleL = TextEditingController();

  double _sqm = 0;
  double _hectare = 0;
  bool _isFourSides = true; // true = ៤ ជ្រុង, false = ២ ជ្រុង

  void _calculate() {
    double result = 0;
    if (_isFourSides) {
      double w1 = double.tryParse(_w1.text) ?? 0;
      double w2 = double.tryParse(_w2.text) ?? 0;
      double l1 = double.tryParse(_l1.text) ?? 0;
      double l2 = double.tryParse(_l2.text) ?? 0;
      // រូបមន្តមធ្យមភាគជ្រុងទល់មុខ
      result = ((w1 + w2) / 2) * ((l1 + l2) / 2);
    } else {
      double w = double.tryParse(_simpleW.text) ?? 0;
      double l = double.tryParse(_simpleL.text) ?? 0;
      result = w * l;
    }

    setState(() {
      _sqm = result;
      _hectare = _sqm / 10000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("គណនាផ្ទៃដីកសិកម្ម"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // ជ្រើសរើសរបៀប
            Row(
              children: [
                _modeBtn(
                  "វាស់ ៤ ជ្រុង",
                  _isFourSides,
                  () => setState(() => _isFourSides = true),
                ),
                SizedBox(width: 10),
                _modeBtn(
                  "ទទឹង x បណ្ដោយ",
                  !_isFourSides,
                  () => setState(() => _isFourSides = false),
                ),
              ],
            ),
            SizedBox(height: 25),

            // បង្ហាញរូបភាពតំណាងដីតាមរបៀបនីមួយៗ

            // ប្រអប់បញ្ចូលទិន្នន័យ
            if (_isFourSides) ...[
              _buildInput("ទទឹងទី ១ / ក្បាលដី (ម)", _w1),
              _buildInput("ទទឹងទី ២ / កន្ទុយដី (ម)", _w2),
              _buildInput("បណ្ដោយទី ១ / ខាងឆ្វេង (ម)", _l1),
              _buildInput("បណ្ដោយទី ២ / ខាងស្តាំ (ម)", _l2),
            ] else ...[
              _buildInput("ទទឹង (ម)", _simpleW),
              _buildInput("បណ្ដោយ (ម)", _simpleL),
            ],

            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _calculate,
              child: Text(
                "គណនាផ្ទៃដី",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            if (_sqm > 0) _resultSection(),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(text),
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? Colors.green : Colors.white,
          foregroundColor: active ? Colors.white : Colors.green,
          side: BorderSide(color: Colors.green),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  Widget _resultSection() {
    return Column(
      children: [
        SizedBox(height: 30),
        Text(
          "លទ្ធផលគណនា៖",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 10),
        _cardResult("${_sqm.toStringAsFixed(2)} ម៉ែត្រការ៉េ", Colors.green),
        SizedBox(height: 10),
        _cardResult("${_hectare.toStringAsFixed(4)} ហិកតា", Colors.blue),
      ],
    );
  }

  Widget _cardResult(String val, Color col) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col, width: 2),
      ),
      child: Text(
        val,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: col),
      ),
    );
  }
}
