
import 'package:flutter/material.dart';

class NormalHeader extends StatelessWidget {
  const NormalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('normal_header'),
      height: 80,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'Lista de reproducción',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandedHeader extends StatelessWidget {
  final VoidCallback onCollapse;
  const ExpandedHeader({super.key, required this.onCollapse});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('expanded_header'),
      height: 80,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'En reproducción',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pantalla de reproducción',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: onCollapse,
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
