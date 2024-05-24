import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pdfLib;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../database/database.dart';

class InvoiceDetailPage extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailPage({Key? key, required this.invoiceId}) : super(key: key);

  @override
  _InvoiceDetailPageState createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late Future<Map<String, dynamic>> _invoiceFuture;
  late Future<List<Map<String, dynamic>>> _invoiceItemsFuture;

  @override
  void initState() {
    super.initState();
    _invoiceFuture = fetchInvoice();
    _invoiceItemsFuture = fetchInvoiceItems();
  }

  Future<Map<String, dynamic>> fetchInvoice() async {
    final db = await initDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'invoice_table',
      where: 'invoiceId = ?',
      whereArgs: [widget.invoiceId],
    );
    return result.isNotEmpty ? result.first : {};
  }

  Future<List<Map<String, dynamic>>> fetchInvoiceItems() async {
    final db = await initDatabase();
    final result = await db.query(
      'invoice_items_table',
      where: 'invoiceId = ?',
      whereArgs: [widget.invoiceId],
    );
    return result;
  }

  /*Future<void> saveAsPDF(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
    final pdf = pdfLib.Document();

    // Create a new page in the PDF document
    pdf.addPage(
      pdfLib.MultiPage(
        build: (context) => [
          pdfLib.Header(level: 0, text: 'Invoice Details'),
          pdfLib.Paragraph(text: 'Invoice ID: ${invoice['invoiceId']}'),
          pdfLib.Paragraph(text: 'Date: ${invoice['timestamp']}'),
          pdfLib.Paragraph(text: 'Total Bill: ${invoice['totalBill']}'),
          pdfLib.Header(level: 1, text: 'Invoice Items'),
          pdfLib.Table.fromTextArray(
            context: context,
            data: [
              ['Item Name', 'Quantity', 'Sell Price', 'Total Amount'],
              ...items.map(
                    (item) => [
                  item['itemName'],
                  item['itemQuantity'].toString(),
                  item['itemSellPrice'].toString(),
                  item['itemTotalAmount'].toString(),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // Get the path to the application's documents directory
    final outputDir = await getApplicationDocumentsDirectory();
    final outputPath = '${outputDir.path}/invoice_${widget.invoiceId}.pdf';

    // Save the PDF file
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invoice saved as PDF: $outputPath')),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List>(
        future: Future.wait([_invoiceFuture, _invoiceItemsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            // Extract the invoice and items from the snapshot data
            final List results = snapshot.data ?? [];
            final Map<String, dynamic> invoice = results[0] as Map<String, dynamic>;
            final List<Map<String, dynamic>> items = results[1] as List<Map<String, dynamic>>;

            if (invoice.isEmpty) {
              return const Center(child: Text("Invoice not found."));
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('Invoice ID: ${invoice['invoiceId']}'),
                Text('Date: ${invoice['timestamp']}'),
                Text('Total Bill: ${invoice['totalBill']}'),
                const SizedBox(height: 16),
                const Text(
                  'Invoice Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (var item in items)
                  ListTile(
                    title: Text('Item Name: ${item['itemName']}'),
                    subtitle: Text('Quantity: ${item['itemQuantity']}'),
                    trailing: Text('Total: ${item['itemTotalAmount']}'),
                  ),
                // ElevatedButton(
                //   onPressed: () {
                //     saveAsPDF(invoice, items);
                //   },
                //   child: const Text('Save as PDF'),
                // ),
              ],
            );
          }
        },
      ),
    );
  }
}
