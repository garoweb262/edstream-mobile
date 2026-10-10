import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_theme.dart';
import 'package:edstream_mobile/presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await LocalCacheStore.instance.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const EdstreamApp());
}

class EdstreamApp extends StatelessWidget {
  const EdstreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edstream Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
