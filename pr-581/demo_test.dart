import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/main.dart' as app;

import '../test/support/app_harness.dart';

bool recording = false;
int frame = 0;
final frames = Directory('${Directory.systemTemp.path}/streak_demo_frames');
DateTime last = DateTime(0);

Future<void> snap() async {
  final view = RendererBinding.instance.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final physical = view.flutterView.physicalSize;
  final image = await layer.toImage(Offset.zero & physical, pixelRatio: 1 / view.flutterView.devicePixelRatio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final name = 'f${frame.toString().padLeft(5, '0')}.png';
  File('${frames.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  File('${frames.path}/times.txt').writeAsStringSync(
    '$name ${DateTime.now().microsecondsSinceEpoch}\n',
    mode: FileMode.append,
  );
  frame++;
}

Future<void> hold(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 16));
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (recording && DateTime.now().difference(last).inMilliseconds >= 110) {
      last = DateTime.now();
      await snap();
    }
  }
}

void mark(String what) {
  print('DEMO $what');
  File('${Directory.systemTemp.path}/streak_demo_marks.txt')
      .writeAsStringSync('$what\n', mode: FileMode.append);
}

int forms(WidgetTester tester) =>
    find.byType(HabitFormPage, skipOffstage: false).evaluate().length;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('pr581 demo', (tester) async {
    await LocalStore.init();
    await LocalStore.writeSetting('onboardingDone', true);
    await LocalStore.writeHabit(testHabit(id: 'read', name: 'Read 20 pages', order: 0, done: lastDays(6)));
    await LocalStore.writeHabit(testHabit(id: 'walk', name: 'Evening walk', order: 1, done: lastDays(3)));
    await Hive.close();

    app.main();
    final view = tester.view;
    for (var i = 0; i < 150; i++) {
      await hold(tester, 100);
      if ((view.physicalSize / view.devicePixelRatio).width >= 900) break;
    }
    File('${Directory.systemTemp.path}/streak_demo_wide').writeAsStringSync('1');
    if (frames.existsSync()) frames.deleteSync(recursive: true);
    frames.createSync();
    recording = true;
    await hold(tester, 2500);
    mark('ready forms=${forms(tester)} logical=${view.physicalSize / view.devicePixelRatio}');

    final started = DateTime.now();
    for (var i = 0; i < 600 && find.byIcon(LucideIcons.plus).evaluate().isEmpty; i++) {
      await hold(tester, 100);
    }
    mark('home shown after ${DateTime.now().difference(started).inMilliseconds} ms');
    final add = find.byIcon(LucideIcons.plus).first;
    mark('plus icons=${find.byIcon(LucideIcons.plus).evaluate().length} first at ${tester.getCenter(add)}');
    for (var i = 1; i <= 3; i++) {
      await tester.tap(add, warnIfMissed: false);
      await hold(tester, 1800);
      mark('click $i forms=${forms(tester)}');
      if (i == 1) {
        final name = find.descendant(
          of: find.byType(HabitFormPage).last,
          matching: find.byType(TextField),
        ).first;
        await tester.enterText(name, 'Drink water');
        FocusManager.instance.primaryFocus?.unfocus();
        await hold(tester, 1500);
        mark('typed name');
      }
    }

    AppNavigator.pop();
    await hold(tester, 1800);
    mark('back once forms=${forms(tester)}');
    await hold(tester, 1500);
    mark('done');
  });
}
