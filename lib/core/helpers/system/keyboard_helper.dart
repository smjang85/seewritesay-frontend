import 'package:flutter/material.dart';

class KeyboardHelper {
  static void dismiss(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
