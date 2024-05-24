import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../database/database.dart';
import '../../model/items_Model.dart';

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({Key? key}) : super(key: key);

  @override
  _InvoiceFormState createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemModel> _allItems = [];
  List<ItemModel> _searchResults = [];
  List<ItemModel> _invoiceItems = [];
  double _totalBill = 0.0;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  // Function to fetch all items from the database
  Future<void> fetchItems() async {
    final db = await initDatabase();
    final List<Map<String, dynamic>> maps = await db.query('item_table');
    _allItems = maps.map((map) => ItemModel.fromMap(map)).toList();
    setState(() {});
  }

  // Search function for items
  void searchItems(String query) {
    setState(() {
      _searchResults = _allItems.where((item) {
        return item.itemName.toLowerCase().contains(query.toLowerCase()) ||
            item.itemNumber.toString().contains(query);
      }).toList();
    });
  }

  // Function to add an item to the invoice
  void addItemToInvoice(ItemModel item, int quantity, double price) {
    double totalAmount = quantity * price;

    // Check if the item is already in the invoice
    final existingItemIndex = _invoiceItems.indexWhere((invItem) => invItem.itemId == item.itemId);

    if (existingItemIndex != -1) {
      // If the item is already in the invoice, update its quantity and total amount
      final existingItem = _invoiceItems[existingItemIndex];

      // Update the existing item's quantity, sell price, and total amount
      existingItem.itemQuantity += quantity;
      existingItem.itemSellPrice = price;
      existingItem.itemTotalAmount += totalAmount;

      // Update the total bill by adding the new total amount
      _totalBill += totalAmount;
    } else {
      // If the item is not in the invoice, add it as a new item
      _invoiceItems.add(ItemModel(
        itemId: item.itemId,
        itemNumber: item.itemNumber,
        itemName: item.itemName,
        itemQuantity: quantity.toDouble(),
        itemSize: item.itemSize,
        itemBuyingPrice: item.itemBuyingPrice,
        itemSellPrice: price,
        itemTotalAmount: totalAmount,
      ));

      // Update the total bill by adding the new total amount
      _totalBill += totalAmount;
    }

    setState(() {});
  }

  // Function to update an item in the invoice
  void updateItemInInvoice(int index, int quantity, double price) {
    final item = _invoiceItems[index];
    final oldTotalAmount = item.itemTotalAmount;

    // Update item's quantity, price, and total amount
    item.itemQuantity = quantity.toDouble();
    item.itemSellPrice = price;
    item.itemTotalAmount = quantity * price;

    // Update total bill by subtracting the old total amount and adding the new total amount
    _totalBill -= oldTotalAmount;
    _totalBill += item.itemTotalAmount;

    setState(() {});
  }


  // Function to generate and display the invoice
  Future<void> completeInvoice() async {
    // Check if there are items in the invoice
    if (_invoiceItems.isEmpty) {
      // If there are no items, show a message to the user and return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice cannot be empty. Please add items to the invoice.')),
      );
      return; // Exit the function early
    }

    try {
      // Load custom font and create PDF document
      final ttf = await rootBundle.load("assets/fonts/times.ttf");
      final font = pw.Font.ttf(ttf);
      final pdfDocument = pw.Document();

      // Create a unique invoice ID (use timestamp or another identifier)
      final invoiceId = DateTime.now().millisecondsSinceEpoch.toString();

      // Add a page to the PDF document
      pdfDocument.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Invoice', style: const pw.TextStyle(fontSize: 24)),
                  pw.SizedBox(height: 20),
                  pw.Text('Invoice ID: $invoiceId'), // Display invoice ID in the PDF
                  ..._invoiceItems.map((item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(item.itemName),
                      pw.Text('${item.itemQuantity} x ${item.itemSellPrice}'),
                      pw.Text(item.itemTotalAmount.toStringAsFixed(2)),
                    ],
                  )).toList(),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total:'),
                      pw.Text('PKR ${_totalBill.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // Get the appropriate directory for saving the file (already implemented)
      Directory? directory;
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted) {
          final fileName = 'invoice_$invoiceId.pdf';
          final filePath = '/$fileName';
          // Save invoice information to the database
          await saveInvoiceToDatabase(invoiceId, filePath);
          directory = await getExternalStorageDirectory();
        } else {
          // Handle permission denial
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required to save the invoice.')),
          );
          return;
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        // Generate file path and save the PDF file
        final fileName = 'invoice_$invoiceId.pdf';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(await pdfDocument.save());
        print(filePath);

        // Deduct item quantities and update database (already implemented)
        for (var item in _invoiceItems) {
          await deductItemQuantity(item);
        }

        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice created and saved as $fileName!')),
        );

        // Save invoice information to the database
        await saveInvoiceToDatabase(invoiceId, filePath);

        // Clear the invoice form
        clearInvoiceForm();
      } else {
        // Handle case where directory is null
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access storage directory.')),
        );
      }
    } catch (error) {
      // Handle errors during PDF generation or file operations
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating invoice: $error')),
      );
    }
  }

  Future<void> saveInvoiceToDatabase(String invoiceId, String filePath) async {
    // Retrieve the database instance
    final db = await initDatabase();

    try {
      // Start a transaction to ensure data integrity
      await db.transaction((txn) async {
        // Save the invoice to the database
        await txn.insert(
          'invoice_table', // Table name
          {
            'invoiceId': invoiceId, // Invoice ID
            'timestamp': DateTime.now().toString(), // Timestamp
            'filePath': filePath, // Path to the invoice PDF file
            'totalBill': _totalBill, // Total bill amount
            // You can add more metadata as needed
          },
        );

        // Save each item in the invoice to the database
        for (var item in _invoiceItems) {
          await txn.insert(
            'invoice_items_table', // Table name
            {
              'invoiceId': invoiceId, // Foreign key linking to the invoice
              'itemId': item.itemId, // Item ID
              'itemName': item.itemName, // Item name
              'itemQuantity': item.itemQuantity, // Item quantity
              'itemSellPrice': item.itemSellPrice, // Item sell price
              'itemTotalAmount': item.itemTotalAmount, // Total amount for the item
              // Add other item details as needed
            },
          );
        }
      });

      // Show a success message to the user if necessary
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Invoice saved successfully.')),
      // );
    } catch (e) {
      // Log the error
      print('Error saving invoice to database: $e');

      // Show an error message to the user
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to save invoice: $e')),
      // );
    }
  }


  // Function to deduct the quantity of an item from the store's inventory
  Future<void> deductItemQuantity(ItemModel invoiceItem) async {
    // Retrieve the existing database instance
    final db = await initDatabase();

    try {
      // Retrieve the current quantity and total price of the item from the database
      final List<Map<String, dynamic>> currentData = await db.query(
        'item_table',
        where: 'itemId = ?',
        whereArgs: [invoiceItem.itemId],
      );

      // Ensure there are results for the item in the database
      if (currentData.isNotEmpty) {
        final Map<String, dynamic> itemData = currentData.first;
        final double currentQuantity = itemData['itemQuantity'] as double;
        final double currentBuyingPrice = itemData['itemBuyingPrice'] as double;

        // Calculate the new quantity and total price of the item after the deduction
        final double newQuantity = currentQuantity - invoiceItem.itemQuantity;
        final double newTotalPrice = currentBuyingPrice * newQuantity;

        // Check if the new quantity is negative or insufficient
        if (newQuantity < 0) {
          // Display an error message and return
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Insufficient quantity for item: ${invoiceItem.itemName}")),
          );
          return;
        }

        // Update the item in the database with the new quantity and total price
        await db.update(
          'item_table',
          {
            'itemQuantity': newQuantity,
            'itemTotalAmount': newTotalPrice,
          },
          where: 'itemId = ?',
          whereArgs: [invoiceItem.itemId],
        );
      } else {
        // Handle the case where no item with the provided itemId exists in the database
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item not found in inventory: ${invoiceItem.itemName}")),
        );
      }
    } catch (error) {
      // Handle any other errors during database operations
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating item: $error")),
      );
    }
  }

  // Function to clear the invoice form
  void clearInvoiceForm() {
    setState(() {
      _invoiceItems = [];
      _totalBill = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search items...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: searchItems,
        ),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Display search results
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return ListTile(
                  title: Text(item.itemName),
                  subtitle: Text('Item Number: ${item.itemNumber}'),
                  onTap: () {
                    // When an item is tapped, prompt the user to input quantity and price
                    showDialog(
                      context: context,
                      builder: (context) {
                        final quantityController = TextEditingController();
                        final priceController = TextEditingController();
                        return AlertDialog(
                          title: const Text('Add Item to Invoice'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Current Quantity: ${item.itemQuantity}'), // Display item's current quantity
                                Text('Current Sell Price: ${item.itemSellPrice.toStringAsFixed(2)}'), // Display item's current sell price
                                const SizedBox(height: 10),
                                TextField(
                                  controller: quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Quantity'),
                                ),
                                TextField(
                                  controller: priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Price'),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // Get the quantity and price input
                                final int quantity = int.tryParse(quantityController.text) ?? 0;
                                final double price = double.tryParse(priceController.text) ?? 0.0;

                                if (quantity > 0 && price > 0) {
                                  // Add the item to the invoice
                                  addItemToInvoice(item, quantity, price);
                                  Navigator.of(context).pop();
                                } else {
                                  // Show an error message if inputs are invalid
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter valid quantity and price')),
                                  );
                                }
                              },
                              child: const Text('Add'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Close the dialog without adding the item
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Display invoice items and total bill
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _invoiceItems.length,
                    itemBuilder: (context, index) {
                      final item = _invoiceItems[index];
                      return ListTile(
                        title: Text(item.itemName),
                        subtitle: Text('Quantity: ${item.itemQuantity}, Price: ${item.itemSellPrice.toStringAsFixed(2)}'),
                        trailing: Text(item.itemTotalAmount.toStringAsFixed(2)),
                        onTap: () {
                          // Allow the user to edit the item
                          showDialog(
                            context: context,
                            builder: (context) {
                              final quantityController = TextEditingController(text: item.itemQuantity.toString());
                              final priceController = TextEditingController(text: item.itemSellPrice.toString());
                              return AlertDialog(
                                title: const Text('Edit Item in Invoice'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Current Quantity: ${item.itemQuantity}'), // Display item's current quantity
                                    Text('Current Sell Price: ${item.itemSellPrice.toStringAsFixed(2)}'), // Display item's current sell price
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Quantity'),
                                    ),
                                    TextField(
                                      controller: priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Price'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Get the updated quantity and price input
                                      final int quantity = int.tryParse(quantityController.text) ?? 0;
                                      final double price = double.tryParse(priceController.text) ?? 0.0;

                                      if (quantity > 0 && price > 0) {
                                        // Update the item in the invoice
                                        updateItemInInvoice(index, quantity, price);
                                        Navigator.of(context).pop();
                                      } else {
                                        // Show an error message if inputs are invalid
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter valid quantity and price')),
                                        );
                                      }
                                    },
                                    child: const Text('Update'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Close the dialog without updating the item
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'Total Bill: ${_totalBill.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: completeInvoice,
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        child: const Icon(Icons.check),
      ),
    );
  }
}