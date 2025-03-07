import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class WebErrorView extends StatelessWidget {
  const WebErrorView({required this.onRetry,super.key, required this.errorMessage});

  final Function() onRetry;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/world.svg',
            semanticsLabel: 'Error SVG',
            height: MediaQuery.of(context).size.height * 0.2,
            width: MediaQuery.of(context).size.height * 0.2,
          ),
          const SizedBox(height: 10),
          const Text(
            "Oops! Something went wrong.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text("  Retry  "),
          ),
        ],
      ),
    );
  }
}