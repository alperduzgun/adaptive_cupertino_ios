import 'package:flutter/cupertino.dart';

void main() {
  print('Map<int, String> cupertinoToSf = {');

  printMapping('sparkles', CupertinoIcons.sparkles);
  printMapping('sparkles', CupertinoIcons.sparkles);

  printMapping('square_grid_2x2', CupertinoIcons.square_grid_2x2);
  printMapping('square_grid_2x2_fill', CupertinoIcons.square_grid_2x2_fill);

  printMapping('uiwindow_split_2x1', CupertinoIcons.uiwindow_split_2x1);

  printMapping('layers_alt', CupertinoIcons.layers_alt);
  printMapping('layers_alt_fill', CupertinoIcons.layers_alt_fill);

  printMapping('lab_flask', CupertinoIcons.lab_flask);
  printMapping('lab_flask_solid', CupertinoIcons.lab_flask_solid);

  print('};');
}

void printMapping(String name, IconData icon) {
  print('  ${icon.codePoint}:, // $name');
}
