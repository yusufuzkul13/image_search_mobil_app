import 'package:crop_lib_dart/src/logic/format_detector/format.dart';

class InvalidInputFormatError extends Error {
  final ImageFormat? inputFormat;

  InvalidInputFormatError(this.inputFormat);
}
