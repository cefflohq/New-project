import 'package:flutter/material.dart';

/// Shared presentation for the six Founder-reviewed operations screens only.
class ReviewProfileHero extends StatelessWidget {
  const ReviewProfileHero({
    super.key,
    required this.name,
    required this.role,
    required this.status,
    this.pending = false,
    this.square = false,
  });
  final String name, role, status;
  final bool pending, square;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0065E4), Color(0xFF003B91), Color(0xFF071C46)],
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 94,
          height: 108,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFDCE7F3),
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(square ? 16 : 54),
          ),
          child: Text(
            name
                .split(' ')
                .where((s) => s.isNotEmpty)
                .take(2)
                .map((s) => s[0])
                .join(),
            style: const TextStyle(
              fontSize: 27,
              color: Color(0xFF12213E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: pending
                      ? const Color(0xFFFEC819)
                      : const Color(0xFFDAF3E4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF102344),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                role,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
