import 'package:flutter/material.dart';

import 'upgrade_pro_screen.dart';

Future<void> openUpgradePro(
  BuildContext context, {
  bool replace = false,
}) async {
  final route = MaterialPageRoute<void>(
    builder: (_) => const UpgradeProScreen(),
  );
  if (replace) {
    await Navigator.of(context).pushReplacement(route);
  } else {
    await Navigator.of(context).push(route);
  }
}
