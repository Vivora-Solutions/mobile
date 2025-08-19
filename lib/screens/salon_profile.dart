import 'package:flutter/material.dart';
import 'package:book_my_salon/services/salon_service.dart';
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
  // Change to store service objects instead of just names
  Map<String, Map<String, dynamic>> selectedServices = {};
  bool isLoading = true;
  String? error;
  String selectedCategory = 'All';

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
      // No need to reinitialize selectedServices - they persist across filter changes
    });
  }

  // Helper method to check if a service is selected
  bool _isServiceSelected(Map<String, dynamic> service) {
    final serviceName = service['service_name'] as String;
    return selectedServices.containsKey(serviceName);
  }

  // Helper method to toggle service selection
  void _toggleServiceSelection(Map<String, dynamic> service) {
    final serviceName = service['service_name'] as String;

    setState(() {
      if (selectedServices.containsKey(serviceName)) {
        // Service is selected, remove it
        selectedServices.remove(serviceName);
      } else {
        // Service is not selected, add it
        selectedServices[serviceName] = service;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(onPressed: _loadSalonData, child: Text('Retry')),
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
        : ['https://placehold.co/300x200'];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: Text(
                  "VIVORA",
                  style: TextStyle(
                    fontFamily: 'VivoraFont',
                    fontSize: 28,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: salonData?['salon_logo_link'] != null
                        ? Image.network(
                            salonData!['salon_logo_link'],
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.store,
                                size: 50,
                                color: Colors.grey,
                              );
                            },
                          )
                        : Icon(Icons.store, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salonData?['salon_name'] ?? widget.salonName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                salonData?['salon_address'] ?? "Colombo",
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (salonData?['average_rating'] != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                salonData!['average_rating'].toString(),
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (selectedServices.isEmpty)...[
                SizedBox(
                  height: 200,
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
                                  width: 200,
                                  height: 200,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey,
                                      child: Center(child: Text('Image Error')),
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
              const Text(
                "Services",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['All', 'Male', 'Female', 'Children', 'Unisex'].map((
                  category,
                ) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: ElevatedButton(
                      onPressed: () => _updateServices(category),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCategory == category
                            ? Colors.black
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(category),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Scrollable services section
              SizedBox(
                height: selectedServices.isEmpty ? null : 300, // Constrain the height of the services section
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (filteredServices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No services available for ${selectedCategory.toLowerCase()} category',
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
                            title: Text(serviceName),
                            subtitle: Text(
                              'Rs $price • ${duration} min${category != null ? ' • ${category.toUpperCase()}' : ''}',
                            ),
                            value: _isServiceSelected(service),
                            onChanged: (bool? value) {
                              _toggleServiceSelection(service);
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ),
              // const SizedBox(height: 8),

              // Show selected services summary if any are selected
              if (selectedServices.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Services (${selectedServices.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      // const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: selectedServices.values.map((service) {
                          return Chip(
                            label: Text(
                              service['service_name'],
                              style: TextStyle(fontSize: 12),
                            ),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () => _toggleServiceSelection(service),
                            backgroundColor: Colors.black,
                            labelStyle: TextStyle(color: Colors.white),
                            deleteIconColor: Colors.white,
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
                    const Text(
                      "Duration",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      totalDuration >= 60
                          ? "${totalDuration ~/ 60} ${totalDuration ~/ 60 == 1 ? 'hour' : 'hours'}${totalDuration % 60 > 0 ? ' ${totalDuration % 60} min' : ''}"
                          : "${totalDuration} min",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Rs $totalCost",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    final selectedServicesList = selectedServices.values
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                          salonId: widget.salonId,
                          salonName:
                              salonData?['salon_name'] ?? widget.salonName,
                          selectedServices: selectedServicesList,
                          totalCost: totalCost,
                          totalDuration: totalDuration,
                          salonData: salonData,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Proceed",
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
