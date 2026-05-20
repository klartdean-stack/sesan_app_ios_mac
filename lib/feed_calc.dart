import 'package:flutter/material.dart';

class FeedCalcPage extends StatefulWidget {
  const FeedCalcPage({super.key});

  @override
  State<FeedCalcPage> createState() => _FeedCalcPageState();
}

class _FeedCalcPageState extends State<FeedCalcPage> {
  final countController = TextEditingController();
  final searchController = TextEditingController();

  String selectedAnimal = 'មាន់សាច់';
  double totalFeed = 0;

  // 🎯 បញ្ជីសត្វ និងបរិមាណចំណីមធ្យម (គីឡូក្រាម/ក្បាល/ថ្ងៃ)
  final Map<String, double> animalData = {
    'មាន់សាច់': 0.15,
    'មាន់ស្រែ': 0.12,
    'ទាសាច់': 0.20,
    'ទាពង': 0.18,
    'ក្រួចសាច់': 0.03,
    'ក្រួចពង': 0.025,
    'ជ្រូកសាច់': 2.5,
    'ជ្រូកមេ': 3.0,
    'គោសាច់': 10.0,
    'គោទឹកដោះ': 12.0,
    'ត្រីអណ្តែង': 0.05,
    'ត្រីប្រា': 0.08,
    'ត្រីទីឡាព្យ៉ា': 0.04,
    'កង្កែប': 0.02,
    'ពស់ចាន់ល្មម': 0.015, // ជាមធ្យមក្នុងមួយថ្ងៃ
    'អន្ទង់': 0.01,
    'កន្ធាយ': 0.03,
    'ពពែ': 2.0,
    'ចៀម': 2.0,
    'ទន្សាយ': 0.15,
  };

  List<String> filteredAnimals = [];

  @override
  void initState() {
    super.initState();
    filteredAnimals = animalData.keys.toList();
  }

  void _filterAnimals(String query) {
    setState(() {
      filteredAnimals = animalData.keys
          .where((animal) => animal.contains(query))
          .toList();
    });
  }

  void calculateFeed() {
    double count = double.tryParse(countController.text) ?? 0;
    double rate = animalData[selectedAnimal] ?? 0;
    setState(() {
      totalFeed = count * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'គណនាចំណីសត្វ (សេសាន)',
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔍 ប្រអប់ស្វែងរកប្រភេទសត្វ
            TextField(
              controller: searchController,
              onChanged: _filterAnimals,
              decoration: InputDecoration(
                hintText: "ស្វែងរកប្រភេទសត្វ... (ឧ៖ ជ្រូក)",
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 📝 បញ្ជីរើសសត្វ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent.shade100),
              ),
              child: DropdownButton<String>(
                value: filteredAnimals.contains(selectedAnimal)
                    ? selectedAnimal
                    : filteredAnimals.first,
                isExpanded: true,
                underline: const SizedBox(),
                items: filteredAnimals.map((String value) {
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
                    selectedAnimal = newValue!;
                  });
                },
              ),
            ),

            const SizedBox(height: 15),
            _buildInput(
              "ចំនួនសត្វសរុប (ក្បាល/ភ្នែក)",
              Icons.pets,
              countController,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: calculateFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'គណនាបរិមាណចំណី',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Siemreap',
                ),
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
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Siemreap'),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ចំណីដែលត្រូវផ្តល់ឱ្យ $selectedAnimal',
            style: const TextStyle(fontFamily: 'Siemreap', fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            '${totalFeed.toStringAsFixed(2)} គ.ក',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const Text(
            'ក្នុងមួយថ្ងៃ (ប៉ាន់ស្មាន)',
            style: TextStyle(
              fontFamily: 'Siemreap',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
