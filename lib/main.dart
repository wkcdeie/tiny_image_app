import 'package:flutter/material.dart';
import 'package:yaru_widgets/widgets.dart';
import 'package:yaru/yaru.dart';
import 'theme.dart';
import 'home.dart';

void main() {
  YaruWindowTitleBar.ensureInitialized()
      .then((value) => runApp(InheritedYaruVariant(child: const MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      data: YaruThemeData(
        variant: InheritedYaruVariant.of(context),
      ),
      builder: (ctx, yaru, child) {
        return MaterialApp(
          title: 'TinyImage',
          debugShowCheckedModeBanner: false,
          theme: yaru.theme,
          darkTheme: yaru.darkTheme,
          highContrastTheme: yaruHighContrastLight,
          highContrastDarkTheme: yaruHighContrastDark,
          home: const HomePage(),
        );
      },
    );
  }
}
