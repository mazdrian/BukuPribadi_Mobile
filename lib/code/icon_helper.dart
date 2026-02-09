import 'package:flutter/material.dart';

/// Maps string icon keys to Material IconData.
/// Used by Category and Book models to store icons as strings in the database
/// while rendering them as proper Material Icons in the UI.
class IconHelper {
  IconHelper._();

  static const Map<String, IconData> _iconMap = {
    // Category icons - Expense
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'movie': Icons.movie_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'school': Icons.school_rounded,
    'more_horiz': Icons.more_horiz_rounded,

    // Category icons - Income
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'business_center': Icons.business_center_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'payments': Icons.payments_rounded,

    // Book icons
    'savings': Icons.savings_rounded,
    'attach_money': Icons.attach_money_rounded,
    'credit_card': Icons.credit_card_rounded,
    'account_balance': Icons.account_balance_rounded,
    'bar_chart': Icons.bar_chart_rounded,
    'trending_up': Icons.trending_up_rounded,
    'work': Icons.work_rounded,
    'track_changes': Icons.track_changes_rounded,
    'home': Icons.home_rounded,
    'commute': Icons.commute_rounded,
    'flight': Icons.flight_rounded,
    'graduation_cap': Icons.school_rounded,
    'checkroom': Icons.checkroom_rounded,
    'fastfood': Icons.fastfood_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'medical_services': Icons.medical_services_rounded,
    'favorite': Icons.favorite_rounded,
    'star': Icons.star_rounded,
    'pets': Icons.pets_rounded,
    'fitness_center': Icons.fitness_center_rounded,
  };

  /// Returns the IconData for a given icon key string.
  /// Falls back to [Icons.category_rounded] if the key is not found.
  static IconData getIcon(String key) {
    return _iconMap[key] ?? Icons.category_rounded;
  }

  /// Returns all available book icon keys.
  static List<String> get bookIconKeys => [
        'savings',
        'attach_money',
        'credit_card',
        'account_balance',
        'bar_chart',
        'trending_up',
        'work',
        'track_changes',
        'home',
        'commute',
        'flight',
        'graduation_cap',
        'checkroom',
        'fastfood',
        'shopping_cart',
        'medical_services',
      ];
}
