import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final outputDirPath = Platform.environment['SCREENSHOT_OUTPUT_DIR'] ??
      'test/metadata/en-US/images/phoneScreenshots';

  await integrationDriver(
    driver: driver,
    onScreenshot: (String name, List<int> image, [Map<String, Object?>? args]) async {
      final outputDir = Directory(outputDirPath);
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }
      final file = File('${outputDir.path}/$name.png');
      await file.writeAsBytes(image, flush: true);
      return true;
    },
  );
}
