class ItemModel {
  final String itemId;
  final String itemName;
  late final double itemQuantity;
  final double itemSize;
  final double itemBuyingPrice;
  late final double itemSellPrice;
  late final double itemTotalAmount;
  final double itemNumber;
  final DateTime? onCreate;

  ItemModel({
    required this.itemId,
    required this.itemName,
    required this.itemQuantity,
    required this.itemSize,
    required this.itemBuyingPrice,
    required this.itemSellPrice,
    required this.itemTotalAmount,
    required this.itemNumber,
    this.onCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemQuantity': itemQuantity,
      'itemSize': itemSize,
      'itemBuyingPrice': itemBuyingPrice,
      'itemSellPrice': itemSellPrice,
      'itemTotalAmount': itemTotalAmount,
      'itemNumber': itemNumber,
      'onCreate': onCreate?.toIso8601String(),
    };
  }

  /// Convert a map from the database into a Dart object (ItemModel).
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      itemId: map['itemId'],
      itemName: map['itemName'],
      itemQuantity: map['itemQuantity'] as double,
      itemSize: map['itemSize'] as double,
      itemBuyingPrice: map['itemBuyingPrice'] as double,
      itemSellPrice: map['itemSellPrice'] as double,
      itemTotalAmount: map['itemTotalAmount'] as double,
      itemNumber: map['itemNumber'] as double,
      onCreate: map.containsKey('onCreate') && map['onCreate'] != null
          ? DateTime.parse(map['onCreate'])
          : null,
    );
  }
}