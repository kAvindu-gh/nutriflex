import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'order_data.dart';
 
// ── Colour tokens ──────────────────────────────────────────────────────────────
const _bg = Color(0xFF0A1F0A);
const _card = Color(0xFF0F2A0F);
const _cardBorder = Color(0xFF1A4A1A);
const _accent = Color(0xFF2ECC71);
const _accentDim = Color(0xFF1A8A40);
const _textPrimary = Color(0xFFE8F5E8);
const _textSecondary = Color(0xFF7AAA7A);
const _warning = Color(0xFF8B6914);
const _warningBg = Color(0xFF2A1F00);
const _selected = Color(0xFF1A5A2A);
 
// ── Your Mapbox public token ───────────────────────────────────────────────────
// Replace with your actual pk.*** token
const _mapboxToken = 'pk.YOUR_TOKEN_HERE';
 
// ── Store model ────────────────────────────────────────────────────────────────
class StoreInfo {
  final String name, address, phone, hours;
  final double rating, distance, availability;
  final Position position; // Mapbox uses Position(lng, lat)
 
  const StoreInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.hours,
    required this.rating,
    required this.distance,
    required this.availability,
    required this.position,
  });
}
 
// Dummy store list — replace with backend fetch later
final _stores = [
  StoreInfo(
    name: 'FreshMart Organic',
    address: '123 Green Street, Colombo 5',
    phone: '+94 11 234 5678',
    hours: '8:00 AM - 10:00PM',
    rating: 4.8,
    distance: 0.8,
    availability: 0.95,
    position: Position(79.8584, 6.8955), // Position(lng, lat)
  ),
  StoreInfo(
    name: 'Keels Super Wellawatta',
    address: '564 Marine Street, Colombo 5',
    phone: '+94 11 234 5678',
    hours: '8:00 AM - 10:00PM',
    rating: 4.6,
    distance: 0.6,
    availability: 0.93,
    position: Position(79.8650, 6.8800),
  ),
];
 
// ── Customer location ──────────────────────────────────────────────────────────
const _customerLng = 79.8617;
const _customerLat = 6.8878;
const _customerAddress = 'Colombo 5, Sri Lanka';
 
// ── Page ───────────────────────────────────────────────────────────────────────
class MapPage extends StatefulWidget {
  final void Function(OrderData data)? onOrderConfirmed;
  const MapPage({super.key, this.onOrderConfirmed});
 
  @override
  State<MapPage> createState() => _MapPageState();
}
 
class _MapPageState extends State<MapPage> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  int _selectedIndex = 0;
 
  @override
  void initState() {
    super.initState();
    // Set token before map loads
    MapboxOptions.setAccessToken(_mapboxToken);
  }
 
  // Called once map is ready
  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _annotationManager =
        await map.annotations.createPointAnnotationManager();
    _addStoreMarkers();
  }
 
  void _addStoreMarkers() async {
    if (_annotationManager == null) return;
    await _annotationManager!.deleteAll();
 
    for (int i = 0; i < _stores.length; i++) {
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: _stores[i].position),
        iconSize: i == _selectedIndex ? 1.6 : 1.2,
        // Uses a built-in Mapbox marker icon
        iconImage: 'marker-15',
        iconColor: i == _selectedIndex ? 0xFF2ECC71 : 0xFF00BFFF,
        textField: _stores[i].name,
        textSize: 10,
        textColor: 0xFFE8F5E8,
        textOffset: [0.0, 2.0],
      );
      await _annotationManager!.create(options);
    }
  }
 
  void _selectStore(int index) {
    setState(() => _selectedIndex = index);
    // Fly camera to selected store
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: _stores[index].position),
        zoom: 15,
      ),
      MapAnimationOptions(duration: 600),
    );
    _addStoreMarkers(); // refresh marker sizes
  }
 
  OrderData _collectOrderData() {
    final store = _stores[_selectedIndex];
    return OrderData(
      selectedStoreName: store.name,
      selectedStoreAddress: store.address,
      storeLat: store.position.lat.toDouble(),
      storeLng: store.position.lng.toDouble(),
      customerLat: _customerLat,
      customerLng: _customerLng,
      deliveryAddress: _customerAddress,
      confirmedAt: DateTime.now(),
    );
  }
 
  void _onConfirm() {
    final data = _collectOrderData();
    widget.onOrderConfirmed?.call(data);
    debugPrint('📦 Order Data Collected:\n${data.toJson()}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _selected,
        content: Text(
          'Order confirmed at ${data.selectedStoreName}!',
          style: const TextStyle(color: _accent),
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.maybePop(context)),
            _MapView(onMapCreated: _onMapCreated),
            const _LocationChip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nearby Stores(${_stores.length})',
                  style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _stores.length,
                itemBuilder: (_, i) => _StoreCard(
                  store: _stores[i],
                  isSelected: i == _selectedIndex,
                  onSelect: () => _selectStore(i),
                ),
              ),
            ),
            _ConfirmButton(onTap: _onConfirm),
          ],
        ),
      ),
    );
  }
}
 
// ── Header ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentDim.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _accent, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find Nearby stores',
                  style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text('Select your preferred location',
                  style: TextStyle(color: _textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ── Map view ───────────────────────────────────────────────────────────────────
class _MapView extends StatelessWidget {
  final void Function(MapboxMap) onMapCreated;
  const _MapView({required this.onMapCreated});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: MapWidget(
        onMapCreated: onMapCreated,
        cameraOptions: CameraOptions(
          center: Point(
              coordinates: Position(_customerLng, _customerLat)),
          zoom: 13.5,
        ),
        // Dark style that matches your app theme
        styleUri: MapboxStyles.DARK,
      ),
    );
  }
}
 
// ── Location chip ──────────────────────────────────────────────────────────────
class _LocationChip extends StatelessWidget {
  const _LocationChip();
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_on_rounded, color: _accent, size: 18),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Location',
                  style: TextStyle(color: _textPrimary, fontSize: 13)),
              Text(_customerAddress,
                  style: TextStyle(color: _textSecondary, fontSize: 11)),
            ],
          ),
          Spacer(),
          Text('Change',
              style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
 
// ── Store card ─────────────────────────────────────────────────────────────────
class _StoreCard extends StatelessWidget {
  final StoreInfo store;
  final bool isSelected;
  final VoidCallback onSelect;
 
  const _StoreCard({
    required this.store,
    required this.isSelected,
    required this.onSelect,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? _selected : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? _accent : _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(store.name,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 3),
              Text(store.rating.toString(),
                  style: const TextStyle(color: Colors.amber, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(store.address,
              style: const TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: _textSecondary, size: 14),
              const SizedBox(width: 4),
              Text('${store.distance} km away',
                  style: const TextStyle(color: _textSecondary, fontSize: 11)),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded,
                  color: _textSecondary, size: 14),
              const SizedBox(width: 4),
              const Text('15-20 min',
                  style: TextStyle(color: _textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: _textSecondary, size: 14),
              const SizedBox(width: 4),
              Text(store.phone,
                  style: const TextStyle(color: _textSecondary, fontSize: 11)),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded,
                  color: _textSecondary, size: 14),
              const SizedBox(width: 4),
              Text(store.hours,
                  style: const TextStyle(color: _textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Ingredient Availability',
                  style: TextStyle(color: _textSecondary, fontSize: 11)),
              const Spacer(),
              Text('${(store.availability * 100).toInt()}%',
                  style: const TextStyle(color: _accent, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: store.availability,
              backgroundColor: _cardBorder,
              valueColor: const AlwaysStoppedAnimation(_accent),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onSelect,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? null : Border.all(color: _cardBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                isSelected ? 'Selected >' : 'Select Store >',
                style: TextStyle(
                  color: isSelected ? Colors.black : _textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _warningBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _warning.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _warning, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Some ingredients may not be available. Next nearest store: HealthyLife Store',
                    style: TextStyle(color: _warning, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Confirm button ─────────────────────────────────────────────────────────────
class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfirmButton({required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Confirm & Place Order',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
        ),
      ),
    );
  }
}