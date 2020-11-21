import 'dart:math';

final rng = Random();

int get_level(int max_level) => rng.nextInt(max_level);

class SkipNode<K extends Comparable, V> {
  final K? key;
  final V? value;
  final List<SkipNode<K, V>> pointers;

  const SkipNode(this.key, this.value, this.pointers);
}

// TODO: iterable
class SkipList<K extends Comparable, V> {
  final int max_level;
  late final SkipNode<K, V> _head;
  late final List<SkipNode<K, V>> _update_nodes;

  SkipList([this.max_level = 0]) {
    final EMPTY = SkipNode<K, V>(null, null, List.empty(growable: false));
    _head =
        SkipNode(null, null, List.filled(max_level, EMPTY, growable: false));
    _update_nodes = List.filled(max_level, EMPTY, growable: false);
  }

  SkipNode<K, V> _search(K val, [bool update = true]) {
    var current = _head;

    for (var i = max_level - 1; i >= 0; i--) {
      while (true) {
        final elem = current.pointers[i].key;
        if (elem == null) {
          break;
        }
        if (elem.compareTo(val) >= 0) {
          break;
        }
        current = current.pointers[i];
      }

      if (update) {
        _update_nodes[i] = current;
      }
    }

    return current;
  }

  void insert(K key, V value) {
    var current = _search(key).pointers[0];
    final elem = current.key;

    if (elem == null || current.key != key) {
      final new_level = max(1, get_level(max_level));
      current = SkipNode(
          key, value, List.generate(new_level, (i) => _head, growable: false));
      for (var i = 0; i < new_level; i++) {
        current.pointers[i] = _update_nodes[i].pointers[i];
        _update_nodes[i].pointers[i] = current;
      }
    }

    _update_nodes = [];

    return;
  }

  void remove(K key) {
    final current = _search(key).pointers[0];
    final elem = current.key;

    if (elem != null) {
      if (elem == key) {
        for (var i = 0; i < max_level; i++) {
          if (_update_nodes[i].pointers[i] == current) {
            _update_nodes[i].pointers[i] = current.pointers[i];
          }
        }
      }
    }

    _update_nodes = [];
  }

  K? find(K key) {
    final current = _search(key, false).pointers[0];

    if (current.key != null && current.key == key) {
      return current.key;
    }
  }
}

void main(List<String> arguments) {
  var test = SkipList<String, void>(32);
  test.insert('aaa', null);
  test.insert('bbb', null);
  test.insert('ccc', null);
  test.remove('bbb');

  // ignore: unused_local_variable
  final a = test.find('ccc');

  print('foo');
}
