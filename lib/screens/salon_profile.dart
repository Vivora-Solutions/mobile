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
  List<Map<String, dynamic>> allServices = []; // Store all services
  List<Map<String, dynamic>> filteredServices = []; // Store filtered services
  Map<String, bool> selectedServices = {};
  bool isLoading = true;
  String? error;
  String selectedCategory = 'All'; // Default to show all services

  int get totalCost => selectedServices.entries
      .where((e) => e.value)
      .map(
        (e) =>
            filteredServices.firstWhere((s) => s['service_name'] == e.key)['price']
                as int,
      )
      .fold(0, (a, b) => a + b);

  int get totalDuration => selectedServices.entries
      .where((e) => e.value)
      .map(
        (e) =>
            filteredServices.firstWhere(
                  (s) => s['service_name'] == e.key,
                )['duration_minutes']
                as int,
      )
      .fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.7, // 70% of width for current image
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

      // Fetch salon details and services in parallel
      final results = await Future.wait([
        SalonService().getSalonById(widget.salonId),
        SalonService().getSalonServices(widget.salonId),
      ]);

      setState(() {
        salonData = results[0] as Map<String, dynamic>;
        allServices = results[1] as List<Map<String, dynamic>>;
        
        // Initially show all services
        filteredServices = List.from(allServices);
        
        // Initialize selected services map
        _initializeSelectedServices();
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _initializeSelectedServices() {
    selectedServices = {
      for (var service in filteredServices)
        service['service_name'] as String: false,
    };
  }

  void _updateServices(String category) {
    setState(() {
      selectedCategory = category;
      
      if (category == 'All') {
        filteredServices = List.from(allServices);
      } else {
        // Map the button text to actual category values in your database
        String categoryFilter;
        switch (category) {
          case 'Male':
            categoryFilter = 'men';
            break;
          case 'Female':
            categoryFilter = 'women';
            break;
          case 'Children':
            categoryFilter = 'children';
            break;
          case 'Unisex':
            categoryFilter = 'unisex';
            break;
          default:
            categoryFilter = category.toLowerCase();
        }
        
        filteredServices = allServices
            .where((service) => 
                service['service_category']?.toString().toLowerCase() == categoryFilter)
            .toList();
      }
      
      // Reset selected services for the new filtered list
      _initializeSelectedServices();
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
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: _loadSalonData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract banner images
    final List<String> bannerImages = salonData?['banner_images'] != null
        ? (salonData!['banner_images'] as List)
            .map((img) => img['image_link'] as String?)
            .where((link) => link != null && link.isNotEmpty)
            .cast<String>()
            .toList()
        : ['https://placehold.co/300x200']; // Fallback image

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
                              return Icon(Icons.store, size: 50, color: Colors.grey);
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
              
              // Horizontal Scrollable Image Gallery
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
                        if (_pageController.hasClients && _pageController.position.hasPixels) {
                          final currentPage = _pageController.page ?? 0.0;
                          value = currentPage - index;
                          value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                        } else {
                          // Before the controller is fully initialized, use the initial page
                          value = _pageController.initialPage.toDouble() - index;
                          value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                        }
                        return Transform.scale(
                          scale: Curves.easeInOut.transform(value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                    child: Center(
                                      child: Text('Image Error'),
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
              
              const SizedBox(height: 24),
              const Text(
                "Services",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Service Category Filter Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['All', 'Male', 'Female', 'Children', 'Unisex'].map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: ElevatedButton(
                      onPressed: () => _updateServices(category),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCategory == category ? Colors.black : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(category),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Dynamic services from API (filtered)
              if (filteredServices.isEmpty)
                Text('No services available for ${selectedCategory.toLowerCase()} category')
              else
                ...filteredServices.map((service) {
                  final serviceName = service['service_name'] as String;
                  final price = service['price'] as int;
                  final duration = service['duration_minutes'] as int;
                  final category = service['service_category'] as String?;
                  
                  return CheckboxListTile(
                    title: Text(serviceName),
                    subtitle: Text('Rs $price • ${duration} min${category != null ? ' • ${category.toUpperCase()}' : ''}'),
                    value: selectedServices[serviceName] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        selectedServices[serviceName] = value ?? false;
                      });
                    },
                  );
                }),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Duration",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${(totalDuration / 60).toStringAsFixed(1)} hours",
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                onPressed: selectedServices.values.contains(true) ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        salonName: salonData?['salon_name'] ?? widget.salonName,
                      ),
                    ),
                  );
                } : null,
                child: const Text(
                  "Proceed",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}