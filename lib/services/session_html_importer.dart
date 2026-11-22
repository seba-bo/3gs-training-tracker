import 'package:html/parser.dart' as html_parser;

class SessionHtmlImporter {
  static List<String> extractMemberNames(String html) {
    final document = html_parser.parse(html);
    final table = document.querySelector('#training-data-table');
    if (table == null) return const [];

    final names = <String>[];
    final seen = <String>{};

    for (final row in table.querySelectorAll('tbody tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;

      final name = cells[1].text.trim();
      if (name.isEmpty) continue;

      final key = name.toLowerCase();
      if (seen.add(key)) names.add(name);
    }

    return names;
  }
}
