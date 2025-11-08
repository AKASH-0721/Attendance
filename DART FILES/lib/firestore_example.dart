import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreExample extends StatefulWidget {
  @override
  _FirestoreExampleState createState() => _FirestoreExampleState();
}

class _FirestoreExampleState extends State<FirestoreExample> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();

  /// 🔹 Add data into users/{userId}/uzer
  Future<void> addUserData() async {
    String userDocId =
        "user123"; // 👈 your user id (can be FirebaseAuth uid later)

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userDocId)
        .collection("uzer")
        .add({
          "name": nameCtrl.text,
          "age": int.tryParse(ageCtrl.text) ?? 0,
          "createdAt": FieldValue.serverTimestamp(),
        });
  }

  /// 🔹 Read data from users/{userId}/uzer
  Stream<QuerySnapshot> getUserData(String userDocId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userDocId)
        .collection("uzer")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    String userDocId = "user123"; // 👈 same user id as above

    return Scaffold(
      appBar: AppBar(title: Text("Firestore Example")),
      body: Column(
        children: [
          // 🔹 Input fields
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: "Enter Name"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: ageCtrl,
              decoration: InputDecoration(labelText: "Enter Age"),
              keyboardType: TextInputType.number,
            ),
          ),

          // 🔹 Add Button
          ElevatedButton(onPressed: addUserData, child: Text("Add Data")),

          // 🔹 Display Data
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getUserData(userDocId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No data found"));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data["name"] ?? "No Name"),
                      subtitle: Text("Age: ${data["age"] ?? '-'}"),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
