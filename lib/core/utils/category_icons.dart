import 'package:flutter/material.dart';

/// Resolves persisted icon identifiers to compile-time Material icons.
///
/// Keeping the allowed set finite lets Flutter tree-shake its icon font in
/// release builds while categories can still store a small serializable value.
IconData categoryIcon(int codePoint) {
  for (final icon in categoryIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.category_rounded;
}

const categoryIcons = <IconData>[
  Icons.restaurant_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.movie_rounded,
  Icons.receipt_long_rounded,
  Icons.favorite_rounded,
  Icons.school_rounded,
  Icons.flight_rounded,
  Icons.more_horiz_rounded,
  Icons.payments_rounded,
  Icons.laptop_mac_rounded,
  Icons.business_center_rounded,
  Icons.trending_up_rounded,
  Icons.add_circle_rounded,
  Icons.home_rounded,
  Icons.sports_esports_rounded,
  Icons.pets_rounded,
  Icons.local_cafe_rounded,
  Icons.work_rounded,
  Icons.wallet_rounded,
];
