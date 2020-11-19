const m = 0x5bd1e995;

int zeroFillRightShift(int n, int amount) {
  return (n & 0xffffffff) >> amount;
}

int murmur2(List<int> data, int seed) {
  var len = data.length;
  var h = seed ^ len;
  var i = 0;

  while (len >= 4) {
    var k = (data[i] & 0xff) |
        ((data[++i] & 0xff) << 8) |
        ((data[++i] & 0xff) << 16) |
        ((data[++i] & 0xff) << 24);

    k = (k & 0xffff) * m + (((zeroFillRightShift(k, 16) * m) & 0xffff) << 16);
    k ^= zeroFillRightShift(k, 24);
    k = (k & 0xffff) * m + (((zeroFillRightShift(k, 16) * m) & 0xffff) << 16);

    h = ((h & 0xffff) * m +
            (((zeroFillRightShift(h, 16) * m) & 0xffff) << 16)) ^
        k;

    len -= 4;
    ++i;
  }

  switch (len) {
    case 3:
      h ^= (data[i + 2] & 0xff) << 16;
      break;
    case 2:
      h ^= (data[i + 1] & 0xff) << 8;
      break;
    case 1:
      h ^= data[i] & 0xff;
      h = (h & 0xffff) * m + (((zeroFillRightShift(h, 16) * m) & 0xffff) << 16);
      break;
  }

  h ^= zeroFillRightShift(h, 13);
  h = (h & 0xffff) * m + (((zeroFillRightShift(h, 16) * m) & 0xffff) << 16);
  h ^= zeroFillRightShift(h, 15);

  return zeroFillRightShift(h, 0);
}
