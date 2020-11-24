import 'package:meta/meta.dart';

bool isNumeric(String s) {
  return int.tryParse(s) != null;
}

bool isSymbol(String s) {
  final re = RegExp(r'[a-z]|[A-Z]|[0-9]|_');
  return re.hasMatch(s);
}

bool isVar(String s) {
  final re = RegExp(r'[A-Z]|_');
  return re.hasMatch(s);
}

enum TokenType {
  symbol,
  left_paren,
  right_paren,
  comma,
  let,
  period,
  number,
  left_bracket,
  right_bracket,
  variable,
  colon,
  minus,
  eof
}

@immutable
class Token {
  final TokenType type;
  final String text;

  Token(this.type, this.text);
}

Iterable<Token> lexer(String string) sync* {
  TokenType? currentType;
  var currentText = <String>[];

  for (final char in string.split('')) {
    if ((currentType == TokenType.symbol ||
            currentType == TokenType.variable) &&
        isSymbol(char)) {
      currentText.add(char);
      continue;
    }

    if (currentType == TokenType.number && isNumeric(char)) {
      currentText.add(char);
      continue;
    }

    if (currentType == TokenType.symbol && !isSymbol(char)) {
      currentType = null;
      yield Token(TokenType.symbol, currentText.join(''));
      currentText = [];
    }

    if (currentType == TokenType.variable && !isSymbol(char)) {
      currentType = null;
      yield Token(TokenType.variable, currentText.join(''));
      currentText = [];
    }

    if (currentType == TokenType.number && !isNumeric(char)) {
      currentType = null;
      yield Token(TokenType.number, currentText.join(''));
      currentText = [];
    }

    if (currentType == TokenType.let && char == '-') {
      currentType = null;
      currentText.add(char);
      yield Token(TokenType.let, currentText.join(''));
      currentText = [];
      continue;
    }

    if (currentType == TokenType.let && char != '-') {
      currentType = null;
      yield Token(TokenType.colon, ':');
    }

    switch (char) {
      case ' ':
        continue;
      case '(':
        currentType = TokenType.left_paren;
        currentText = ['('];
        break;
      case ')':
        currentType = TokenType.right_paren;
        currentText = [')'];
        break;
      case ',':
        currentType = TokenType.comma;
        currentText = [','];
        break;
      case ':':
        currentType = TokenType.let;
        currentText = [':'];
        continue;
      case '-':
        currentType = TokenType.minus;
        currentText = ['-'];
        continue;
      case '.':
        currentType = TokenType.period;
        currentText = ['.'];
        break;
      case '[':
        currentType = TokenType.left_bracket;
        currentText = ['['];
        break;
      case ']':
        currentType = TokenType.right_bracket;
        currentText = [']'];
        break;
    }
    if (currentType == null) {
      if (isVar(char)) {
        currentType = TokenType.variable;
      } else {
        currentType = TokenType.symbol;
      }
      currentText.add(char);
    } else {
      yield Token(currentType, currentText.join(''));
      currentType = null;
      currentText = [];
    }
  }

  if (currentType != null) {
    yield Token(currentType, currentText.join(''));
  }

  yield Token(TokenType.eof, '');
}
