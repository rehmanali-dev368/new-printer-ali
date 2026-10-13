import 'package:flutter/material.dart';

const pageTitleStyle = TextStyle(
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w600,
  fontSize: 24,
  letterSpacing: 0.24,
  color: Color(0xFF000000),
  height: 1,
);

double pageTopGap(BuildContext context) {
  final statusBar = MediaQuery.paddingOf(context).top;
  return (52 - statusBar).clamp(0.0, 52.0);
}
