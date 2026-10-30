import 'package:flutter/material.dart';
import 'package:question_reponse/app/widgets/brand_mark.dart';

class AuthLoadingPage extends StatelessWidget {
  const AuthLoadingPage({super.key});

  static const routePath = '/chargement';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Chargement',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 64),
              const SizedBox(height: 28),
              SizedBox(
                width: 96,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
