import 'package:flutter/material.dart';
import 'package:frontendemart/models/UserLocation_model.dart';
import 'package:frontendemart/services/cart_service.dart';

class ChooseAddressScreen extends StatefulWidget {
  const ChooseAddressScreen({super.key});

  @override
  State<ChooseAddressScreen> createState() => _ChooseAddressScreenState();
}

class _ChooseAddressScreenState extends State<ChooseAddressScreen> {
  List<UserLocation> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final addresses = await CartService.getAddresses();
    setState(() => _addresses = addresses);
  }

  void _addAddressDialog() {
    final addressController = TextEditingController();
    final labelController = TextEditingController();
    final governorateController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add Address"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                TextField(
                  controller: governorateController,
                  decoration: const InputDecoration(labelText: "Governorate"),
                ),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: "Label (ex: Home, Work)"),
                ),
                TextField(
                  controller: latitudeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Latitude"),
                ),
                TextField(
                  controller: longitudeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Longitude"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newAddress = UserLocation(
                  userLocationID: DateTime.now().millisecondsSinceEpoch, // identifiant temporaire local
                  address: addressController.text,
                  userID: 0, // si pas encore de vrai user
                  labelName: labelController.text,
                  districtID: null,
                  latitude: latitudeController.text.isNotEmpty
                      ? double.tryParse(latitudeController.text)
                      : null,
                  longitude: longitudeController.text.isNotEmpty
                      ? double.tryParse(longitudeController.text)
                      : null,
                );

                await CartService.addAddress(newAddress);
                _loadAddresses();
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteAddress(int userLocationID) async {
    await CartService.removeAddress(userLocationID);
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Address"),
        backgroundColor: Colors.deepOrange,
      ),
      body: _addresses.isEmpty
          ? const Center(child: Text("No address saved"))
          : ListView.builder(
              itemCount: _addresses.length,
              itemBuilder: (ctx, i) {
                final addr = _addresses[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(addr.address),
                    subtitle: Text(
                      "${addr.labelName ?? ""}\nGovernorate: ${addr.districtID ?? "N/A"}\n"
                      "GPS: ${addr.latitude ?? "?"}, ${addr.longitude ?? "?"}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAddress(addr.userLocationID),
                    ),
                    onTap: () {
                      Navigator.pop(context, addr); // retourne l’adresse choisie
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: _addAddressDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
