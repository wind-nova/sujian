import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/home_page.dart';
import 'render/texture.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 纸纹噪声（190×190，生成一次全程复用）
  await TextureKit.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: C.ambient1,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SujianApp());
}

class SujianApp extends StatelessWidget {
  const SujianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '素笺',
      debugShowCheckedModeBanner: false,
      theme: SujianTheme.build(),
      home: const HomePage(),
      builder: (context, child) {
        // 锁定文字缩放：纸上的字是"画"不是"文"，不跟随系统字号
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
