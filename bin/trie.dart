import 'dart:convert';
import 'dart:typed_data';

class Pair<A, B> {
  final A item1;
  final B item2;

  const Pair(this.item1, this.item2);
}

List<Pair<A, B>> zip<A, B>(List<A> a, List<B> b) =>
    List.generate(a.length, (index) => Pair(a[index], b[index]));

class TrieNode<V> {
  final V? value;
  late final List<TrieNode<V>> children;
  late Uint8List links;
  late bool terminal;

  TrieNode(this.value) {
    links = Uint8List(0);
    children = [];
    terminal = false;
  }

  void addLink(int key, TrieNode<V> node) {
    final newLinks = Uint8List(links.length + 1);

    for (var i = 0; i < links.length; i++) {
      newLinks[i] = links[i];
    }

    newLinks[links.length] = key;
    links = newLinks;

    children.add(node);
  }

  void sort() {
    final zipped = zip(links, children);
    zipped.sort((a, b) => a.item1.compareTo(b.item1));
    for (var i = 0; i < zipped.length; i++) {
      links[i] = zipped[i].item1;
      children[i] = zipped[i].item2;
      children[i].sort();
    }
  }

  Iterable<MapEntry<String, V?>> _iterate([List<int> prefix = const []]) sync* {
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final str = prefix + [links[i]];
      if (child.terminal) {
        yield MapEntry(utf8.decode(str), child.value);
      }
      yield* child._iterate(str);
    }
  }

  Iterable<MapEntry<String, V?>> get values => _iterate();
}

class Trie<V> {
  late TrieNode<V> head;

  Trie() {
    head = TrieNode(null);
  }

  Iterable<TrieNode<V>> _search(List<int> data) sync* {
    var prefix = head;

    for (final char in data) {
      final index = prefix.links.indexOf(char);
      if (index == -1) {
        break;
      }
      prefix = prefix.children[index];
      yield prefix;
    }
  }

  void insert(String key, [V? value]) {
    final data = utf8.encode(key);
    var prefix = head;
    var i = 0;
    for (prefix in _search(data)) {
      i++;
    }

    if (key.substring(i).isEmpty) {
      if (!prefix.terminal) {
        prefix.terminal = true;
      }

      return;
    }

    final updated = <TrieNode<V>>[];
    for (final char in data.sublist(i)) {
      final node = TrieNode(value);
      prefix.addLink(char, node);
      updated.add(prefix);
      prefix = node;
    }

    prefix.terminal = true;

    return;
  }

  bool contains(Object? value) {
    if (!(value is String)) {
      return false;
    }

    final data = utf8.encode(value);
    try {
      var prefix = _search(data).last;

      if (prefix.terminal) {
        return true;
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  void remove(String value) {
    final data = utf8.encode(value);
    var prefix = _search(data).last;

    if (!prefix.terminal) {
      return;
    }

    prefix.terminal = false;

    final n = Trie<V>();
    for (final entry in head.values) {
      n.insert(entry.key, entry.value);
    }

    head = n.head;
  }

  Iterable<MapEntry<String, V?>> get values => head.values;
}

void main(List<String> arguments) {
  var test = Trie();
  test.insert('foo');
  test.insert('bar');
  test.insert('baz');

  // ignore: unused_local_variable
  final a = test.contains('bar');
  // ignore: unused_local_variable
  final b = test.contains('meh');

  // ignore: unused_local_variable
  final all = List.from(test.values);

  test.remove('bar');

  // ignore: unused_local_variable
  final rAll = List.from(test.values);

  return;
}
