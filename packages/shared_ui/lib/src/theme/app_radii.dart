import 'package:flutter/material.dart';

@immutable
class AppRadii {
  const AppRadii({this.sm = 6, this.md = 12, this.lg = 20});

  static const AppRadii defaults = AppRadii();

  final double sm;
  final double md;
  final double lg;
}
