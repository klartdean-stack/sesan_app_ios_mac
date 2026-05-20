import 'package:flutter/material.dart';

class FertilizerCalcPage extends StatefulWidget {
  const FertilizerCalcPage({super.key});

  @override
  State<FertilizerCalcPage> createState() => _FertilizerCalcPageState();
}

class _FertilizerCalcPageState extends State<FertilizerCalcPage> {
  final areaController = TextEditingController();
  final searchController = TextEditingController();

  String selectedCrop = 'ស្រូវ';
  double totalBags = 0;

  // 🎯 មេអាចថែមឈ្មោះដំណាំក្នុងនេះឱ្យដល់ ១០០ ក៏បាន (ឈ្មោះ : អត្រាជី)
  final Map<String, double> allCrops = {
    'ស្រូវ': 3.0, 'ដំឡូងមី': 4.0, 'ទុរេន': 6.5, 'ស្វាយ': 4.0, 'ប័រ': 5.0,
    'សាវម៉ាវ': 5.5, 'កៅស៊ូ': 4.5, 'ត្របែក': 4.0, 'មៀន': 5.0, 'ខ្នុរ': 4.0,
    'ចន្ទី': 3.5, 'ដូង': 4.5, 'ពោត': 4.5, 'ម្រេច': 6.0, 'កាហ្វេ': 5.0,
    'ក្រូចពោធិ៍សាត់': 5.0, 'ម្នាស់': 4.0, 'ចេក': 3.5, 'ឪឡឹក': 4.0, 'ម្ទេស': 5.5,
    'ប៉េងប៉ោះ': 5.0,
    'ត្រសក់': 4.5,
    'ស្ពៃក្តោប': 5.5,
    'ខ្ទឹមបារាំង': 4.0,
    'សណ្តែកដី': 2.5,
    // ... មេអាចថែមបន្តទៀតនៅទីនេះឱ្យដល់ ១០០ មុខតាមចិត្ត
  };

  List<String> filteredCrops = [];

  @override
  void initState() {
    super.initState();
    filteredCrops = allCrops.keys.toList();
  }

  void _filterCrops(String query) {
    setState(() {
      filteredCrops = allCrops.keys
          .where((crop) => crop.contains(query))
          .toList();
    });
  }

  void calculateFertilizer() {
    double area = double.tryParse(areaController.text) ?? 0;
    double rate = allCrops[selectedCrop] ?? 0;
    setState(() {
      totalBags = area * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'រូបមន្តដាក់ជី ១០០ មុខ',
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔍 ប្រអប់ស្វែងរកឈ្មោះដំណាំ
            TextField(
              controller: searchController,
              onChanged: _filterCrops,
              decoration: InputDecoration(
                hintText: "ស្វែងរកឈ្មោះដំណាំ... (ឧ៖ ទុរេន)",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 📝 កន្លែងរើសដំណាំដែលបាន Filter រួច
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: DropdownButton<String>(
                value: filteredCrops.contains(selectedCrop)
                    ? selectedCrop
                    : filteredCrops.first,
                isExpanded: true,
                underline: const SizedBox(),
                items: filteredCrops.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(fontFamily: 'Siemreap'),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedCrop = newValue!;
                  });
                },
              ),
            ),

            const SizedBox(height: 15),
            _buildInput(
              "ផ្ទៃដីដាំដុះ (ហិកតា)",
              Icons.landscape,
              areaController,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: calculateFertilizer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'គណនាបរិមាណជី',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            'តម្រូវការជីសម្រាប់ $selectedCrop',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            '${totalBags.toStringAsFixed(1)} បាវ',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const Text(
            '(បាវ ៥០ គីឡូក្រាម)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
