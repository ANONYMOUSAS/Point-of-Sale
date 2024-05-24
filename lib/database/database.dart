import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> deleteAndRecreateDatabase() async {
  final dbPath = await getDatabasesPath();
  final databasePath = join(dbPath, 'saad_saintry.db');

  try {
    // Delete the existing database file
    await deleteDatabase(databasePath);
    debugPrint("Database deleted successfully.");
  } catch (e) {
    debugPrint("Error deleting database: $e");
  }

  // Reinitialize the database
  await initDatabase();
  debugPrint("Database reinitialized successfully.");
}

Future<Database> initDatabase() async {
  final dbPath = await getDatabasesPath();
  final databasePath = join(dbPath, 'saad_saintry.db');

  // Attempt to open or create the database
  try {
    return await openDatabase(
        databasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create the `item_table` with appropriate columns
          await db.execute('''
                    CREATE TABLE item_table (
                        itemId TEXT PRIMARY KEY,
                        itemName TEXT NOT NULL,
                        itemQuantity REAL NOT NULL DEFAULT 0,
                        itemSize REAL,
                        itemBuyingPrice REAL NOT NULL DEFAULT 0,
                        itemSellPrice REAL NOT NULL DEFAULT 0,
                        itemTotalAmount REAL NOT NULL DEFAULT 0,
                        itemNumber REAL NOT NULL,
                        onCreate TEXT -- Storing date in ISO string format
                    )
                ''');
          debugPrint('Table `item_table` created successfully.');

          // Create `invoice_table` for storing invoice details
          await db.execute('''
                    CREATE TABLE invoice_table (
                        invoiceId TEXT PRIMARY KEY,
                        timestamp TEXT NOT NULL, -- ISO string date format
                        filePath TEXT NOT NULL,
                        totalBill REAL NOT NULL
                    )
                ''');
          debugPrint('Table `invoice_table` created successfully.');

          // Create `invoice_items_table` for storing invoice items
          await db.execute('''
                    CREATE TABLE invoice_items_table (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        invoiceId TEXT NOT NULL,
                        itemId TEXT NOT NULL,
                        itemName TEXT NOT NULL,
                        itemQuantity REAL NOT NULL DEFAULT 0,
                        itemSellPrice REAL NOT NULL DEFAULT 0,
                        itemTotalAmount REAL NOT NULL DEFAULT 0,
                        FOREIGN KEY (invoiceId) REFERENCES invoice_table (invoiceId),
                        FOREIGN KEY (itemId) REFERENCES item_table (itemId)
                    )
                ''');
          debugPrint('Table `invoice_items_table` created successfully.');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Handle schema changes and upgrades if required
          // Add your migration logic here if the version changes
          debugPrint("Upgrading database from version $oldVersion to $newVersion.");
          // Add upgrade logic here
        }
    );
  } catch (e) {
    debugPrint('Error initializing database: $e');
    // Handle fallback to in-memory database if necessary
    return await openDatabase(':memory:');
  }
}
