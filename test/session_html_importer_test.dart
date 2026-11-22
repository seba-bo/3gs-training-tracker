import 'package:flutter_test/flutter_test.dart';
import 'package:ipsc_training/services/session_html_importer.dart';

void main() {
  test('extracts unique members from Complete Training Data table', () {
    const html = '''
      <h2>Complete Training Data</h2>
      <table id="training-data-table">
        <tbody>
          <tr><td>1</td><td>Alice</td><td>Pistol</td></tr>
          <tr><td>2</td><td>Bob</td><td>Pistol</td></tr>
          <tr><td>3</td><td>Alice</td><td>Pistol</td></tr>
        </tbody>
      </table>
    ''';

    expect(SessionHtmlImporter.extractMemberNames(html), ['Alice', 'Bob']);
  });

  test('decodes HTML entities and ignores files without training table', () {
    const html = '''
      <table id="training-data-table">
        <tbody>
          <tr><td>1</td><td>A &amp; B</td><td>Pistol</td></tr>
        </tbody>
      </table>
    ''';

    expect(SessionHtmlImporter.extractMemberNames(html), ['A & B']);
    expect(SessionHtmlImporter.extractMemberNames('<h2>Other</h2>'), isEmpty);
  });
}
