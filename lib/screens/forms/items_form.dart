import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../customWidgets/customWidgets.dart';
import '../../database/database.dart';
import '../../model/items_Model.dart';
import '../homepage.dart';

class ItemsForm extends StatefulWidget {
  final ItemModel? item;

  const ItemsForm({super.key, this.item});

  @override
  _ItemsFormState createState() => _ItemsFormState();
}

class _ItemsFormState extends State<ItemsForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemQuantityController = TextEditingController();
  TextEditingController itemSizeController = TextEditingController();
  TextEditingController itemBuyingPriceController = TextEditingController();
  TextEditingController itemSellPriceController = TextEditingController();
  TextEditingController itemNumberController = TextEditingController();

  late Database _database;
  final uuid = const Uuid();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    initializeDatabase();
    if (widget.item != null) {
      isEditing = true;
      itemNameController.text = widget.item!.itemName;
      itemQuantityController.text = widget.item!.itemQuantity.toString();
      itemSizeController.text = widget.item!.itemSize.toString();
      itemBuyingPriceController.text = widget.item!.itemBuyingPrice.toString();
      itemSellPriceController.text = widget.item!.itemSellPrice.toString();
      itemNumberController.text = widget.item!.itemNumber.toString();
    }
  }

  @override
  void dispose() {
    // Clean up controllers when the form is disposed
    itemNameController.dispose();
    itemQuantityController.dispose();
    itemSizeController.dispose();
    itemBuyingPriceController.dispose();
    itemSellPriceController.dispose();
    itemNumberController.dispose();
    super.dispose();
  }

  Future<void> initializeDatabase() async {
    // await deleteAndRecreateDatabase();
    try {
      _database = await initDatabase();
      print("Database initialized successfully.");
    } catch (e) {
      print("Error initializing database: $e");
    }
  }


  Future<void> saveItem() async {
    if (formKey.currentState!.validate()) {
      // Calculate total amount (you can modify this calculation as per your requirements)
      final itemTotalPrice = (double.tryParse(itemQuantityController.text) ?? 0) *
          (double.tryParse(itemBuyingPriceController.text) ?? 0);

      final newItem = ItemModel(
        itemId: widget.item != null ? widget.item!.itemId : uuid.v4(),
        itemName: itemNameController.text,
        itemQuantity: double.tryParse(itemQuantityController.text) ?? 0,
        itemSize: double.tryParse(itemSizeController.text) ?? 0,
        itemBuyingPrice: double.tryParse(itemBuyingPriceController.text) ?? 0,
        itemSellPrice: double.tryParse(itemSellPriceController.text) ?? 0,
        itemNumber: double.tryParse(itemNumberController.text) ?? 0,
        itemTotalAmount: itemTotalPrice,
        onCreate: DateTime.now(),
      );

      // Convert the newItem to a map
      Map<String, dynamic> data = newItem.toMap();

      // Perform the insert or update operation
      try {
        if (widget.item != null) {
          await _database.update(
            'item_table',
            data,
            where: 'itemId = ?',
            whereArgs: [newItem.itemId],
          );
        } else {
          await _database.insert('item_table', data);
        }

        // Clear the text fields after successful operation
        itemNameController.clear();
        itemQuantityController.clear();
        itemSizeController.clear();
        itemBuyingPriceController.clear();
        itemSellPriceController.clear();
        itemNumberController.clear();

        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item Saved Successfully")));

        // Navigate back to HomePage
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false);
      } catch (error) {
        // Handle errors gracefully
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving item: $error")));
      }
    }
  }

  void checkDatabaseStructure() async {
    // Open your database
    Database db = await initDatabase();

    // List all tables
    List<Map<String, dynamic>> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
    print("Tables: $tables");

    // For each table, print the table schema
    for (var table in tables) {
      String tableName = table['name'];
      print("Schema of table $tableName:");

      // Query table schema
      List<Map<String, dynamic>> schema = await db.rawQuery("PRAGMA table_info($tableName);");
      print(schema);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item != null ? "Edit Item" : "Add Item"),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 100.0, horizontal: 10.0),
          elevation: 5.0,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10.0),
                CustomTextFormField(
                  controller: itemNameController,
                  labelText: "Item Name",
                  hintText: "Enter Item Name",
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.abc),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter item name";
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: itemNumberController,
                  labelText: "Item Number",
                  hintText: "Enter Item Number",
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.format_list_numbered_outlined),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter item Number";
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: itemQuantityController,
                  labelText: "Item Quantity",
                  hintText: "Enter Item Quantity",
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.numbers),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter item quantity";
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: itemSizeController,
                  labelText: "Item Size",
                  hintText: "Enter Item Size",
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.format_size),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                ),
                CustomTextFormField(
                  controller: itemBuyingPriceController,
                  labelText: "Item Buy Price",
                  hintText: "Enter Buy Price",
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.monetization_on),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter buy price";
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: itemSellPriceController,
                  labelText: "Item Sell Price",
                  hintText: "Enter Sell Price",
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.attach_money),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter sell price";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                CustomButton(
                  onPressed: saveItem,
                  child: Text(
                    widget.item != null ? "Update Item" : "Add Item",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20.0),
                  ),
                ),
                const SizedBox(height: 30.0,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
