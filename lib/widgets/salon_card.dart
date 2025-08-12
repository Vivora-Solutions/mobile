import 'package:flutter/material.dart';

class SalonCard extends StatelessWidget {
  final String name;
  final String address;
  // final String hours;
  final VoidCallback onTap;

  const SalonCard({
    required this.name,
    required this.address,
    // required this.hours,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          // Replace with a local asset or remove NetworkImage
          backgroundImage: const AssetImage(
            'images/placeholder.png',
          ),
          // Replace with a local asset or remove NetworkImage
          child: Icon(Icons.store, color: Colors.grey),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(hours), 
            Text('🌐 $address')
            ],
        ),
        onTap: onTap,
      ),
    );
  }
}
