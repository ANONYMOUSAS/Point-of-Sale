import 'package:flutter/material.dart';
import '../database/database.dart';
import 'invoice_detail_page.dart';

class InvoiceHistory extends StatefulWidget {
  const InvoiceHistory({Key? key}) : super(key: key);

  @override
  _InvoiceHistoryState createState() => _InvoiceHistoryState();
}

class _InvoiceHistoryState extends State<InvoiceHistory> {
  late Future<List<Map<String, dynamic>>> _invoicesFuture;

  @override
  void initState() {
    super.initState();
    _invoicesFuture = fetchInvoices();
  }

  Future<List<Map<String, dynamic>>> fetchInvoices() async {
    final db = await initDatabase();
    final invoices = await db.query('invoice_table');
    return invoices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while data is being fetched
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show an error message if something goes wrong
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final invoices = snapshot.data ?? [];
            if (invoices.isEmpty) {
              return const Center(child: Text("No invoices available."));
            }

            return ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return ListTile(
                  title: Text("Invoice ID: ${invoice['invoiceId']}"),
                  subtitle: Text("Date: ${invoice['timestamp']}"),
                  trailing: Text("${invoice['totalBill']}"),
                  onTap: () {
                    // Navigate to the InvoiceDetailPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceDetailPage(
                          invoiceId: invoice['invoiceId'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
