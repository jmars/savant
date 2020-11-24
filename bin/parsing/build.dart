import '../savant.dart';
import 'expressions.dart';

class AstWalker {
  static List<Value> walkArgs(Expression args) {
    final collapsed = <Value>[];

    if (args is ConjunctionExpression) {
      Expression current = args;
      while (current is ConjunctionExpression) {
        collapsed.add(AstWalker.walk(current.left));
        current = current.right;
      }

      return collapsed;
    }

    return [AstWalker.walk(args)];
  }

  static List<Rule> walkRules(Expression arg) {
    final rules = <Rule>[];

    if (arg is! PeriodExpression) {
      throw Error();
    }

    Expression current = arg;
    while (current is PeriodExpression) {
      final left = current.left;

      if (left is RuleExpression) {
        final head = AstWalker.walk(left.head);
        final tail = AstWalker.walk(left.body);

        if (head is! Term) {
          throw Error();
        }

        if (tail is Conjunction) {
          rules.add(Rule(head, tail));
          continue;
        }

        if (tail is Term) {
          rules.add(Rule(head, Conjunction([tail])));
          continue;
        }

        throw Error();
      }

      if (left is TermExpression) {
        final head = AstWalker.walk(left);

        if (head is! Term) {
          throw Error();
        }

        rules.add(Rule(head, Conjunction([TRUE])));
      }

      current = current.right;
    }

    if (current is! EmptyExpression) {
      throw Error();
    }

    return rules;
  }

  static Value walk(Expression expr) {
    if (expr is SymbolExpression) {
      return Term(expr.symbol);
    }
    if (expr is VariableExpression) {
      return Variable(expr.name);
    }
    if (expr is TermExpression) {
      final name = expr.name;

      if (name is! SymbolExpression) {
        throw Error();
      }

      return Term(name.symbol, AstWalker.walkArgs(expr.args));
    }
    if (expr is ConjunctionExpression) {
      return Conjunction(AstWalker.walkArgs(expr));
    }
    if (expr is PeriodExpression) {
      throw Error();
    }
    if (expr is EmptyExpression) {
      throw Error();
    }
    if (expr is RuleExpression) {
      throw Error();
    }

    throw Error();
  }
}
