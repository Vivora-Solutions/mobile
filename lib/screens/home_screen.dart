import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:book_my_salon/screens/salon_profile.dart';
import 'package:book_my_salon/screens/auth/login_screen.dart';
import 'package:book_my_salon/services/auth_service.dart';
import 'package:book_my_salon/services/salon_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:book_my_salon/screens/user_profile.dart';
import 'package:book_my_salon/screens/current_booking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  latLng.LatLng? _currentLocation;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSalonSectionExpanded = false; // Add state for expansion

  List<Map<String, dynamic>> _allSalons = [];
  List<Map<String, dynamic>> _displayedSalons = [];
  List<Map<String, dynamic>> _nearbySalons = [];

  final TextEditingController _searchController = TextEditingController();
  final SalonService _salonService = SalonService();

  bool _useLocationBasedSearch = true;

  ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    // Remove the scroll controller listener from here
  }

  Future<void> _fetchInitialData() async {
    await _fetchInitialLocation();
    await _fetchSalons();
  }

  Future<void> _fetchSalons() async {
    try {
      List<Map<String, dynamic>> salons;
      if (_useLocationBasedSearch && _currentLocation != null) {
        salons = await _salonService.getSalonsByLocation(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          radiusMeters: 10000,
        );

        setState(() {
          _nearbySalons = salons;
        });
      } else {
        salons = await _salonService.getAllSalons();
      }

      final transformedSalons = salons.map((salon) {
        final location = _getSalonLocation(salon);
        return {
          ...salon,
          'latitude': location?.latitude,
          'longitude': location?.longitude,
        };
      }).toList();

      setState(() {
        _allSalons = transformedSalons;
        _displayedSalons = transformedSalons;
      });
    } catch (e) {
      if (_useLocationBasedSearch) {
        try {
          final allSalons = await _salonService.getAllSalons();
          final transformedSalons = allSalons.map((salon) {
            final location = _getSalonLocation(salon);
            return {
              ...salon,
              'latitude': location?.latitude,
              'longitude': location?.longitude,
            };
          }).toList();
          setState(() {
            _allSalons = transformedSalons;
            _displayedSalons = transformedSalons;
            _useLocationBasedSearch = false;
          });
        } catch (fallbackError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error loading salons: ${fallbackError.toString().replaceAll('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading salons: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  latLng.LatLng? _getSalonLocation(Map<String, dynamic> salon) {
    try {
      if (salon['latitude'] != null && salon['longitude'] != null) {
        final lat = double.tryParse(salon['latitude'].toString());
        final lng = double.tryParse(salon['longitude'].toString());
        if (lat != null && lng != null) {
          return latLng.LatLng(lat, lng);
        }
      }

      if (salon['distance'] != null) {
        final lat = double.tryParse(salon['lat']?.toString() ?? '');
        final lng = double.tryParse(salon['lng']?.toString() ?? '');
        if (lat != null && lng != null) {
          return latLng.LatLng(lat, lng);
        }
      }

      if (salon['location'] != null) {
        final locationStr = salon['location'].toString();
        final bytes = hexToBytes(locationStr);
        if (bytes.length >= 21) {
          final byteData = ByteData.view(Uint8List.fromList(bytes).buffer);
          final byteOrder = bytes[0];
          Endian endian = byteOrder == 1 ? Endian.little : Endian.big;
          final type = byteData.getUint32(1, endian);
          int coordOffset = 9;
          if (type & 0x20000000 == 0x20000000) {
            coordOffset = 9;
          }
          final lon = byteData.getFloat64(coordOffset, endian);
          final lat = byteData.getFloat64(coordOffset + 8, endian);
          return latLng.LatLng(lat, lon);
        }

        final pointRegex = RegExp(r'POINT\(([^\s]+)\s([^\)]+)\)');
        final pointMatch = pointRegex.firstMatch(locationStr);
        if (pointMatch != null) {
          final lng = double.tryParse(pointMatch.group(1) ?? '');
          final lat = double.tryParse(pointMatch.group(2) ?? '');
          if (lng != null && lat != null) {
            return latLng.LatLng(lat, lng);
          }
        }
      }

      return null;
    } catch (e) {
      print('Error parsing salon location: $e');
      return null;
    }
  }

  List<int> hexToBytes(String hex) {
    hex = hex.replaceAll(' ', '');
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  Future<void> _refreshSalonsForLocation() async {
    if (_currentLocation != null) {
      setState(() {
        _isLoading = true;
      });
      await _fetchSalons();
      setState(() {
        _isLoading = false;
      });
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

      if (_currentLocation != null) {
        await _fetchSalons();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _handleLocationError();
    }
  }

  void _handleLocationError() {
    setState(() {
      _currentLocation = latLng.LatLng(6.9271, 79.8612);
      _useLocationBasedSearch = false;
      _isLoading = false;
    });

    _fetchSalons();
  }

  void _onSalonMarkerTapped(Map<String, dynamic> salon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalonProfile(
          salonId: salon['salon_id']?.toString() ?? '',
          salonName: salon['salon_name'] ?? 'Unknown Salon',
        ),
      ),
    );
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

    // Filter from _allSalons directly (case-insensitive)
    final filteredResults = _allSalons.where((salon) {
      final salonName = (salon['salon_name'] ?? '').toString().toLowerCase();
      return salonName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _displayedSalons = filteredResults;
      _isSearching = false;
    });
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
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'VIVORA',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshSalonsForLocation,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout == true) {
                _logout();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search a Salon...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                _searchController.text.isEmpty
                                    ? Icons.search
                                    : Icons.clear,
                              ),
                              onPressed: () {
                                if (_searchController.text.isNotEmpty) {
                                  _searchController.clear();
                                  _searchSalons('');
                                }
                              },
                            ),
                    ),
                    onChanged: (value) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value) {
                          _searchSalons(value);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location status indicator
                  if (_useLocationBasedSearch && _currentLocation != null)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Showing salons near your location',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_useLocationBasedSearch && _currentLocation != null)
                    const SizedBox(height: 16),

                  // Map (hidden when salon section is expanded)
                  if (!_isSalonSectionExpanded)
                    Expanded(
                      flex: 2,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              _currentLocation ??
                              latLng.LatLng(6.9271, 79.8612),
                          initialZoom: _useLocationBasedSearch ? 14.0 : 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: ['a', 'b', 'c'],
                            userAgentPackageName: 'com.example.book_my_salon',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_currentLocation != null)
                                Marker(
                                  point: _currentLocation!,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                              ..._displayedSalons
                                  .map((salon) {
                                    if (salon['latitude'] != null &&
                                        salon['longitude'] != null) {
                                      return Marker(
                                        point: latLng.LatLng(
                                          salon['latitude'],
                                          salon['longitude'],
                                        ),
                                        child: GestureDetector(
                                          onTap: () =>
                                              _onSalonMarkerTapped(salon),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.store,
                                              color: Colors.white,
                                              size: 20.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return null;
                                  })
                                  .where((marker) => marker != null)
                                  .cast<Marker>(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (!_isSalonSectionExpanded) const SizedBox(height: 16),

                  // Section heading with arrow icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            _searchController.text.isEmpty
                                ? (_useLocationBasedSearch
                                      ? 'Nearby Salons'
                                      : 'All Salons')
                                : 'Search Results (${_displayedSalons.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_useLocationBasedSearch &&
                              _searchController.text.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: IconButton(
                                icon: Icon(
                                  _isSalonSectionExpanded
                                      ? Icons.keyboard_arrow_down
                                      : Icons.keyboard_arrow_up,
                                  size: 24,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSalonSectionExpanded =
                                        !_isSalonSectionExpanded;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                      if (_useLocationBasedSearch &&
                          _displayedSalons.isNotEmpty)
                        Text(
                          '${_displayedSalons.length} found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Salon list with NotificationListener for scroll detection
                  Expanded(
                    flex: _isSalonSectionExpanded ? 3 : 1,
                    child: _displayedSalons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.store, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No salons available nearby'
                                      : 'No salons found for "${_searchController.text}"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_useLocationBasedSearch) ...[
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _useLocationBasedSearch = false;
                                      });
                                      await _fetchSalons();
                                    },
                                    child: Text('Show All Salons'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo is ScrollUpdateNotification) {
                                final scrollDelta = scrollInfo.scrollDelta ?? 0;

                                // Only trigger if scroll is significant (more than 5 pixels)
                                if (scrollDelta.abs() > 5) {
                                  if (scrollDelta > 0 &&
                                      !_isSalonSectionExpanded) {
                                    // Scrolling up - hide map
                                    setState(() {
                                      _isSalonSectionExpanded = true;
                                    });
                                  } else if (scrollDelta < 0 &&
                                      _isSalonSectionExpanded) {
                                    // Scrolling down - show map
                                    setState(() {
                                      _isSalonSectionExpanded = false;
                                    });
                                  }
                                }
                              }
                              return false; // Allow the notification to continue
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _displayedSalons.length,
                              itemBuilder: (context, index) {
                                final salon = _displayedSalons[index];
                                final distance = salon['distance'];

                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: salon['salon_logo_link'] != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                salon['salon_logo_link'],
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.store,
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.store,
                                              color: Colors.grey[600],
                                            ),
                                    ),
                                    title: Text(
                                      salon['salon_name'] ?? 'Unknown Salon',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          salon['salon_address'] ??
                                              'Address not available',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        if (distance != null) ...[
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${(distance / 1000).toStringAsFixed(1)} km away',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (salon['average_rating'] !=
                                            null) ...[
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Colors.amber,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${salon['average_rating'].toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () => _onSalonMarkerTapped(salon),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
    _scrollController.dispose();
    super.dispose();
  }
}
