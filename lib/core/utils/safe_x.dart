extension SafeList<E> on Iterable<E> {
  E? safeFirstWhere(bool Function(E element) test, {E Function()? orElse}) {
    if (any(test)) {
      return firstWhere(test, orElse: orElse);
    }
    return null;
  }

  E? safeElementAt(int index) {
    if (length > index) {
      return elementAt(index);
    }
    return null;
  }
}
