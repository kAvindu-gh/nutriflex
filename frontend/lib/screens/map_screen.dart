import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import 'order_confirmation_screen.dart';

// ── Store data model ──────────────────────────────────────────────────────────
class NearbyStore {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double distanceKm;
  final String? phone;
  final String? openingHours;
  final int availabilityPercent;

  NearbyStore({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.phone,
    this.openingHours,
    required this.availabilityPercent,
  });

  factory NearbyStore.fromJson(Map<String, dynamic> j) => NearbyStore(
        id: j['id'] ?? '',
        name: j['name'] ?? 'Store',
        address: j['address'] ?? '',
        lat: (j['lat'] ?? 0).toDouble(),
        lng: (j['lng'] ?? 0).toDouble(),
        distanceKm: (j['distance_km'] ?? 0).toDouble(),
        phone: j['phone'],
        openingHours: j['opening_hours'],
        availabilityPercent: j['availability_percent'] ?? 85,
      );
}

// ── Pulsing map marker ────────────────────────────────────────────────────────
class _PulseMarker extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseMarker({required this.color, this.size = 18});
  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: widget.size + 14 + _pulse.value * 8,
            height: widget.size + 14 + _pulse.value * 8,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15 - _pulse.value * 0.1),
              shape: BoxShape.circle,
            ),
          ),
          // Inner ring
          Container(
            width: widget.size + 6,
            height: widget.size + 6,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          // Core dot
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Store card widget ─────────────────────────────────────────────────────────
class _StoreCard extends StatefulWidget {
  final NearbyStore store;
  final bool isSelected;
  final VoidCallback onSelect;

  const _StoreCard({
    required this.store,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<_StoreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final isSelected = widget.isSelected;
    final avail = store.availabilityPercent;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0D2818)
                : const Color(0xFF0A1A10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676).withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            (4.2 + math.Random(store.id.hashCode).nextDouble() *
                                    0.8)
                                .toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  store.address.isNotEmpty
                      ? store.address
                      : 'Address not available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Distance + hours + phone row
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: '${store.distanceKm} km away',
                      color: const Color(0xFF00E676),
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.access_time,
                      label: store.distanceKm < 1 ? '10-20 min' : '20-35 min',
                      color: Colors.white54,
                    ),
                  ],
                ),
                if (store.phone != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.phone_outlined,
                        label: store.phone!,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 10),
                      if (store.openingHours != null &&
                          store.openingHours != 'Hours not available')
                        _InfoChip(
                          icon: Icons.storefront_outlined,
                          label: store.openingHours!,
                          color: Colors.white54,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Availability bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ingredient Availability',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '$avail%',
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: avail / 100,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          avail >= 90
                              ? const Color(0xFF00E676)
                              : avail >= 75
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Select button
                GestureDetector(
                  onTap: widget.onSelect,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E676)
                            : const Color(0xFF00E676).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSelected ? 'Selected >' : 'Select Store >',
                          style: TextStyle(
                            color:
                                isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Warning note
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A00),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.withOpacity(0.8), size: 14),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Some ingredients may not be available. Next nearest store recommended.',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small info chip ───────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

// ── Main Map Screen ───────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double discount;
  final String? promoCode;

  const MapScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.discount = 0,
    this.promoCode,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _locationCtrl = TextEditingController();

  LatLng _userLocation = const LatLng(6.9271, 79.8612); // Colombo default
  String _locationName = 'Colombo 5, Sri Lanka';
  List<NearbyStore> _stores = [];
  NearbyStore? _selectedStore;
  bool _loadingLocation = true;
  bool _loadingStores = false;
  bool _changingLocation = false;
  bool _placingOrder = false;
  String? _locationError;

  // Animations
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final AnimationController _storesCtrl;
  late final Animation<double> _storesFade;
  late final AnimationController _mapCtrl;
  late final Animation<double> _mapScale;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);

    _storesCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _storesFade =
        CurvedAnimation(parent: _storesCtrl, curve: Curves.easeOut);

    _mapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _mapScale =
        CurvedAnimation(parent: _mapCtrl, curve: Curves.easeOutBack);

    _initLocation();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _storesCtrl.dispose();
    _mapCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Location init ──────────────────────────────────────────────────

  Future<void> _initLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _useDefaultLocation();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      await _updateLocation(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    _updateLocation(_userLocation);
  }

  Future<void> _updateLocation(LatLng loc) async {
    setState(() {
      _userLocation = loc;
      _loadingLocation = false;
    });

    // Animate map to new location
    _mapCtrl.forward(from: 0);
    try {
      _mapController.move(loc, 14.0);
    } catch (_) {}

    // Get address name
    final name = await ApiService.reverseGeocode(loc.latitude, loc.longitude);
    if (mounted) {
      setState(() => _locationName = name);
    }
    _headerCtrl.forward(from: 0);

    // Fetch stores
    await _fetchStores(loc);
  }

  Future<void> _fetchStores(LatLng loc) async {
    setState(() {
      _loadingStores = true;
      _stores = [];
      _selectedStore = null;
    });
    _storesCtrl.reset();

    try {
      final stores = await ApiService.getNearbyStores(
          loc.latitude, loc.longitude);
      if (mounted) {
        setState(() {
          _stores = stores;
          _loadingStores = false;
        });
        _storesCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStores = false);
    }
  }

  // ── Change location ────────────────────────────────────────────────

  void _showChangeLocationSheet() {
    setState(() => _changingLocation = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1A10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Location',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter an address or use your current GPS location',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 20),

            // GPS button
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _initLocation();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF00E676).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.my_location,
                        color: Color(0xFF00E676), size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Use My Current Location',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 13),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
              ],
            ),
            const SizedBox(height: 16),

            // Text search
            TextField(
              controller: _locationCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type an address...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
                filled: true,
                fillColor: const Color(0xFF111A13),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: const Color(0xFF00E676).withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF00E676)),
                ),
              ),
              onSubmitted: (val) {
                Navigator.pop(ctx);
                _searchAddress(val);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _searchAddress(_locationCtrl.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Search',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    ).whenComplete(() => setState(() => _changingLocation = false));
  }

  Future<void> _searchAddress(String address) async {
    if (address.trim().isEmpty) return;
    setState(() => _loadingLocation = true);

    final result = await ApiService.geocodeAddress(address.trim());
    if (result != null && mounted) {
      final loc = LatLng(result['lat'], result['lng']);
      setState(() => _locationName = result['display_name'] ?? address);
      await _updateLocation(loc);
    } else if (mounted) {
      setState(() => _loadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address not found. Try a different search.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Place order ────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (_selectedStore == null) return;
    setState(() => _placingOrder = true);

    try {
      final order = await ApiService.placeOrder(
        store: _selectedStore!,
        cartItems: widget.cartItems,
        subtotal: widget.subtotal,
        deliveryFee: widget.deliveryFee,
        total: widget.total,
        discount: widget.discount,
        promoCode: widget.promoCode,
      );

      if (!mounted) return;

      // Clear cart after order
      context.read<CartProvider>().fetchCart();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) =>
              OrderConfirmationScreen(order: order),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000302),
        body: Stack(
          children: [
            Column(
              children: [
                // ── MAP SECTION ─────────────────────────────────────────
                _buildMapSection(),

                // ── SCROLLABLE BOTTOM SHEET ─────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF060F08),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLocationRow(),
                                const SizedBox(height: 20),
                                _buildStoresSection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── TOP HEADER overlay ────────────────────────────────────
            _buildTopHeader(),

            // ── BOTTOM CONFIRM BUTTON ─────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildConfirmButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map section ───────────────────────────────────────────────────

  Widget _buildMapSection() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(_mapScale),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation,
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nutriflex.app',
                  additionalOptions: const {
                    'attribution':
                        '© OpenStreetMap contributors',
                  },
                ),
                MarkerLayer(
                  markers: [
                    // User marker
                    Marker(
                      point: _userLocation,
                      width: 44,
                      height: 44,
                      child: const _PulseMarker(color: Color(0xFF00E676)),
                    ),
                    // Store markers
                    ..._stores.map((store) => Marker(
                          point: LatLng(store.lat, store.lng),
                          width: 36,
                          height: 36,
                          child: _PulseMarker(
                            color: _selectedStore?.id == store.id
                                ? Colors.orange
                                : const Color(0xFF69F0AE),
                            size: 12,
                          ),
                        )),
                  ],
                ),
              ],
            ),

            // Dark overlay top gradient for header readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_loadingLocation)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E676)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Top header ────────────────────────────────────────────────────

  Widget _buildTopHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF111A13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF14D97D).withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF14D97D),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            FadeTransition(
              opacity: _headerFade,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Nearby Stores',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Select your preferred location',
                    style: TextStyle(
                        color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Location row ──────────────────────────────────────────────────

  Widget _buildLocationRow() {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2818).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00E676).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_pin,
                color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _locationName,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showChangeLocationSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF00E676).withOpacity(0.4)),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stores section ────────────────────────────────────────────────

  Widget _buildStoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _loadingStores
                  ? 'Nearby Stores'
                  : 'Nearby Stores(${_stores.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_loadingStores) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Color(0xFF00E676),
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingStores)
          _buildStoreShimmer()
        else if (_stores.isEmpty)
          _buildNoStores()
        else
          FadeTransition(
            opacity: _storesFade,
            child: Column(
              children: _stores
                  .map((s) => _StoreCard(
                        store: s,
                        isSelected: _selectedStore?.id == s.id,
                        onSelect: () => setState(() => _selectedStore = s),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildStoreShimmer() {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2818).withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildNoStores() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.store_outlined,
                color: Colors.white.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            const Text(
              'No stores found nearby',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _fetchStores(_userLocation),
              child: const Text('Try again',
                  style: TextStyle(color: Color(0xFF00E676))),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm button ────────────────────────────────────────────────

  Widget _buildConfirmButton() {
    final canConfirm = _selectedStore != null && !_placingOrder;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF060F08).withOpacity(0),
            const Color(0xFF060F08),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: canConfirm ? _placeOrder : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: canConfirm
                ? const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  )
                : null,
            color: canConfirm ? null : Colors.white12,
            borderRadius: BorderRadius.circular(18),
            boxShadow: canConfirm
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: _placingOrder
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    canConfirm
                        ? 'Confirm & Place Order'
                        : 'Select a Store to Continue',
                    style: TextStyle(
                      color: canConfirm ? Colors.black : Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}