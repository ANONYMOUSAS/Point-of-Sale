import 'package:flutter/material.dart';
import '../database/database.dart';
import '../model/items_Model.dart';
import 'forms/invoice_form.dart';
import 'forms/items_form.dart';
import 'invoice_history.dart'; // Import the InvoiceHistory screen

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<ItemModel>> _itemsFuture;
  List<ItemModel> _allItems = [];
  List<ItemModel> _displayedItems = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemsFuture = fetchItems();
  }

  Future<List<ItemModel>> fetchItems() async {
    final db = await initDatabase();
    final List<Map<String, dynamic>> maps = await db.query('item_table');

    // Convert List<Map<String, dynamic>> to List<ItemModel>
    List<ItemModel> items = maps.map((map) => ItemModel.fromMap(map)).toList();
    _allItems = items;
    _displayedItems = items;

    return items;
  }

  // Function to edit an item
  Future<void> editItem(ItemModel item) async {
    // Navigate to ItemsForm to edit the item
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemsForm(item: item),
      ),
    );

    // Refresh the list of items when returning from ItemsForm
    refreshItems();
  }

  // Function to delete an item
  Future<void> deleteItem(String itemId) async {
    final db = await initDatabase();
    try {
      await db.delete(
        'item_table',
        where: 'itemId = ?',
        whereArgs: [itemId],
      );
      // Refresh the list of items
      refreshItems();
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item deleted successfully")),
      );
    } catch (error) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete item: $error")),
      );
    }
  }

  // Refresh the list of items
  void refreshItems() {
    setState(() {
      _itemsFuture = fetchItems();
    });
  }

  // Search items based on the search query
  void searchItems(String query) {
    setState(() {
      if (query.isEmpty) {
        // If the query is empty, display all items
        _displayedItems = _allItems;
      } else {
        // Filter the items based on the query
        _displayedItems = _allItems.where((item) {
          return item.itemName.toLowerCase().contains(query.toLowerCase()) ||
              item.itemNumber.toString().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (query) {
            // Trigger search when the search query changes
            searchItems(query);
          },
        )
            : const Text("HomePage"),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                // If currently searching, clear search mode
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  searchItems(''); // Clear the search query
                });
              } else {
                // If not searching, activate search mode
                setState(() {
                  _isSearching = true;
                });
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 40.0,),
            ListTile(
              tileColor: Colors.green[200],
              leading: const Icon(Icons.receipt),
              title: const Text("Create Invoice"),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoiceForm()));
              },
            ),
            ListTile(
              tileColor: Colors.amberAccent,
              leading: const Icon(Icons.history),
              title: const Text("Invoice History"),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoiceHistory()));
              },
            ),
            ListTile(
              tileColor: Colors.red,
              leading: const Icon(Icons.remove),
              title: const Text("Delete DataBase"),
              onTap: ()async{
                await deleteAndRecreateDatabase();
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ItemModel>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while the data is being fetched
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show an error message if something went wrong
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            // If data is available, display it in a DataTable
            final items = _displayedItems;

            if (items.isEmpty) {
              return const Center(child: Text("No items available."));
            }

            // Calculate the total sum of itemTotalAmount
            double totalSum = items.fold(
              0,
                  (prev, element) => prev + element.itemTotalAmount,
            );

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                        columns: const [
                          // Columns definition
                          DataColumn(label: Text('Serial#')),
                          DataColumn(label: Text('Number')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Size')),
                          DataColumn(label: Text('Buy Price')),
                          DataColumn(label: Text('Sell Price')),
                          DataColumn(label: Text('Total Amount')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _displayedItems.asMap().map((index, item) {
                          return MapEntry(index, DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(item.itemNumber.toString())),
                              DataCell(Text(item.itemName)),
                              DataCell(Text(item.itemQuantity.toString())),
                              DataCell(Text(item.itemSize.toString())),
                              DataCell(Text(item.itemBuyingPrice.toString())),
                              DataCell(Text(item.itemSellPrice.toString())),
                              DataCell(Text(item.itemTotalAmount.toString())),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => editItem(item),
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteItem(item.itemId),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ));
                        }).values.toList(),
                      ),
                    ),
                  ),
                ),
                // Display the total sum at the bottom of the screen
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Total Sum: ${totalSum.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to ItemsForm to add a new item
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ItemsForm(),
            ),
          );
          // Refresh the list of items when returning from ItemsForm
          refreshItems();
        },
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
