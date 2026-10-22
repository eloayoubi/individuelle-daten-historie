import 'dart:math' as math;

/// Werte eines Felds in einem Zeitfenster bis zum Eintrag: Summe oder Durchschnitt, `null` ohne Werte.
typedef FormulaWindow = double? Function(String name, double days, bool average);

/// Warum sich eine Formel nicht lesen lässt; die Texte stehen in den ARB-Dateien.
enum FormulaErrorKind { empty, unexpectedCharacter, unexpectedEnd, unexpectedToken, missingParenthesis, unknownFunction, argumentCount, unknownVariable, tooDeep }

class FormulaException implements Exception {
  const FormulaException(this.kind, this.position, [this.detail]);

  final FormulaErrorKind kind;

  /// Zeichenposition im Ausdruck (0-basiert).
  final int position;

  /// Z. B. der unbekannte Name.
  final String? detail;

  @override
  String toString() => 'FormulaException($kind at $position${detail == null ? '' : ': $detail'})';
}

/// Ein Rechenausdruck für Formel-Felder, z. B. `verbrauch * arbeitspreis + grundpreis * monate`.
///
/// - Zahlen mit Punkt oder Komma (`0,329`); Argumente trennt `;` oder `, ` (Komma mit Leerzeichen).
/// - `+ - * / ^`, Klammern, Vergleiche `< > <= >= = !=` (ergeben 1 oder 0).
/// - Funktionen: `min`, `max`, `abs`, `runden(x; stellen)`, `wurzel`, `wenn(bedingung; dann; sonst)`
///   (englisch auch `round`, `sqrt`, `if`); über Zeit `summe(feld; tage)` und `schnitt(feld; tage)`
///   (`sum`, `avg`) – Werte des Felds in den letzten Tagen bis zum Eintrag.
/// - Namen sind Feld-Kurznamen (siehe `Formulas.keyOf`) oder `verbrauch`, `tage`, `monate`.
///
/// Eigener Parser statt `eval`: nur Rechnen, keine Schleifen, Tiefe begrenzt.
class Formula {
  Formula._(this.source, this._root, this.variables);

  /// So tief dürfen Klammern und Aufrufe geschachtelt sein.
  static const maxDepth = 48;

  final String source;
  final _Node _root;

  /// Alle Namen, die der Ausdruck benutzt.
  final Set<String> variables;

  /// Liest den Ausdruck oder wirft [FormulaException] mit der Stelle.
  factory Formula.parse(String source) {
    final parser = _Parser(source);
    final root = parser.parse();
    final names = <String>{};
    root.collect(names);
    return Formula._(source, root, names);
  }

  /// `null`, wenn ein Name fehlt, durch 0 geteilt wird oder das Ergebnis keine Zahl ist.
  /// [window] liefert die Werte für `summe` und `schnitt`.
  double? evaluate(Map<String, double> values, {FormulaWindow? window}) {
    final result = _root.eval(values, window);
    return result != null && result.isFinite ? result : null;
  }
}

// ---------------------------------------------------------------------------------------------
// Zerlegen
// ---------------------------------------------------------------------------------------------

enum _T { number, name, op, open, close, separator, end }

class _Token {
  const _Token(this.type, this.text, this.position, [this.value]);

  final _T type;
  final String text;
  final int position;
  final double? value;
}

List<_Token> _tokenize(String s) {
  final tokens = <_Token>[];
  bool isDigit(int i) => i >= 0 && i < s.length && s.codeUnitAt(i) >= 48 && s.codeUnitAt(i) <= 57;
  bool isNameStart(String c) => RegExp(r'[A-Za-zÄÖÜäöüß_]').hasMatch(c);
  bool isNamePart(String c) => RegExp(r'[A-Za-zÄÖÜäöüß_0-9]').hasMatch(c);
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c.trim().isEmpty) {
      i++;
    } else if (isDigit(i) || (c == '.' && isDigit(i + 1))) {
      final start = i;
      var dot = false;
      while (i < s.length) {
        if (isDigit(i)) {
          i++;
        } else if (!dot && (s[i] == '.' || s[i] == ',') && isDigit(i + 1)) {
          // Komma direkt zwischen Ziffern ist eine Dezimalstelle (`0,329`), sonst ein Trenner.
          dot = true;
          i++;
        } else {
          break;
        }
      }
      final text = s.substring(start, i);
      tokens.add(_Token(_T.number, text, start, double.parse(text.replaceAll(',', '.'))));
    } else if (isNameStart(c)) {
      final start = i;
      while (i < s.length && isNamePart(s[i])) {
        i++;
      }
      tokens.add(_Token(_T.name, s.substring(start, i).toLowerCase(), start));
    } else if (c == '(') {
      tokens.add(_Token(_T.open, c, i++));
    } else if (c == ')') {
      tokens.add(_Token(_T.close, c, i++));
    } else if (c == ';' || c == ',') {
      tokens.add(_Token(_T.separator, c, i++));
    } else {
      final two = i + 1 < s.length ? s.substring(i, i + 2) : '';
      if (const ['<=', '>=', '==', '!=', '<>'].contains(two)) {
        tokens.add(_Token(_T.op, two == '<>' ? '!=' : (two == '==' ? '=' : two), i));
        i += 2;
      } else if ('+-*/^<>=×÷·'.contains(c)) {
        tokens.add(_Token(_T.op, switch (c) { '×' || '·' => '*', '÷' => '/', _ => c }, i++));
      } else {
        throw FormulaException(FormulaErrorKind.unexpectedCharacter, i, c);
      }
    }
  }
  tokens.add(_Token(_T.end, '', s.length));
  return tokens;
}

// ---------------------------------------------------------------------------------------------
// Lesen (Pratt-Parser)
// ---------------------------------------------------------------------------------------------

class _Parser {
  _Parser(this.source) : _tokens = _tokenize(source);

  final String source;
  final List<_Token> _tokens;
  var _i = 0;
  var _depth = 0;

  _Token get _peek => _tokens[_i];

  _Token _next() => _tokens[_i++];

  _Node parse() {
    if (_peek.type == _T.end) throw const FormulaException(FormulaErrorKind.empty, 0);
    final node = _expression(0);
    if (_peek.type != _T.end) throw FormulaException(FormulaErrorKind.unexpectedToken, _peek.position, _peek.text);
    return node;
  }

  static const _precedence = {'<': 1, '>': 1, '<=': 1, '>=': 1, '=': 1, '!=': 1, '+': 2, '-': 2, '*': 3, '/': 3, '^': 5};

  _Node _expression(int minPrecedence) {
    if (++_depth > Formula.maxDepth) throw FormulaException(FormulaErrorKind.tooDeep, _peek.position);
    var left = _unary();
    while (true) {
      final t = _peek;
      final p = t.type == _T.op ? _precedence[t.text] : null;
      if (p == null || p < minPrecedence) break;
      _next();
      // ^ bindet von rechts, Vergleiche lassen sich nicht verketten.
      final right = _expression(t.text == '^' ? p : p + 1);
      left = _Bin(t.text, left, right);
      if (p == 1 && _peek.type == _T.op && _precedence[_peek.text] == 1) {
        throw FormulaException(FormulaErrorKind.unexpectedToken, _peek.position, _peek.text);
      }
    }
    _depth--;
    return left;
  }

  _Node _unary() {
    if (_peek.type == _T.op && (_peek.text == '-' || _peek.text == '+')) {
      final sign = _next().text;
      // -2^2 = -4: Potenz vor Vorzeichen.
      final operand = _expression(4);
      return sign == '-' ? _Neg(operand) : operand;
    }
    return _primary();
  }

  _Node _primary() {
    final t = _next();
    switch (t.type) {
      case _T.number:
        return _Num(t.value!);
      case _T.name:
        if (_peek.type == _T.open) return _call(t);
        return _Var(t.text);
      case _T.open:
        final inner = _expression(0);
        if (_peek.type != _T.close) throw FormulaException(FormulaErrorKind.missingParenthesis, _peek.position);
        _next();
        return inner;
      case _T.end:
        throw FormulaException(FormulaErrorKind.unexpectedEnd, t.position);
      case _T.op || _T.close || _T.separator:
        throw FormulaException(FormulaErrorKind.unexpectedToken, t.position, t.text);
    }
  }

  static const _arity = {
    'min': (1, 99),
    'max': (1, 99),
    'abs': (1, 1),
    'runden': (1, 2),
    'round': (1, 2),
    'wurzel': (1, 1),
    'sqrt': (1, 1),
    'wenn': (3, 3),
    'if': (3, 3),
    'summe': (2, 2),
    'sum': (2, 2),
    'schnitt': (2, 2),
    'avg': (2, 2),
  };

  static const _windowed = {'summe', 'sum', 'schnitt', 'avg'};

  _Node _call(_Token name) {
    final arity = _arity[name.text];
    if (arity == null) throw FormulaException(FormulaErrorKind.unknownFunction, name.position, name.text);
    _next(); // (
    final args = <_Node>[];
    if (_peek.type != _T.close) {
      args.add(_expression(0));
      while (_peek.type == _T.separator) {
        _next();
        args.add(_expression(0));
      }
    }
    if (_peek.type != _T.close) throw FormulaException(FormulaErrorKind.missingParenthesis, _peek.position);
    _next();
    if (args.length < arity.$1 || args.length > arity.$2) throw FormulaException(FormulaErrorKind.argumentCount, name.position, name.text);
    // Zeitfenster brauchen einen Feldnamen als ersten Wert.
    if (_windowed.contains(name.text) && args.first is! _Var) throw FormulaException(FormulaErrorKind.argumentCount, name.position, name.text);
    return _Call(name.text, args);
  }
}

// ---------------------------------------------------------------------------------------------
// Rechnen
// ---------------------------------------------------------------------------------------------

sealed class _Node {
  double? eval(Map<String, double> v, FormulaWindow? w);

  void collect(Set<String> names);
}

class _Num extends _Node {
  _Num(this.value);

  final double value;

  @override
  double? eval(Map<String, double> v, FormulaWindow? w) => value;

  @override
  void collect(Set<String> names) {}
}

class _Var extends _Node {
  _Var(this.name);

  final String name;

  @override
  double? eval(Map<String, double> v, FormulaWindow? w) => v[name];

  @override
  void collect(Set<String> names) => names.add(name);
}

class _Neg extends _Node {
  _Neg(this.inner);

  final _Node inner;

  @override
  double? eval(Map<String, double> v, FormulaWindow? w) => switch (inner.eval(v, w)) {
    final double x => -x,
    null => null,
  };

  @override
  void collect(Set<String> names) => inner.collect(names);
}

class _Bin extends _Node {
  _Bin(this.op, this.left, this.right);

  final String op;
  final _Node left;
  final _Node right;

  @override
  double? eval(Map<String, double> v, FormulaWindow? w) {
    final a = left.eval(v, w), b = right.eval(v, w);
    if (a == null || b == null) return null;
    double flag(bool x) => x ? 1 : 0;
    return switch (op) {
      '+' => a + b,
      '-' => a - b,
      '*' => a * b,
      '/' => b == 0 ? null : a / b,
      '^' => math.pow(a, b).toDouble(),
      '<' => flag(a < b),
      '>' => flag(a > b),
      '<=' => flag(a <= b),
      '>=' => flag(a >= b),
      '=' => flag((a - b).abs() < 1e-9),
      '!=' => flag((a - b).abs() >= 1e-9),
      _ => null,
    };
  }

  @override
  void collect(Set<String> names) {
    left.collect(names);
    right.collect(names);
  }
}

class _Call extends _Node {
  _Call(this.fn, this.args);

  final String fn;
  final List<_Node> args;

  @override
  double? eval(Map<String, double> v, FormulaWindow? w) {
    if (fn == 'wenn' || fn == 'if') {
      // Nur der gewählte Zweig wird gerechnet – fehlende Werte im anderen stören nicht.
      final condition = args[0].eval(v, w);
      if (condition == null) return null;
      return (condition != 0 ? args[1] : args[2]).eval(v, w);
    }
    if (_Parser._windowed.contains(fn)) {
      final days = args[1].eval(v, w);
      if (w == null || days == null || days <= 0) return null;
      return w((args[0] as _Var).name, days, fn == 'schnitt' || fn == 'avg');
    }
    final values = <double>[];
    for (final a in args) {
      final x = a.eval(v, w);
      if (x == null) return null;
      values.add(x);
    }
    return switch (fn) {
      'min' => values.reduce(math.min),
      'max' => values.reduce(math.max),
      'abs' => values.first.abs(),
      'wurzel' || 'sqrt' => values.first < 0 ? null : math.sqrt(values.first),
      'runden' || 'round' => _round(values.first, values.length > 1 ? values[1].round().clamp(0, 6) : 0),
      _ => null,
    };
  }

  static double _round(double x, int digits) {
    final f = math.pow(10, digits);
    return (x * f).roundToDouble() / f;
  }

  @override
  void collect(Set<String> names) {
    for (final a in args) {
      a.collect(names);
    }
  }
}
