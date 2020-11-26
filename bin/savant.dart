import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'parsing/build.dart';
import 'parsing/infix.dart';
import 'parsing/lexer.dart';
import 'parsing/parser.dart';
import 'parsing/prefix.dart';

HashMap<Variable, Value>? merge_bindings(
    HashMap<Variable, Value>? bindings1, HashMap<Variable, Value>? bindings2) {
  if (bindings1 == null || bindings2 == null) {
    return null;
  }

  var conflict = false;
  var bindings = HashMap<Variable, Value>.from(bindings1);

  bindings2.forEach((variable, value) {
    var other = bindings[variable];
    if (other != null) {
      var sub = other.match(value);
      if (sub == null) {
        conflict = true;
      } else {
        bindings.addAll(sub);
      }
    } else {
      bindings[variable] = value;
    }
  });

  if (conflict) {
    return null;
  }

  return bindings;
}

abstract class Value {
  String get functor;
  HashMap<Variable, Value>? match(Value other);
  Value substitute(HashMap<Variable, Value> bindings);
  Iterable<Value> query(Database database);
}

class Variable extends Equatable implements Value {
  final String name;

  const Variable(this.name);

  @override
  String get functor => name + '/var';

  @override
  HashMap<Variable, Value>? match(Value other) {
    var bindings = HashMap<Variable, Value>();

    if (this != other) {
      bindings[this] = other;
    }

    return bindings;
  }

  @override
  Value substitute(HashMap<Variable, Value> bindings) {
    var value = bindings[this];

    if (value != null) {
      return value.substitute(bindings);
    }

    return this;
  }

  @override
  Iterable<Value> query(Database database) sync* {
    yield this;
  }

  @override
  List<Object> get props => [name];
}

Iterable<Iterable<Value>> zip(Iterable<List<Value>> arrays) => arrays.first
    .asMap()
    .entries
    .map((entry) => arrays.map((array) => array[entry.key]));

class Term implements Value {
  final String name;
  final List<Value> args;

  Term(this.name, [this.args = const []]);

  @override
  String get functor => [name, args.length.toString()].join('/');

  @override
  HashMap<Variable, Value>? match(Value other) {
    if (other is Term) {
      if (functor != other.functor) {
        return null;
      }

      if (args.length != other.args.length) {
        return null;
      }

      if (args.isEmpty) {
        return HashMap();
      }

      var zipped = zip([args, other.args]).map((args) {
        var largs = List<Value>.from(args);
        return largs[0].match(largs[1]);
      });

      return zipped.reduce(merge_bindings);
    }

    return other.match(this);
  }

  @override
  Value substitute(HashMap<Variable, Value> bindings) =>
      Term(name, List<Value>.from(args.map((arg) => arg.substitute(bindings))));

  @override
  Iterable<Value> query(Database database) sync* {
    yield* database.query(this);
  }
}

class True extends Term implements Value {
  True([String functor = 'true']) : super(functor);

  @override
  Value substitute(HashMap<Variable, Value> bindings) => this;

  @override
  Iterable<Value> query(Database database) sync* {
    yield this;
  }
}

abstract class TopLevel {}

class Rule implements TopLevel {
  final Term head;
  final Conjunction body;

  const Rule(this.head, this.body);
}

class Command implements TopLevel {
  final Term body;

  const Command(this.body);
}

class Conjunction extends Term implements Value {
  @override
  final List<Value> args;

  Conjunction(this.args) : super(',', args);

  @override
  Value substitute(HashMap<Variable, Value> bindings) =>
      Conjunction(List.from(args.map((arg) => arg.substitute(bindings))));

  Iterable<Value> solutions(
      Database database, int index, HashMap<Variable, Value> bindings) sync* {
    Value? arg;

    try {
      arg = args[index];
    } on RangeError {
      arg = null;
    }

    if (arg == null) {
      yield substitute(bindings);
    } else {
      for (var item in database.query(arg.substitute(bindings))) {
        var unified = merge_bindings(arg.match(item), bindings);
        if (unified != null) {
          yield* solutions(database, index + 1, unified);
        }
      }
    }
  }

  @override
  Iterable<Value> query(Database database) sync* {
    yield* solutions(database, 0, HashMap());
  }
}

typedef Builtin = Iterable<Value> Function(Database database, List<Value> args);

class Database {
  late final Map<String, List<Rule>> rules;
  late final Map<String, Builtin> builtins;

  Database(List<TopLevel> toplevel) {
    builtins = {};
    rules = {};
    for (final top in toplevel) {
      if (top is Rule) {
        final functor = top.head.functor;
        var instances = rules[functor];
        instances ??= [];
        instances.add(top);
        rules[functor] = instances;
        continue;
      }
      if (top is Command) {
        // force with toList
        query(top.body).toList();
      }
    }
  }

  Database registerBuiltin(String proto, Builtin builtin) {
    builtins[proto] = builtin;
    return this;
  }

  Iterable<Value> query(Value goal) sync* {
    if (goal is Conjunction) {
      yield* goal.query(this);
      return;
    }

    final func = builtins[goal.functor];

    if (func != null && goal is Term) {
      yield* func(this, goal.args);
      return;
    }

    final all = rules[goal.functor];

    if (all == null) {
      return;
    }

    for (var rule in all) {
      var match = rule.head.match(goal);

      if (match != null) {
        var head = rule.head.substitute(match);
        var body = rule.body.substitute(match);

        for (var item in body.query(this)) {
          match = body.match(item);

          if (match != null) {
            yield head.substitute(match);
          }
        }
      }
    }
  }
}

void main(List<String> arguments) {
  final rules = lexer('foo(1).\nfoo(2).');

  final parser = Parser(rules)
    ..register(TokenType.symbol, SymbolParselet())
    ..register(TokenType.variable, VariableParselet())
    ..register(TokenType.let, CommandParselet())
    ..register(TokenType.eof, EOFParselet())
    ..registerInfix(TokenType.comma, CommaParselet())
    ..registerInfix(TokenType.left_paren, ParenParselet())
    ..registerInfix(TokenType.period, PeriodParslet())
    ..registerInfix(TokenType.let, LetParslet());

  final built = AstWalker.walkDatabase(parser.parseExpression());

  final database = Database(built);

  parser.tokens = lexer('foo(X), bar(X).');

  final parsed = parser.parseExpression();
  final goal = AstWalker.walk(parsed);

  // ignore: unused_local_variable
  database.registerBuiltin('bar/1', (database, args) sync* {
    var i = 0;
    while (i < 10) {
      final s = i.toString();
      yield Term('bar', [Term(s, [])]);
      i++;
    }
  });

  final results = database.query(goal).toList();

  return;
}
