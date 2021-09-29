import 'package:fixnum/fixnum.dart';

abstract class HasId {
  Int64 get id;
}

abstract class Validatable {
  bool isValid();
}
