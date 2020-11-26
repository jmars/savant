import 'expressions.dart';
import 'lexer.dart';
import 'parser.dart';

abstract class PrefixParselet {
  Expression parse(Parser parse, Token token);
}

class SymbolParselet implements PrefixParselet {
  @override
  Expression parse(Parser parse, Token token) {
    return SymbolExpression(token.text);
  }
}

class NumberParselet implements PrefixParselet {
  @override
  Expression parse(Parser parse, Token token) {
    final value = double.tryParse(token.text);

    if (value == null) {
      throw Error();
    }

    return NumberExpression(value);
  }
}

class VariableParselet implements PrefixParselet {
  @override
  Expression parse(Parser parse, Token token) {
    return VariableExpression(token.text);
  }
}

class EOFParselet implements PrefixParselet {
  @override
  Expression parse(Parser parse, Token token) {
    return EmptyExpression();
  }
}

class CommandParselet implements PrefixParselet {
  @override
  Expression parse(Parser parse, Token token) {
    return CommandExpression(parse.parseExpression(1));
  }
}
