import 'expressions.dart';
import 'lexer.dart';
import 'parser.dart';

enum Precedence { period, rule, term, conjunction }

extension IntValue on Precedence {
  int get value {
    switch (this) {
      case Precedence.period:
        return 1;
      case Precedence.rule:
        return 2;
      case Precedence.conjunction:
        return 3;
      case Precedence.term:
        return 4;
    }
  }
}

abstract class InfixParselet {
  Expression parse(Parser parser, Expression left, Token token);
  int get precedence;
}

class ParenParselet implements InfixParselet {
  @override
  Expression parse(Parser parser, Expression left, Token token) {
    final operand = parser.parseExpression(precedence - 1);
    parser.expect(')');
    return TermExpression(left, operand);
  }

  @override
  int get precedence => Precedence.term.value;
}

class CommaParselet implements InfixParselet {
  @override
  Expression parse(Parser parser, Expression left, Token token) {
    final right = parser.parseExpression(precedence - 1);
    return ConjunctionExpression(left, right);
  }

  @override
  int get precedence => Precedence.conjunction.value;
}

class PeriodParslet implements InfixParselet {
  @override
  Expression parse(Parser parser, Expression left, Token token) {
    final right = parser.parseExpression(precedence - 1);
    return PeriodExpression(left, right);
  }

  @override
  int get precedence => Precedence.period.value;
}

class LetParslet implements InfixParselet {
  @override
  Expression parse(Parser parser, Expression head, Token token) {
    final body = parser.parseExpression(precedence - 1);
    return RuleExpression(head, body);
  }

  @override
  int get precedence => Precedence.rule.value;
}
