import 'dart:math';

final rng = Random();

int get_level(int max_level) => rng.nextInt(max_level);

class SkipNode<K extends Comparable> {
  final K? key;
  final List<SkipNode<K>> pointers;

  const SkipNode(this.key, this.pointers);
}

class SkipList<K extends Comparable, V> {
  final int max_level;
  late final SkipNode<K> _head;
  late final List<SkipNode<K>> _update_nodes;

  SkipList([this.max_level = 0]) {
    final EMPTY = SkipNode<K>(null, List.empty(growable: false));
    _head = SkipNode(null, List.filled(max_level, EMPTY, growable: false));
    _update_nodes = List.filled(max_level, EMPTY, growable: false);
  }

  SkipNode<K> _search(K val) {
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
      _update_nodes[i] = current;
    }

    return current;
  }

  void insert(K key) {
    var current = _search(key).pointers[0];
    final elem = current.key;

    if (elem == null || current.key != key) {
      final new_level = max(1, get_level(max_level));
      current = SkipNode(
          key, List.generate(new_level, (i) => _head, growable: false));
      for (var i = 0; i < new_level; i++) {
        current.pointers[i] = _update_nodes[i].pointers[i];
        _update_nodes[i].pointers[i] = current;
      }
    }

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
  }

  K? find(K key) {
    final current = _search(key).pointers[0];

    if (current.key != null && current.key == key) {
      return current.key;
    }
  }
}

void main(List<String> arguments) {
  var test = SkipList<String, int>(32);
  test.insert('aaa');
  test.insert('bbb');
  test.insert('ccc');
  test.remove('bbb');

  final a = test.find('ccc');

  print('foo');
}
