abstract class Expression {
  String print(StringBuffer buffer);
}

class SymbolExpression implements Expression {
  final String symbol;

  const SymbolExpression(this.symbol);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class VariableExpression implements Expression {
  final String name;

  const VariableExpression(this.name);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class TermExpression implements Expression {
  final Expression name;
  final Expression args;

  const TermExpression(this.name, this.args);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class ConjunctionExpression implements Expression {
  final Expression left;
  final Expression right;

  const ConjunctionExpression(this.left, this.right);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class PeriodExpression implements Expression {
  final Expression left;
  final Expression right;

  const PeriodExpression(this.left, this.right);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class EmptyExpression implements Expression {
  const EmptyExpression();

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class RuleExpression implements Expression {
  final Expression head;
  final Expression body;

  const RuleExpression(this.head, this.body);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}

class CommandExpression implements Expression {
  final Expression command;

  CommandExpression(this.command);

  @override
  String print(StringBuffer buffer) {
    throw UnimplementedError();
  }
}
