import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class Triple<A, B, C> {
  final A item1;
  final B item2;
  final C item3;

  const Triple(this.item1, this.item2, this.item3);
}

class DawgNode extends Equatable {
  final bool terminal;
  static int DawgID = 0;

  late final int id;
  late final SplayTreeMap<int, DawgNode> edges;

  DawgNode([this.terminal = false]) {
    id = DawgID++;
    edges = SplayTreeMap();
  }

  int get count {
    var c = 0;

    if (terminal) {
      c++;
    }

    for (var node in edges.values) {
      c += node.count;
    }

    return c;
  }

  @override
  List<Object> get props => [terminal, edges];

  Iterable<String> _iterate([List<int> prefix = const []]) sync* {
    for (final entry in edges.entries) {
      final str = prefix + [entry.key];
      if (entry.value.terminal) {
        yield utf8.decode(str);
      }
      yield* entry.value._iterate(str);
    }
  }

  Iterable<String> get keys => _iterate();

  @override
  bool get stringify => true;
}

class Dawg<V> {
  late final DawgNode root;
  late final List<Triple<DawgNode, int, DawgNode>> unchecked_nodes;
  late final Set<DawgNode> minimized_nodes;
  late final List<V> data;

  late Uint8List previous_word;

  Dawg() {
    previous_word = Uint8List(0);
    root = DawgNode();
    unchecked_nodes = [];
    minimized_nodes = {};
    data = [];
  }

  void insert(String w, V value) {
    if (w.compareTo(utf8.decode(previous_word)) < 1) {
      throw Exception('Error: Words must be inserted in alphabetical order');
    }

    final word = utf8.encode(w);

    var common_prefix = 0;
    for (var i = 0; i < min(word.length, previous_word.length); i++) {
      if (word[i] != previous_word[i]) {
        break;
      }
      common_prefix++;
    }

    _minimise(common_prefix);

    data.add(value);

    DawgNode node;
    if (unchecked_nodes.isEmpty) {
      node = root;
    } else {
      node = unchecked_nodes.last.item3;
    }

    final suffix = word.sublist(common_prefix, word.length - 1);
    for (final letter in suffix) {
      final next_node = DawgNode();
      node.edges[letter] = next_node;
      unchecked_nodes.add(Triple(node, letter, next_node));
      node = next_node;
    }

    final next_node = DawgNode(true);
    node.edges[word.last] = next_node;
    unchecked_nodes.add(Triple(node, word.last, next_node));

    previous_word = word as Uint8List;
  }

  int finish() {
    _minimise(0);
    return root.count;
  }

  void _minimise(int down_to) {
    for (var i = unchecked_nodes.length - 1; i >= down_to; i--) {
      final unchecked = unchecked_nodes[i];
      final parent = unchecked.item1;
      final letter = unchecked.item2;
      final child = unchecked.item3;

      final minimized = minimized_nodes.lookup(child);
      if (minimized != null) {
        parent.edges[letter] = minimized;
      } else {
        minimized_nodes.add(child);
      }

      unchecked_nodes.removeLast();
    }
  }

  V? lookup(String word) {
    var node = root;
    var skipped = 0;

    for (final letter in utf8.encode(word)) {
      if (!node.edges.containsKey(letter)) {
        print(letter);
        return null;
      }

      for (final entry in node.edges.entries) {
        final label = entry.key;
        final child = entry.value;

        if (label == letter) {
          if (node.terminal) {
            skipped += 1;
          }
          node = child;
          break;
        }

        skipped += child.count;
      }
    }

    if (node.terminal) {
      return data[skipped];
    }

    return null;
  }

  int get node_count => minimized_nodes.length;

  int get edge_count {
    var count = 0;

    for (final node in minimized_nodes) {
      count += node.edges.length;
    }

    return count;
  }

  Iterable<MapEntry<String, V>> _entries() sync* {
    var i = 0;
    for (final key in root.keys) {
      yield MapEntry(key, data[i++]);
    }
  }

  Iterable<MapEntry<String, V>> get entries => _entries();

  Iterable<String> get keys => root.keys;

  Iterable<V> _values() sync* {
    for (final d in data) {
      yield d;
    }
  }

  Iterable<V> get values => _values();

  void display() {
    final stack = [root];
    var done = <DawgNode>{};
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (done.contains(node)) {
        continue;
      }
      done.add(node);
      print(node.id.toString() + ': ' + '(' + node.toString() + ')');
      for (final entry in node.edges.entries) {
        print('    ' +
            utf8.decode([entry.key]) +
            ' goto ' +
            entry.value.id.toString());
        stack.add(entry.value);
      }
    }
  }
}
