import 'package:meta/meta.dart';

bool isNumeric(String s) {
  return int.tryParse(s) != null;
}

bool isSymbol(String s) {
  final re = RegExp(r'[a-z]|[A-Z]|[0-9]');
  return re.hasMatch(s);
}

bool isVar(String s) {
  final re = RegExp(r'[A-Z]|_');
  return re.hasMatch(s);
}

class TokenType {
  static final int SYMBOL = 0;
  static final int LEFT_PAREN = 1;
  static final int RIGHT_PAREN = 2;
  static final int COMMA = 3;
  static final int COLON = 4;
  static final int MINUS = 5;
  static final int PERIOD = 6;
  static final int NUMBER = 7;
  static final int LEFT_BRACKET = 8;
  static final int RIGHT_BRACKET = 9;
  static final int VARIABLE = 10;
}

class Precedence {
  static final int PERIOD = 1;
  static final int LET = 2;
  static final int COMMA = 3;
  static final int PAREN = 4;
}

@immutable
class Token {
  final int type;
  final String text;

  Token(this.type, this.text);
}

Iterable<Token> lexer(String string) sync* {
  int? currentType;
  var currentText = <String>[];

  for (final char in string.split('')) {
    if ((currentType == TokenType.SYMBOL ||
            currentType == TokenType.VARIABLE) &&
        isSymbol(char)) {
      currentText.add(char);
      continue;
    }

    if (currentType == TokenType.SYMBOL && !isSymbol(char)) {
      currentType = null;
      yield Token(TokenType.SYMBOL, currentText.join(''));
      currentText = [];
    }

    if (currentType == TokenType.NUMBER && isNumeric(char)) {
      currentText.add(char);
      continue;
    }

    if (currentType == TokenType.NUMBER && !isNumeric(char)) {
      currentType = null;
      yield Token(TokenType.NUMBER, currentText.join(''));
      currentText = [];
    }

    switch (char) {
      case ' ':
        continue;
      case '(':
        currentType = TokenType.LEFT_PAREN;
        currentText = ['('];
        break;
      case ')':
        currentType = TokenType.RIGHT_PAREN;
        currentText = [')'];
        break;
      case ',':
        currentType = TokenType.COMMA;
        currentText = [','];
        break;
      case ':':
        currentType = TokenType.COLON;
        currentText = [':'];
        break;
      case '-':
        currentType = TokenType.MINUS;
        currentText = ['-'];
        break;
      case '.':
        currentType = TokenType.PERIOD;
        currentText = ['.'];
        break;
      case '[':
        currentType = TokenType.LEFT_BRACKET;
        currentText = ['['];
        break;
      case ']':
        currentType = TokenType.RIGHT_BRACKET;
        currentText = [']'];
        break;
    }
    if (currentType == null) {
      if (isVar(char)) {
        currentType = TokenType.VARIABLE;
      } else {
        currentType = TokenType.SYMBOL;
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
}

abstract class Expression {
  String print(StringBuffer buffer);
}

class SymbolExpression implements Expression {
  final String symbol;

  SymbolExpression(this.symbol);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class VariableExpression implements Expression {
  final String name;

  VariableExpression(this.name);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class ParenExpression implements Expression {
  final Expression name;
  final Expression args;

  ParenExpression(this.name, this.args);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class CommaExpression implements Expression {
  final Expression left;
  final Expression right;

  CommaExpression(this.left, this.right);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

abstract class PrefixParselet {
  Expression parse(Parser parse, Token token);
}

class SymbolParselet implements PrefixParselet {
  @override
  Expression parse(Parser parse, Token token) {
    return SymbolExpression(token.text);
  }
}

class VariableParselet implements PrefixParselet {
  @override
  Expression parse(Parser parse, Token token) {
    return VariableExpression(token.text);
  }
}

abstract class InfixParselet {
  Expression parse(Parser parser, Expression left, Token token);
  int get precedence;
}

class ParenParselet implements InfixParselet {
  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var operand = parser.parseExpression(precedence);
    parser.expect(')');
    return ParenExpression(left, operand);
  }

  @override
  int get precedence => Precedence.PAREN;
}

class CommaParselet implements InfixParselet {
  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var right = parser.parseExpression(precedence);
    return CommaExpression(left, right);
  }

  @override
  int get precedence => Precedence.COMMA;
}

class ParseError extends Error {
  final String message;

  ParseError(this.message);
}

class Parser {
  final Map<int, PrefixParselet> prefixParselets = {};
  final Map<int, InfixParselet> infixParselets = {};
  final Iterator<Token> tokens;

  Parser(this.tokens) {
    consume();
  }

  Token consume() {
    final current = tokens.current;
    tokens.moveNext();
    return current;
  }

  Token expect(String next) {
    if (tokens.current.text != next) {
      throw Error();
    }
    return consume();
  }

  Token? lookAhead() => tokens.current;

  void register(int token, PrefixParselet parselet) {
    prefixParselets[token] = parselet;
  }

  void registerInfix(int token, InfixParselet parselet) {
    infixParselets[token] = parselet;
  }

  int getPrecedence() {
    var parser = infixParselets[lookAhead()?.type];

    if (parser != null) {
      return parser.precedence;
    }

    return 0;
  }

  Expression parseExpression([int precedence = 0]) {
    var token = consume();
    final prefix = prefixParselets[token.type];

    if (prefix == null) {
      throw ParseError('Could not parse \"' + token.text + '\".');
    }

    var left = prefix.parse(this, token);

    while (precedence < getPrecedence()) {
      token = consume();

      final infix = infixParselets[token.type];

      if (infix == null) {
        throw Error();
      }

      left = infix.parse(this, left, token);
    }

    return left;
  }
}

void main(List<String> arguments) {
  var tokens = lexer('foo(bar), baz(moo)').toList();

  var parser = Parser(tokens.iterator);

  parser.register(TokenType.SYMBOL, SymbolParselet());
  parser.register(TokenType.VARIABLE, VariableParselet());
  parser.registerInfix(TokenType.COMMA, CommaParselet());
  parser.registerInfix(TokenType.LEFT_PAREN, ParenParselet());

  final parsed = parser.parseExpression();

  return;
}
