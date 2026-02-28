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
      final file = _uniqueScreenshotFile(outputDir, name);
      await file.writeAsBytes(image, flush: true);
      return true;
    },
  );
}

File _uniqueScreenshotFile(Directory outputDir, String baseName) {
  var candidate = File('${outputDir.path}/$baseName.png');
  if (!candidate.existsSync()) {
    return candidate;
  }

  var counter = 2;
  while (true) {
    candidate = File('${outputDir.path}/${baseName}_$counter.png');
    if (!candidate.existsSync()) {
      return candidate;
    }
    counter += 1;
  }
}
