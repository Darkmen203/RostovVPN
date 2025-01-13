import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rostov_vpn/bootstrap.dart';
import 'package:rostov_vpn/core/model/environment.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  return lazyBootstrap(widgetsBinding, Environment.prod);
}
