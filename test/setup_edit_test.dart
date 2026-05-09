import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/setup_edit.dart';

void main() {
  group('validateInfoUrl', () {
    test('accepts null', () {
      expect(validateInfoUrl(null), isNull);
    });

    test('accepts empty string', () {
      expect(validateInfoUrl(''), isNull);
    });

    test('accepts whitespace-only string', () {
      expect(validateInfoUrl('   '), isNull);
    });

    test('accepts valid https URL', () {
      expect(validateInfoUrl('https://example.com/product'), isNull);
    });

    test('accepts valid http URL', () {
      expect(validateInfoUrl('http://example.com'), isNull);
    });

    test('rejects string with no scheme', () {
      expect(validateInfoUrl('example.com/product'), isNotNull);
    });

    test('rejects plain text', () {
      expect(validateInfoUrl('not a url at all'), isNotNull);
    });
  });
}
