import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/product_detail.dart';


class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      // 🎯 ១. ទាញយក "បង្គោល" SharedPreferences សិន
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        if (!prefsSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }


        // 🎯 ២. ទាញយក UID ដែលមេបាន Save ទុក
        final String currentUserId =
            prefsSnapshot.data!.getString('user_uid') ?? '';


        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "ទំនិញរក្សាទុក",
              style: TextStyle(fontFamily: 'Siemreap'),
            ),
            backgroundColor: Colors.green,
          ),
          // 🎯 ៣. ឆែកមើលក្នុង Firestore តាមរយៈ UID ដែលទាញបាន
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookmarks') // 🎯 ទាញពី Collection bookmarks
                .where(
              'userId',
              isEqualTo: currentUserId,
            ) // 🎯 ចម្រាញ់យកតែរបស់ User នោះ
                .orderBy(
              'savedAt',
              descending: true,
            ) // 🎯 ដាក់របស់ Save ថ្មីនៅមុនគេ
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return const Center(child: Text("មានបញ្ហា!"));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }


              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("មិនទាន់មានទំនិញរក្សាទុកនៅឡើយ"),
                );
              }


              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String docId = snapshot.data!.docs[index].id;


                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          (data['imageUrl'] is List)
                              ? data['imageUrl'][0]
                              : (data['imageUrl'] ?? ''),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image),
                        ),
                      ),
                      title: Text(
                        data['productName'] ?? 'គ្មានឈ្មោះ',
                        style: const TextStyle(
                          fontFamily: 'Siemreap',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${data['price']} ${data['currency'] ?? '៛'}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('bookmarks')
                              .doc(docId)
                              .delete();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: Map<String, dynamic>.from(data)
                                ..['id'] = data['productId'] ?? docId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}



