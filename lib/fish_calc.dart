import 'package:flutter/material.dart';

class FishCalcPage extends StatefulWidget {
  const FishCalcPage({super.key});
  @override
  State<FishCalcPage> createState() => _FishCalcPageState();
}

class _FishCalcPageState extends State<FishCalcPage> {
  final _widthCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _depthCtrl = TextEditingController();
  String _selectedFish = "ត្រីទីឡាព្យ៉ា";

  double _volume = 0;
  int _fishCount = 0;
  double _totalYieldKg = 0;
  double _totalFeedKg = 0;
  int _feedBags = 0;

  // ទិន្នន័យ៖ {មេគុណត្រី/m3, ទម្ងន់លក់(kg), FCR, រយៈពេលចិញ្ចឹម(ខែ)}
  final Map<String, List<dynamic>> fishData = {
    "ត្រីទីឡាព្យ៉ា": [15, 0.6, 1.5, "4-6"],
    "ត្រីរ៉ស់": [20, 0.8, 1.8, "6-8"],
    "ត្រីអណ្ដែង": [50, 0.4, 1.2, "3-4"],
    "ត្រីឆ្ពិន": [10, 0.5, 1.6, "6-10"],
    "ត្រីផ្ទួក់": [20, 0.7, 1.7, "6-8"],
    "ត្រីដំរី": [5, 1.2, 2.0, "12-18"],
    "ត្រីស្ដោរ": [15, 1.5, 2.2, "8-12"],
    "ត្រីក្រាញ់": [40, 0.2, 1.4, "3-5"],
    "ត្រីប្រា": [15, 1.0, 1.6, "6-10"],
    "ត្រីពោធិ៍": [12, 0.8, 1.7, "6-9"],
    "ត្រីកាហែ": [10, 0.4, 1.5, "5-8"],
  };

  void _calculate() {
    double w = double.tryParse(_widthCtrl.text) ?? 0;
    double l = double.tryParse(_lengthCtrl.text) ?? 0;
    double d = double.tryParse(_depthCtrl.text) ?? 0;

    if (w == 0 || l == 0 || d == 0) return;

    setState(() {
      var data = fishData[_selectedFish]!;
      _volume = w * l * d; // គណនាម៉ែត្រគូប
      _fishCount = (_volume * data[0]).toInt(); // ចំនួនត្រី
      _totalYieldKg = (_fishCount * 0.9) * data[1]; // ទិន្នផល (គិតអត្រារស់ 90%)
      _totalFeedKg = _totalYieldKg * data[2]; // ចំណីសរុបតាម FCR
      _feedBags = (_totalFeedKg / 25).ceil(); // ចំនួនបាវ (១បាវ=២៥គីឡូ)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ម៉ាស៊ីនគណនាចិញ្ចឹមត្រីវៃឆ្លាត"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCard(
              child: DropdownButtonFormField<String>(
                value: _selectedFish,
                items: fishData.keys
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFish = v!),
                decoration: const InputDecoration(
                  labelText: "ជ្រើសរើសប្រភេទត្រី",
                  border: InputBorder.none,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildInput(_lengthCtrl, "បណ្ដោយ (ម)")),
                const SizedBox(width: 10),
                Expanded(child: _buildInput(_widthCtrl, "ទទឹង (ម)")),
                const SizedBox(width: 10),
                Expanded(child: _buildInput(_depthCtrl, "ជម្រៅទឹក (ម)")),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "គណនាផែនការចិញ្ចឹម",
                style: TextStyle(fontSize: 18),
              ),
            ),
            if (_volume > 0) _buildResultView(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _buildResultView() {
    var data = fishData[_selectedFish]!;
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          _resItem(
            "មាឌទឹកសរុប៖",
            "${_volume.toStringAsFixed(1)} ម៉ែត្រគូប",
            Icons.water,
          ),
          _resItem("ចំនួនត្រីត្រូវដាក់៖", "$_fishCount ក្បាល", Icons.pets),
          _resItem("រយៈពេលចិញ្ចឹម៖", "${data[3]} ខែ", Icons.calendar_today),
          const Divider(height: 30),
          _resItem(
            "ទិន្នផលរំពឹងទុក៖",
            "${_totalYieldKg.toStringAsFixed(0)} គីឡូក្រាម",
            Icons.shopping_basket,
            color: Colors.green.shade700,
          ),
          _resItem(
            "ចំណីត្រូវប្រើសរុប៖",
            "${_totalFeedKg.toStringAsFixed(0)} គីឡូក្រាម",
            Icons.inventory,
            color: Colors.orange.shade800,
          ),
          _resItem(
            "ត្រូវទិញចំណី៖",
            "$_feedBags បាវ (25kg/បាវ)",
            Icons.bakery_dining,
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _resItem(String label, String val, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text(label),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color ?? Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
