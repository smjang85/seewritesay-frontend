import 'package:flutter/material.dart';

final primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.indigo,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

final outlinedIndigoButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: Colors.indigo,
  side: const BorderSide(color: Colors.indigo),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);