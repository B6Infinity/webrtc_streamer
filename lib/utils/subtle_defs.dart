// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget h3txt(String txt,
    {int multiplier = 1, Color? color, double padding = 8.0}) {
  return Padding(
    padding: EdgeInsets.all(padding),
    child: Text(
      txt,
      style: TextStyle(
        fontSize: (22 * multiplier).toDouble(),
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );
}

Widget h3heading(String txt,
    {int multiplier = 1,
    alignment = MainAxisAlignment.center,
    Color? color,
    double padding = 8.0}) {
  return Row(
    mainAxisAlignment: alignment,
    children: [
      Padding(
        padding: EdgeInsets.all(padding),
        child: Text(
          txt,
          style: TextStyle(
            fontSize: (20 * multiplier).toDouble(),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    ],
  );
}

Future copyTextToClipboard(String txt) async {
  await Clipboard.setData(ClipboardData(text: txt));
}

void showSnackBarMSG(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
  ));
}

void printG(String str) {
  print('\u001b[32m$str\u001b[0m');
}

void printB(String str) {
  print('\u001b[34m$str\u001b[0m');
}

void printM(String str) {
  print('\u001b[35m$str\u001b[0m');
}

void printC(String str) {
  print('\u001b[36m$str\u001b[0m');
}
