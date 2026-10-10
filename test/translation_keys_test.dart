import 'dart:io';

import 'package:edunest/core/translations/app_translations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every literal `'area.key'.tr` / `.trp(` in lib must exist in English, or families see raw keys.
void main() {
  test('literal translation keys all exist in English', () {
    final english = AppTranslations().keys['en']!;
    final pattern = RegExp(r"'([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)'\s*\.\s*(?:tr|trp)\b");
    final missing = <String>{};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final m in pattern.allMatches(file.readAsStringSync())) {
        if (!english.containsKey(m.group(1))) missing.add('${m.group(1)}  (${file.path})');
      }
    }
    expect(missing, isEmpty);
  });
}
