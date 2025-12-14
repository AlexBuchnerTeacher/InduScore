/// Tendenz einer Note (optional)
enum Tendenz {
  plus('+'),
  minus('-'),
  keine('');

  final String symbol;
  const Tendenz(this.symbol);

  static Tendenz fromString(String? value) {
    if (value == '+') return Tendenz.plus;
    if (value == '-') return Tendenz.minus;
    return Tendenz.keine;
  }
}
