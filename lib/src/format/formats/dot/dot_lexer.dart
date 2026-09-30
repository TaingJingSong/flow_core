/// Token types produced by [DotLexer].
enum DotTokenType {
  identifier,
  quotedString,
  htmlString,
  number,
  lbrace,
  rbrace,
  lbracket,
  rbracket,
  semicolon,
  comma,
  colon,
  equals,
  edgeDirected,
  edgeUndirected,
  eof,
}

class DotToken {
  const DotToken(this.type, this.value, this.position);

  final DotTokenType type;
  final String value;
  final int position;

  @override
  String toString() => 'DotToken($type, "$value")';
}

/// Tokenizes Graphviz DOT source.
class DotLexer {
  DotLexer(this.source);

  final String source;
  int _pos = 0;

  List<DotToken> tokenize() {
    final out = <DotToken>[];
    while (true) {
      _skipWhitespaceAndComments();
      if (_pos >= source.length) break;
      final c = source[_pos];
      final start = _pos;

      switch (c) {
        case '{':
          _pos++;
          out.add(DotToken(DotTokenType.lbrace, '{', start));
          continue;
        case '}':
          _pos++;
          out.add(DotToken(DotTokenType.rbrace, '}', start));
          continue;
        case '[':
          _pos++;
          out.add(DotToken(DotTokenType.lbracket, '[', start));
          continue;
        case ']':
          _pos++;
          out.add(DotToken(DotTokenType.rbracket, ']', start));
          continue;
        case ';':
          _pos++;
          out.add(DotToken(DotTokenType.semicolon, ';', start));
          continue;
        case ',':
          _pos++;
          out.add(DotToken(DotTokenType.comma, ',', start));
          continue;
        case '=':
          _pos++;
          out.add(DotToken(DotTokenType.equals, '=', start));
          continue;
        case ':':
          _pos++;
          out.add(DotToken(DotTokenType.colon, ':', start));
          continue;
        case '"':
          out.add(_readQuoted());
          continue;
        case '<':
          out.add(_readHtml());
          continue;
      }

      if (c == '-' && _pos + 1 < source.length) {
        final next = source[_pos + 1];
        if (next == '>') {
          _pos += 2;
          out.add(DotToken(DotTokenType.edgeDirected, '->', start));
          continue;
        }
        if (next == '-') {
          _pos += 2;
          out.add(DotToken(DotTokenType.edgeUndirected, '--', start));
          continue;
        }
      }

      if (_isNumberStart(c)) {
        out.add(_readNumber());
        continue;
      }
      if (_isIdentifierStart(c)) {
        out.add(_readIdentifier());
        continue;
      }

      throw FormatException('Unexpected character "$c" at position $_pos');
    }
    out.add(DotToken(DotTokenType.eof, '', source.length));
    return out;
  }

  void _skipWhitespaceAndComments() {
    while (_pos < source.length) {
      final c = source[_pos];
      if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
        _pos++;
        continue;
      }
      if (c == '/' && _pos + 1 < source.length) {
        final next = source[_pos + 1];
        if (next == '/') {
          _pos += 2;
          while (_pos < source.length && source[_pos] != '\n') {
            _pos++;
          }
          continue;
        }
        if (next == '*') {
          _pos += 2;
          while (_pos + 1 < source.length &&
              !(source[_pos] == '*' && source[_pos + 1] == '/')) {
            _pos++;
          }
          _pos = (_pos + 2).clamp(0, source.length);
          continue;
        }
      }
      if (c == '#') {
        while (_pos < source.length && source[_pos] != '\n') {
          _pos++;
        }
        continue;
      }
      break;
    }
  }

  DotToken _readQuoted() {
    final start = _pos;
    _pos++; // opening "
    final b = StringBuffer();
    while (_pos < source.length) {
      final c = source[_pos];
      if (c == '\\' && _pos + 1 < source.length) {
        final n = source[_pos + 1];
        if (n == '"') {
          b.write('"');
          _pos += 2;
          continue;
        }
        if (n == '\\') {
          b.write('\\');
          _pos += 2;
          continue;
        }
        if (n == 'n') {
          b.write('\n');
          _pos += 2;
          continue;
        }
        if (n == 't') {
          b.write('\t');
          _pos += 2;
          continue;
        }
        b.write(c);
        _pos++;
        continue;
      }
      if (c == '"') {
        _pos++;
        return DotToken(DotTokenType.quotedString, b.toString(), start);
      }
      b.write(c);
      _pos++;
    }
    throw FormatException('Unterminated quoted string at $start');
  }

  DotToken _readHtml() {
    final start = _pos;
    _pos++; // opening <
    var depth = 1;
    while (_pos < source.length && depth > 0) {
      final c = source[_pos];
      if (c == '<') {
        depth++;
      }
      else if (c == '>') {
        depth--;
      }
      _pos++;
    }
    if (depth > 0) {
      throw FormatException('Unterminated HTML string at $start');
    }
    final value = source.substring(start + 1, _pos - 1);
    return DotToken(DotTokenType.htmlString, value, start);
  }

  DotToken _readNumber() {
    final start = _pos;
    if (source[_pos] == '-') _pos++;
    while (_pos < source.length && _isDigit(source[_pos])) {
      _pos++;
    }
    if (_pos < source.length && source[_pos] == '.') {
      _pos++;
      while (_pos < source.length && _isDigit(source[_pos])) {
        _pos++;
      }
    }
    return DotToken(DotTokenType.number, source.substring(start, _pos), start);
  }

  DotToken _readIdentifier() {
    final start = _pos;
    while (_pos < source.length && _isIdentifierChar(source[_pos])) {
      _pos++;
    }
    return DotToken(DotTokenType.identifier, source.substring(start, _pos), start);
  }

  bool _isNumberStart(String c) {
    if (c == '-') {
      if (_pos + 1 >= source.length) return false;
      final n = source[_pos + 1];
      return _isDigit(n) || n == '.';
    }
    if (c == '.') {
      if (_pos + 1 >= source.length) return false;
      return _isDigit(source[_pos + 1]);
    }
    return _isDigit(c);
  }

  static bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  static bool _isIdentifierStart(String c) {
    final code = c.codeUnitAt(0);
    if (code >= 0x41 && code <= 0x5A) return true;
    if (code >= 0x61 && code <= 0x7A) return true;
    if (c == '_') return true;
    if (code >= 0x80) return true;
    return false;
  }

  static bool _isIdentifierChar(String c) {
    if (_isIdentifierStart(c)) return true;
    if (_isDigit(c)) return true;
    return false;
  }
}