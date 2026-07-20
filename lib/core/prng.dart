class Xorshift32 {
  int _state;
  Xorshift32(int seed) : _state = seed == 0 ? 1 : seed;
  
  int next() {
    // xorshift32 algorithm
    _state ^= _state << 13;
    _state &= 0xFFFFFFFF; // keep 32-bit
    _state ^= _state >> 17;
    _state &= 0xFFFFFFFF;
    _state ^= _state << 5;
    _state &= 0xFFFFFFFF;
    return _state;
  }
  
  int nextInt(int max) {
    return (next() & 0x7FFFFFFF) % max;
  }
  
  bool nextBool() => (next() & 1) == 0;
}
