import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/store.dart';
import 'pages/home_page.dart';
import 'render/texture.dart';
import 'theme/skin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 纸纹噪声（190×190，生成一次全程复用）
  await TextureKit.init();

  // 本地数据：写过的每一篇 + 选中的主题
  await EntryStore.instance.load();
  await SkinStore.instance.load();

  _applySystemUi();
  SkinStore.instance.addListener(_applySystemUi);

  runApp(const SujianApp());
}

void _applySystemUi() {
  final dark = SkinStore.instance.current.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: SkinStore.instance.current.ambient2,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    ),
  );
}

class SujianApp extends StatelessWidget {
  const SujianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SkinStore.instance,
      builder: (context, _) {
        return MaterialApp(
          title: '素笺',
          debugShowCheckedModeBanner: false,
          theme: SujianTheme.build(),
          home: const HomePage(),
          builder: (context, child) {
            // 锁定文字缩放：纸上的字是"画"不是"文"
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
        );
      },
    );
  }
}
