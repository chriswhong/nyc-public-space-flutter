import 'package:flutter/material.dart';

class AppColors {
  static const Color pageBackground = Color.fromARGB(255, 242, 241, 246);
  static const Color dark = Color.fromARGB(255, 13, 13, 13);
  static const Color gray = Color.fromARGB(255, 165, 165, 165);
  static const Color green = Color(0xAA77bb3f);

  static const Color popsColor = Color(0xAA6b82d6);
  static const Color parkColor = Color(0xAA77bb3f);
  static const Color wpaaColor = Color(0xAA0ad6f5);
  static const Color plazaColor = Color(0xAAffbf47);
  static const Color stpColor = Color(0xAAF55353);
  static const Color miscColor = Color(0xAACCCCCC);
}

class AppStyles {
  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.green, // Set the button background color to green
    foregroundColor: Colors.white, // Set the button text color to white
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold, // Set the font weight
      fontSize: 16, // Optionally set the font size
    ),
  );
}
