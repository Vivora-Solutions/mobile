import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salonDora/services/salon_service.dart';
import 'booking_screen.dart';

class SalonProfile extends StatefulWidget {
  final String salonId;
  final String salonName;

  const SalonProfile({
    required this.salonId,
    required this.salonName,
    super.key,
  });

  @override
  _SalonProfileState createState() => _SalonProfileState();
}

class _SalonProfileState extends State<SalonProfile> {
  late PageController _pageController;
  Map<String, dynamic>? salonData;
  List<Map<String, dynamic>> allServices = [];
  List<Map<String, dynamic>> filteredServices = [];
  Map<String, Map<String, dynamic>> selectedServices = {};
  bool isLoading = true;
  String? error;
  String selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  int get totalCost => selectedServices.values
      .map((service) => service['price'] as int)
      .fold(0, (a, b) => a + b);

  int get totalDuration => selectedServices.values
      .map((service) => service['duration_minutes'] as int)
      .fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.7,
      keepPage: true,
    );
    _searchController.addListener(_filterServicesBySearch);
    _loadSalonData();
  }

  Future<void> _loadSalonData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final results = await Future.wait([
        SalonService().getSalonById(widget.salonId),
        SalonService().getSalonServices(widget.salonId),
      ]);

      setState(() {
        salonData = results[0] as Map<String, dynamic>;
        allServices = results[1] as List<Map<String, dynamic>>;
        filteredServices = List.from(allServices);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _updateServices(String category) {
    setState(() {
      selectedCategory = category;

      if (category == 'All') {
        filteredServices = List.from(allServices);
      } else {
        List<String> categoryFilters = [];

        switch (category) {
          case 'Male':
            categoryFilters = ['men', 'unisex'];
            break;
          case 'Female':
            categoryFilters = ['women', 'unisex'];
            break;
          case 'Children':
            categoryFilters = ['children'];
            break;
          case 'Unisex':
            categoryFilters = ['unisex'];
            break;
          default:
            categoryFilters = [category.toLowerCase()];
        }

        filteredServices = allServices
            .where(
              (service) => categoryFilters.contains(
                service['service_category']?.toString().toLowerCase(),
              ),
            )
            .toList();
      }
      _filterServicesBySearch();
    });
  }

  void _filterServicesBySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredServices = selectedCategory == 'All'
            ? List.from(allServices)
            : allServices.where((service) {
                final categoryFilters = selectedCategory == 'Male'
                    ? ['men', 'unisex']
                    : selectedCategory == 'Female'
                        ? ['women', 'unisex']
                        : selectedCategory == 'Children'
                            ? ['children']
                            : selectedCategory == 'Unisex'
                                ? ['unisex']
                                : [selectedCategory.toLowerCase()];
                return categoryFilters.contains(
                    service['service_category']?.toString().toLowerCase());
              }).toList();
      } else {
        filteredServices = allServices
            .where(
              (service) =>
                  (service['service_name'] as String)
                      .toLowerCase()
                      .contains(query) &&
                  (selectedCategory == 'All' ||
                      (selectedCategory == 'Male' &&
                          ['men', 'unisex']
                              .contains(service['service_category']?.toString().toLowerCase())) ||
                      (selectedCategory == 'Female' &&
                          ['women', 'unisex']
                              .contains(service['service_category']?.toString().toLowerCase())) ||
                      (selectedCategory == 'Children' &&
                          ['children'].contains(
                              service['service_category']?.toString().toLowerCase())) ||
                      (selectedCategory == 'Unisex' &&
                          ['unisex'].contains(
                              service['service_category']?.toString().toLowerCase()))),
            )
            .toList();
      }
    });
  }

  bool _isServiceSelected(Map<String, dynamic> service) {
    final serviceName = service['service_name'] as String;
    return selectedServices.containsKey(serviceName);
  }

  void _toggleServiceSelection(Map<String, dynamic> service) {
    final serviceName = service['service_name'] as String;

    setState(() {
      if (selectedServices.containsKey(serviceName)) {
        selectedServices.remove(serviceName);
      } else {
        selectedServices[serviceName] = service;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $error',
                style: GoogleFonts.roboto(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              ElevatedButton(
                onPressed: _loadSalonData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<String> bannerImages = salonData?['banner_images'] != null
        ? (salonData!['banner_images'] as List)
              .map((img) => img['image_link'] as String?)
              .where((link) => link != null && link.isNotEmpty)
              .cast<String>()
              .toList()
        : ['https://placehold.co/400x300'];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: salonData?['salon_logo_link'] != null
                        ? Image.network(
                            salonData!['salon_logo_link'],
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.store,
                                size: 70,
                                color: Colors.grey[600],
                              );
                            },
                          )
                        : Icon(Icons.store, size: 70, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salonData?['salon_name'] ?? widget.salonName,
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                salonData?['salon_address'] ?? "Colombo",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (salonData?['average_rating'] != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 18, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                salonData!['average_rating'].toString(),
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (selectedServices.isEmpty) ...[
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: bannerImages.length,
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.hasClients &&
                              _pageController.position.hasPixels) {
                            final currentPage = _pageController.page ?? 0.0;
                            value = currentPage - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                          } else {
                            value =
                                _pageController.initialPage.toDouble() - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                          }
                          return Transform.scale(
                            scale: Curves.easeInOut.transform(value),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  bannerImages[index],
                                  fit: BoxFit.cover,
                                  width: 300,
                                  height: 300,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Center(
                                        child: Text(
                                          'Image Error',
                                          style: GoogleFonts.roboto(
                                            color: Colors.black54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                "Services",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['All', 'Male', 'Female'].map((category) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () => _updateServices(category),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategory == category
                              ? Colors.black
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          minimumSize: Size(100, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          textStyle: GoogleFonts.roboto(fontSize: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        child: Text(category),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Children', 'Unisex'].map((category) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () => _updateServices(category),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategory == category
                              ? Colors.black
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          minimumSize: Size(80, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          textStyle: GoogleFonts.roboto(fontSize: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        child: Text(category),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),
                  ),
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: selectedServices.isEmpty ? null : 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (filteredServices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No services available for ${selectedCategory.toLowerCase()} category',
                            style: GoogleFonts.roboto(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        ...filteredServices.map((service) {
                          final serviceName = service['service_name'] as String;
                          final price = service['price'] as int;
                          final duration = service['duration_minutes'] as int;
                          final category =
                              service['service_category'] as String?;
                          return CheckboxListTile(
                            title: Text(
                              serviceName,
                              style: GoogleFonts.roboto(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Rs $price • ${duration} min${category != null ? ' • ${category.toUpperCase()}' : ''}',
                              style: GoogleFonts.roboto(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            value: _isServiceSelected(service),
                            onChanged: (bool? value) {
                              _toggleServiceSelection(service);
                            },
                            activeColor: Colors.black,
                          );
                        }),
                    ],
                  ),
                ),
              ),
              if (selectedServices.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Services (${selectedServices.length})',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: selectedServices.values.map((service) {
                          return Chip(
                            label: Text(
                              service['service_name'],
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            deleteIcon: Icon(Icons.close, size: 16, color: Colors.white),
                            onDeleted: () => _toggleServiceSelection(service),
                            backgroundColor: Colors.black,
                            labelStyle: GoogleFonts.roboto(color: Colors.white),
                            deleteIconColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Duration",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      totalDuration >= 60
                          ? "${totalDuration ~/ 60} ${totalDuration ~/ 60 == 1 ? 'hour' : 'hours'}${totalDuration % 60 > 0 ? ' ${totalDuration % 60} min' : ''}"
                          : "${totalDuration} min",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Rs $totalCost",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 3,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0, // Elevation handled by Container's shadow
                    ),
                    onPressed: () {
                      final selectedServicesList = selectedServices.values.toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            salonId: widget.salonId,
                            salonName: salonData?['salon_name'] ?? widget.salonName,
                            selectedServices: selectedServicesList,
                            totalCost: totalCost,
                            totalDuration: totalDuration,
                            salonData: salonData,
                          ),
                        ),
                      );
                    },
                    child: const Text("Proceed"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}