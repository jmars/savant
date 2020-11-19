import 'dart:collection';

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
  HashMap<Variable, Value>? match(Value other);
  Value substitute(HashMap<Variable, Value> bindings);
  Iterable<Value> query(Database database);
}

class Variable implements Value {
  final String name;

  const Variable(this.name);

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
}

Iterable<Iterable<Value>> zip(Iterable<List<Value>> arrays) => arrays.first
    .asMap()
    .entries
    .map((entry) => arrays.map((array) => array[entry.key]));

class Term implements Value {
  final String functor;
  final List<Value> args;

  const Term(this.functor, [this.args = const []]);

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
  Value substitute(HashMap<Variable, Value> bindings) => Term(
      functor, List<Value>.from(args.map((arg) => arg.substitute(bindings))));

  @override
  Iterable<Value> query(Database database) sync* {
    yield* database.query(this);
  }
}

class True extends Term implements Value {
  const True([String functor = 'true']) : super(functor);

  @override
  Value substitute(HashMap<Variable, Value> bindings) => this;

  @override
  Iterable<Value> query(Database database) sync* {
    yield this;
  }
}

const TRUE = True();

class Rule {
  final Term head;
  final Conjunction body;

  const Rule(this.head, this.body);
}

class Conjunction extends Term implements Value {
  @override
  final List<Value> args;

  const Conjunction(this.args) : super(',');

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

class Database {
  final List<Rule> rules;

  const Database(this.rules);

  Iterable<Value> query(Value goal) sync* {
    for (var rule in rules) {
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
  var knownTerm = Term('father_child', [Term('eric'), Term('thorne')]);

  var x = Variable('X');

  var goal = Term('father_child', [Term('eric'), x]);

  var bindings = goal.match(knownTerm);

  if (bindings == null) {
    print('No bindings');
    return;
  }

  // ignore: unused_local_variable
  var value = goal.substitute(bindings);
  return;
}
