import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:book_my_salon/utils/colors.dart';

class AppStyles {
  static final TextStyle headingStyle = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static final TextStyle subHeadingStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: AppColors.lightTextColor,
  );

  static final TextStyle appBarStyle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle sectionHeadingStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );

  static final TextStyle linkStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.secondaryColor,
    decoration: TextDecoration.underline,
  );
}
