import 'dart:convert';
import 'dart:typed_data';

class Pair<A, B> {
  final A item1;
  final B item2;

  const Pair(this.item1, this.item2);
}

List<Pair<A, B>> zip<A, B>(List<A> a, List<B> b) =>
    List.generate(a.length, (index) => Pair(a[index], b[index]));

class TrieNode {
  late final List<TrieNode> children;
  late Uint8List links;
  late bool terminal;

  TrieNode() {
    links = Uint8List(0);
    children = [];
    terminal = false;
  }

  void addLink(int key, TrieNode node) {
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

  Iterable<String> iterate([String prefix = '']) sync* {
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final str = prefix + utf8.decode([links[i]]);
      if (child.terminal) {
        yield str;
      }
      yield* child.iterate(str);
    }
  }
}

class Trie {
  late TrieNode head;

  Trie() {
    head = TrieNode();
  }

  Iterable<TrieNode> _search(List<int> data) sync* {
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

  void insert(String value) {
    final data = utf8.encode(value);
    var prefix = head;
    var i = 0;
    for (prefix in _search(data)) {
      i++;
    }

    if (value.substring(i).isEmpty) {
      if (!prefix.terminal) {
        prefix.terminal = true;
      }

      return;
    }

    final updated = <TrieNode>[];
    for (final char in data.sublist(i)) {
      final node = TrieNode();
      prefix.addLink(char, node);
      updated.add(prefix);
      prefix = node;
    }

    prefix.terminal = true;

    return;
  }

  bool contains(String value) {
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

    final n = Trie();
    for (final str in head.iterate()) {
      n.insert(str);
    }

    head = n.head;
  }

  Iterable<String> iterate() => head.iterate();
}

void main(List<String> arguments) {
  var test = Trie();
  test.insert('foo');
  test.insert('bar');
  test.insert('baz');

  final a = test.contains('bar');
  final b = test.contains('meh');

  final all = test.iterate().toList();

  test.remove('bar');

  final rAll = test.iterate().toList();

  return;
}
