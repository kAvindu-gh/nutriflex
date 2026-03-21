/// Holds all customer data collected on the Map page.
/// Plug this into REST, Riverpod, Provider, GetX — anything — later.
class OrderData {
  final String selectedStoreName;
  final String selectedStoreAddress;
  final double storeLat;
  final double storeLng;
  final double customerLat;
  final double customerLng;
  final String deliveryAddress;
  final DateTime confirmedAt;
 
  const OrderData({
    required this.selectedStoreName,
    required this.selectedStoreAddress,
    required this.storeLat,
    required this.storeLng,
    required this.customerLat,
    required this.customerLng,
    required this.deliveryAddress,
    required this.confirmedAt,
  });
 
  /// Convert to JSON — ready to POST to any backend endpoint.
  Map<String, dynamic> toJson() => {
        'selected_store': {
          'name': selectedStoreName,
          'address': selectedStoreAddress,
          'lat': storeLat,
          'lng': storeLng,
        },
        'customer_location': {
          'lat': customerLat,
          'lng': customerLng,
          'delivery_address': deliveryAddress,
        },
        'order_confirmed_at': confirmedAt.toIso8601String(),
      };
 
  @override
  String toString() => toJson().toString();
}