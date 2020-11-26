import 'expressions.dart';
import 'infix.dart';
import 'lexer.dart';
import 'prefix.dart';

class ParseError extends Error {
  final String message;

  ParseError(this.message);
}

class Parser {
  final Map<TokenType, PrefixParselet> prefixParselets = {};
  final Map<TokenType, InfixParselet> infixParselets = {};
  late Iterator<Token> _tokens;

  Parser(Iterable<Token> tokens) {
    _tokens = tokens.iterator;
    consume();
  }

  set tokens(Iterable<Token> t) {
    _tokens = t.iterator;
    consume();
  }

  Token consume() {
    final current = _tokens.current;
    _tokens.moveNext();
    return current;
  }

  Token expect(String next) {
    if (_tokens.current.text != next) {
      throw Error();
    }
    return consume();
  }

  Token? lookAhead() => _tokens.current;

  Parser register(TokenType token, PrefixParselet parselet) {
    prefixParselets[token] = parselet;
    return this;
  }

  Parser registerInfix(TokenType token, InfixParselet parselet) {
    infixParselets[token] = parselet;
    return this;
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
