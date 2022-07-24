import 'package:flutter/material.dart';

class Nav {
  /// Go back in the history
  static pop(BuildContext context) {
    NavigatorState nav = Navigator.of(context);
    if (!nav.canPop()) return;
    nav.pop();
  }

  static push(BuildContext context, Widget page, {replace = false}) {
    NavigatorState nav = Navigator.of(context);
    MaterialPageRoute route =
        MaterialPageRoute(builder: (BuildContext context) => page);
    replace ? nav.pushReplacement(route) : nav.push(route);
  }
}
