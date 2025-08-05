import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:mobile/utils/styles.dart';
import 'package:mobile/widgets/salon_card.dart';
import 'package:mobile/screens/salon_profile.dart';
import 'package:mobile/screens/auth/login_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/salon_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/screens/user_profile.dart';
import 'package:mobile/screens/current_booking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  latLng.LatLng? _currentLocation;
  bool _isLoading = true;
  bool _isSearching = false;

  List<Map<String, dynamic>> _allSalons = [];
  List<Map<String, dynamic>> _displayedSalons = [];

  final TextEditingController _searchController = TextEditingController();
  final SalonService _salonService = SalonService();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchInitialLocation(), _fetchAllSalons()]);
  }

  Future<void> _fetchAllSalons() async {
    try {
      final salons = await _salonService.getAllSalons();
      setState(() {
        _allSalons = salons;
        _displayedSalons = salons;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading salons: ${e.toString().replaceAll('Exception: ', '')}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  Future<void> _searchSalons(String query) async {
    if (query.isEmpty) {
      setState(() {
        _displayedSalons = _allSalons;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final searchResults = await _salonService.searchSalonsByName(query);
      setState(() {
        _displayedSalons = searchResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Search error: ${e.toString().replaceAll('Exception: ', '')}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout error: ${e.toString().replaceAll('Exception: ', '')}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  Future<void> _fetchInitialLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _handleLocationError();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _handleLocationError();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = latLng.LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _handleLocationError();
    }
  }

  void _handleLocationError() {
    setState(() {
      _currentLocation = latLng.LatLng(6.9271, 79.8612); // Default to Colombo
      _isLoading = false;
    });
  }

  latLng.LatLng? _getSalonLocation(Map<String, dynamic> salon) {
    if (salon['location'] != null) {
      final locationStr = salon['location'].toString();
      final regex = RegExp(r'POINT\(([^\s]+)\s([^\)]+)\)');
      final match = regex.firstMatch(locationStr);
      if (match != null) {
        final lng = double.tryParse(match.group(1) ?? '');
        final lat = double.tryParse(match.group(2) ?? '');
        if (lng != null && lat != null) {
          return latLng.LatLng(lat, lng);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Book My Salon', style: AppStyles.appBarStyle.copyWith(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search a Salon...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                _searchController.text.isEmpty
                                    ? Icons.search
                                    : Icons.clear,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                if (_searchController.text.isNotEmpty) {
                                  _searchController.clear();
                                  _searchSalons('');
                                }
                              },
                            ),
                    ),
                    style: const TextStyle(color: Colors.black),
                    cursorColor: Colors.black,
                    onChanged: (value) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value) {
                          _searchSalons(value);
                        }
                      });
                    },
                  ),
                ),
                // Map
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      center: _currentLocation ?? latLng.LatLng(6.9271, 79.8612),
                      zoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.mobile',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_currentLocation != null)
                            Marker(
                              point: _currentLocation!,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.black,
                                size: 30.0,
                              ),
                            ),
                          ..._displayedSalons.map((salon) {
                            final salonLocation = _getSalonLocation(salon);
                            if (salonLocation == null) return null;
                            return Marker(
                              point: salonLocation,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SalonProfile(
                                        salonId: salon['salon_id'] ?? '',
                                        salonName:
                                            salon['salon_name'] ?? 'Unknown Salon',
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 30.0,
                                ),
                              ),
                            );
                          }).where((marker) => marker != null).cast<Marker>(),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nearby Salons Section
                Container(
                  height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Nearby Salons'
                              : 'Search Results (${_displayedSalons.length})',
                          style: AppStyles.sectionHeadingStyle.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _displayedSalons.isEmpty
                            ? Center(
                                child: Text(
                                  _searchController.text.isEmpty
                                      ? 'No salons available'
                                      : 'No salons found for "${_searchController.text}"',
                                  style: AppStyles.sectionHeadingStyle.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _displayedSalons.length,
                                itemBuilder: (context, index) {
                                  final salon = _displayedSalons[index];
                                  return SalonCard(
                                    name: salon['salon_name'] ?? 'Unknown Salon',
                                    address: salon['salon_address'] ??
                                        'Address not available',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SalonProfile(
                                            salonId: salon['salon_id'] ?? '',
                                            salonName:
                                                salon['salon_name'] ?? 'Unknown Salon',
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, color: Colors.black),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CurrentBooking()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserProfile()),
              );
              break;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}