import 'dart:io';

class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();


  static const String baseUrl = 'https://backend-2-o7e5.onrender.com/api';

  //  Base URL configuration
   static String get baseUrl {
     if (Platform.isAndroid) {
       return 'http://10.0.2.2:3000/api'; // Android emulator
     } else if (Platform.isIOS) {
       return 'http://localhost:3000/api'; // iOS simulator
     } else {
       return 'http://localhost:3000/api'; // Web/Desktop
     }
   }

}