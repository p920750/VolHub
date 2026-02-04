import 'package:flutter/material.dart';

class EventColors {
  // Background
  static const Color background = Color(0xFFE0F2F1); // Light Mint Green
  
  // Header / Navigation
  static const Color headerBackground = Color(0xFF001529); // Dark Blue/Black
  static const Color headerText = Colors.white;
  static const Color headerIcon = Colors.white;

  // Cards
  static const Color cardBackground = Color(0xFF1E4D40); // Dark Green
  static const Color cardText = Colors.white;
  static const Color cardLabel = Color(0xFFA5D6A7); // Light Green text for labels
  
  // Stats
  static const Color statValue = Colors.white;
  static const Color statLabel = Colors.white70;

  // Team Section
  static const Color teamCardBackground = Color(0xFF2C3E50); // Darker Blue-Grey for team list, or use cardBackground
  // Actually image shows same Dark Green for all cards
  
  // Status Labels
  static const Color statusPending = Color(0xFF757575);
  static const Color statusAccepted = Color(0xFF4CAF50);
  
  // Typography
  static const TextStyle itemsTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 24, 
    fontWeight: FontWeight.bold
  );
  
  static const TextStyle sectionHeaderStyle = TextStyle(
    color: Color(0xFF1E4D40),
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}
