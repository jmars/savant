import 'dart:math';
import 'package:bit_array/bit_array.dart';
import '../hashing/murmur2.dart';

class BloomFilter {
  late final BitArray array;
  late final int hashFunctionCount;
  static final double falsePositiveProbability = 0.0001;

  BloomFilter(int expectedCount) {
    final m = max(1, BloomFilter._computeM(expectedCount));
    final k = max(1, BloomFilter._computeK(expectedCount));

    final sizeInEvenBytes = (m + 7) & -7;

    array = BitArray(sizeInEvenBytes);
    hashFunctionCount = k;
  }

  static int _computeM(int expectedCount) {
    final p = BloomFilter.falsePositiveProbability;
    final n = expectedCount;

    final numerator = n * log(p);
    final denominator = log(1.0 / pow(2.0, log(2.0)));

    return (numerator / denominator).ceil();
  }

  static int _computeK(int expectedCount) {
    final n = expectedCount;
    final m = BloomFilter._computeM(expectedCount);

    final temp = log(2.0) * m / n;

    return temp.round();
  }

  int _computeHash(List<int> key, int seed) => murmur2(key, seed);

  void addKeys(Iterable<List<int>> keys) {
    for (final name in keys) {
      add(name);
    }
  }

  void add(List<int> value) {
    for (var i = 0; i < hashFunctionCount; i++) {
      var hash = _computeHash(value, i);
      hash = hash % array.length;
      array[hash.abs()] = true;
    }
  }

  bool probablyContains(List<int> value) {
    for (var i = 0; i < hashFunctionCount; i++) {
      var hash = _computeHash(value, i);
      hash = hash % array.length;
      if (!array[hash.abs()]) {
        return false;
      }
    }

    return true;
  }

  bool isEquivalent(BloomFilter filter) =>
      BloomFilter.isEquivalent2(array, filter.array) &&
      hashFunctionCount == filter.hashFunctionCount;

  static bool isEquivalent2(BitArray array1, BitArray array2) {
    if (array1.length != array2.length) {
      return false;
    }

    for (var i = 0; i < array1.length; i++) {
      if (array1[i] != array2[i]) {
        return false;
      }
    }

    return true;
  }
}
