import 'package:flutter/material.dart';
import 'miles_membership_sheet.dart';

/// Dark Miles Membership banner matching the reference screenshot.
class MilesMembershipBanner extends StatelessWidget {
  const MilesMembershipBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF18181B), // Sleek pitch-dark background
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => MilesMembershipSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: [Miles] pill + Membership + White Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48), // Vivid red
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Miles',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Membership',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bullets line: • ₹ 20,000 Savings • Discounts Upto 25% • Free SOS
                Row(
                  children: const [
                    Text(
                      '•  ₹ 20,000 Savings',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '•  Discounts Upto 25%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '•  Free SOS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
