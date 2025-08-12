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
  Map<String, bool> selectedServices = {};
  bool isLoading = true;
  String? error;
  String selectedCategory = 'All';

  int get totalCost => selectedServices.entries
      .where((e) => e.value)
      .map(
        (e) => filteredServices.firstWhere((s) => s['service_name'] == e.key)['price'] as int,
      )
      .fold(0, (a, b) => a + b);

  int get totalDuration => selectedServices.entries
      .where((e) => e.value)
      .map(
        (e) => filteredServices.firstWhere((s) => s['service_name'] == e.key)['duration_minutes'] as int,
      )
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
      for (var service in filteredServices) service['service_name'] as String: false,
    };
  }

  void _updateServices(String category) {
    setState(() {
      selectedCategory = category;

      if (category == 'All') {
        filteredServices = List.from(allServices);
      } else {
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
            .where((service) => service['service_category']?.toString().toLowerCase() == categoryFilter)
            .toList();
      }

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
        body: const Center(child: CircularProgressIndicator()),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
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
        : ['https://placehold.co/300x200'];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: Text(
                  "Book My Salon",
                  style: const TextStyle(
                    fontFamily: 'VivoraFont',
                    fontSize: 28,
                    color: Color.fromARGB(255, 0, 0, 0),
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
                              return const Icon(Icons.store, size: 50, color: Color.fromARGB(255, 0, 0, 0));
                            },
                          )
                        : const Icon(Icons.store, size: 50, color: Colors.grey),
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
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Color.fromARGB(255, 0, 0, 0)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                salonData?['salon_address'] ?? "Colombo",
                                style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (salonData?['average_rating'] != null)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                salonData!['average_rating'].toString(),
                                style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Text(
                                        'Image is not loading',
                                        style: TextStyle(color: Colors.white),
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
              const SizedBox(height: 24),
              const Text(
                "Services",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['All', 'Male', 'Female', 'Children', 'Unisex'].map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: ElevatedButton(
                      onPressed: () => _updateServices(category),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCategory == category ? Colors.grey[700] : Colors.grey[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(category, style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (filteredServices.isEmpty)
                const Text(
                  'No services available for selected category',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...filteredServices.map((service) {
                  final serviceName = service['service_name'] as String;
                  final price = service['price'] as int;
                  final duration = service['duration_minutes'] as int;
                  final category = service['service_category'] as String?;

                  return CheckboxListTile(
                    title: Text(serviceName, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                    subtitle: Text(
                      'Rs $price • ${duration} min${category != null ? ' • ${category.toUpperCase()}' : ''}',
                      style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    value: selectedServices[serviceName] ?? false,
                    activeColor: Colors.black,
                    checkColor: Colors.white,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  Text(
                    "${(totalDuration / 60).toStringAsFixed(1)} hours",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  Text(
                    "Rs $totalCost",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: selectedServices.values.contains(true)
                    ? () {
                        final selectedServicesList = allServices
                            .where((service) => selectedServices[service['service_name']] == true)
                            .toList();
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
                      }
                    : null,
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