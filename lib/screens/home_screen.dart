import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salonDora/screens/salon_profile.dart';
import 'package:salonDora/screens/auth/login_screen.dart';
import 'package:salonDora/services/auth_service.dart';
import 'package:salonDora/services/salon_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salonDora/screens/user_profile.dart';
import 'package:salonDora/screens/current_booking.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSalonSectionExpanded = false;
  bool _isLoggedinAlready = true;

  List<Map<String, dynamic>> _allSalons = [];
  List<Map<String, dynamic>> _displayedSalons = [];
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  final TextEditingController _searchController = TextEditingController();
  final SalonService _salonService = SalonService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _useLocationBasedSearch = true;

  @override
  void initState() {
    super.initState();
    _isLoggedIn();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchInitialData();
    _animationController.forward();
    WidgetsBinding.instance.addObserver(this);
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

        setState(() {});
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
      _updateMarkers();
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
          _updateMarkers();
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

  void _updateMarkers() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add salon markers
    for (int i = 0; i < _displayedSalons.length; i++) {
      final salon = _displayedSalons[i];
      if (salon['latitude'] != null && salon['longitude'] != null) {
        markers.add(
          Marker(
            markerId: MarkerId('salon_$i'),
            position: LatLng(salon['latitude'], salon['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: salon['salon_name'] ?? 'Unknown Salon',
              snippet: salon['salon_address'] ?? '',
            ),
            onTap: () => _onSalonMarkerTapped(salon),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  LatLng? _getSalonLocation(Map<String, dynamic> salon) {
    try {
      if (salon['latitude'] != null && salon['longitude'] != null) {
        final lat = double.tryParse(salon['latitude'].toString());
        final lng = double.tryParse(salon['longitude'].toString());
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }

      if (salon['distance'] != null) {
        final lat = double.tryParse(salon['lat']?.toString() ?? '');
        final lng = double.tryParse(salon['lng']?.toString() ?? '');
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
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
          return LatLng(lat, lon);
        }

        final pointRegex = RegExp(r'POINT\(([^\s]+)\s([^\)]+)\)');
        final pointMatch = pointRegex.firstMatch(locationStr);
        if (pointMatch != null) {
          final lng = double.tryParse(pointMatch.group(1) ?? '');
          final lat = double.tryParse(pointMatch.group(2) ?? '');
          if (lng != null && lat != null) {
            return LatLng(lat, lng);
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
        _currentLocation = LatLng(position.latitude, position.longitude);
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
      _currentLocation = LatLng(6.9271, 79.8612);
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
      _updateMarkers();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final filteredResults = _allSalons.where((salon) {
      final salonName = (salon['salon_name'] ?? '').toString().toLowerCase();
      return salonName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _displayedSalons = filteredResults;
      _isSearching = false;
    });
    _updateMarkers();
  }

  Future<void> _isLoggedIn() async {
    try {
      final isLoggedIn = await AuthService().isLoggedIn();
      setState(() {
        _isLoggedinAlready = isLoggedIn;
      });
    } catch (e) {
      setState(() {
        _isLoggedinAlready = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error checking login status: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
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
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double searchBarHeight = 80.0;
    final double bottomNavHeight =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final double availableHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        searchBarHeight -
        bottomNavHeight -
        60.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 60.0,
        title: Container(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 17.0),
            child: Image.asset(
              'images/header.jpg',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to text if image doesn't load
                return ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 0, 0, 0),
                      Color.fromARGB(255, 98, 98, 98),
                      Color.fromARGB(255, 255, 255, 255),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'SalonDora',
                    style: GoogleFonts.dancingScript(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 255, 255),
                Color.fromARGB(255, 255, 255, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshSalonsForLocation,
          ),
          IconButton(
            icon: _isLoggedinAlready
                ? Icon(Icons.logout, color: Colors.red)
                : Icon(Icons.login, color: Colors.green),
            onPressed: () async {
              if (!_isLoggedinAlready) {
                // Navigate to login and refresh when returning
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );

                // Refresh login status when returning from login screen
                _isLoggedIn();
              } else {
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
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ?? LatLng(6.9271, 79.8612),
                      zoom: _useLocationBasedSearch ? 14.0 : 13.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                  ),
                ),
                SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search a Salon...',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: _isSearching
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.purple,
                                                ),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          _searchController.text.isEmpty
                                              ? Icons.search
                                              : Icons.clear,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          if (_searchController
                                              .text
                                              .isNotEmpty) {
                                            _searchController.clear();
                                            _searchSalons('');
                                          }
                                        },
                                      ),
                              ),
                              onChanged: (value) {
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    if (_searchController.text == value) {
                                      _searchSalons(value);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        top: _isSalonSectionExpanded
                            ? searchBarHeight
                            : availableHeight,
                        left: 3,
                        right: 3,
                        bottom: _isSalonSectionExpanded ? 0 : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          constraints: BoxConstraints(
                            minHeight: _isSalonSectionExpanded ? 0 : 80.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isSalonSectionExpanded)
                                Container(
                                  width: 48,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _searchController.text.isEmpty
                                              ? (_useLocationBasedSearch
                                                    ? ''
                                                    : 'All Salons')
                                              : 'Search Results (${_displayedSalons.length})',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(
                                            _isSalonSectionExpanded
                                                ? Icons.keyboard_arrow_down
                                                : Icons.keyboard_arrow_up,
                                            size: 28,
                                            color: const Color.fromARGB(
                                              255,
                                              131,
                                              129,
                                              131,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isSalonSectionExpanded =
                                                  !_isSalonSectionExpanded;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    if (_useLocationBasedSearch &&
                                        _displayedSalons.isNotEmpty &&
                                        _isSalonSectionExpanded)
                                      Text(
                                        '${_displayedSalons.length} found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_isSalonSectionExpanded) ...[
                                if (_useLocationBasedSearch &&
                                    _currentLocation != null)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Showing salons near your location',
                                            style: GoogleFonts.poppins(
                                              color: Colors.green[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: _displayedSalons.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.store,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                _searchController.text.isEmpty
                                                    ? 'No salons available nearby'
                                                    : 'No salons found for "${_searchController.text}"',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (_useLocationBasedSearch) ...[
                                                const SizedBox(height: 16),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                          255,
                                                          0,
                                                          0,
                                                          0,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    setState(() {
                                                      _useLocationBasedSearch =
                                                          false;
                                                    });
                                                    await _fetchSalons();
                                                  },
                                                  child: Text(
                                                    'Show All Salons',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _displayedSalons.length,
                                          itemBuilder: (context, index) {
                                            final salon =
                                                _displayedSalons[index];
                                            final distance = salon['distance'];

                                            return FadeTransition(
                                              opacity: _fadeAnimation,
                                              child: Card(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12,
                                                  left: 8,
                                                  right: 8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 4,
                                                child: ListTile(
                                                  leading: Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child:
                                                        salon['salon_logo_link'] !=
                                                            null
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
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
                                                                    color: Colors
                                                                        .grey[600],
                                                                  ),
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons.store,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                  ),
                                                  title: Text(
                                                    salon['salon_name'] ??
                                                        'Unknown Salon',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        salon['salon_address'] ??
                                                            'Address not available',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                      ),
                                                      if (distance != null) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.location_on,
                                                              size: 14,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${(distance / 1000).toStringAsFixed(1)} km away',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.blue,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                      if (salon['average_rating'] !=
                                                          null) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              size: 14,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${salon['average_rating'].toStringAsFixed(1)}',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  trailing: const Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 16,
                                                    color: Color.fromARGB(
                                                      255,
                                                      0,
                                                      0,
                                                      0,
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      _onSalonMarkerTapped(
                                                        salon,
                                                      ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'My Bookings',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: 0,
          selectedItemColor: const Color.fromARGB(255, 96, 94, 94),
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          onTap: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrentBooking(),
                  ),
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
