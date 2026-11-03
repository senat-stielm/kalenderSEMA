import 'package:flutter/material.dart';

/// Ikon Help Desk bergaya aplikasi macOS: squircle hijau-hutan dengan
/// headset emas dan kilau kecil di sudut.
class IkonHelpdesk extends StatelessWidget {
  const IkonHelpdesk({super.key, this.ukuran = 48, this.denganLatar = true});

  final double ukuran;
  final bool denganLatar;

  @override
  Widget build(BuildContext context) {
    final inti = Icon(
      Icons.support_agent_rounded,
      size: ukuran * 0.5,
      color: Colors.white,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: ukuran * 0.12,
          offset: Offset(0, ukuran * 0.03),
        ),
      ],
    );

    if (!denganLatar) return SizedBox.square(dimension: ukuran, child: inti);

    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A7A54), Color(0xFF123F2B)],
        ),
        borderRadius: BorderRadius.circular(ukuran * 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5B40).withValues(alpha: 0.45),
            blurRadius: ukuran * 0.3,
            offset: Offset(0, ukuran * 0.1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: ukuran * 0.06,
            left: ukuran * 0.08,
            child: Container(
              width: ukuran * 0.34,
              height: ukuran * 0.16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(ukuran),
              ),
            ),
          ),
          inti,
          Positioned(
            top: ukuran * 0.09,
            right: ukuran * 0.09,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: ukuran * 0.24,
              color: const Color(0xFFE7D6A8),
            ),
          ),
          Positioned(
            bottom: ukuran * 0.09,
            right: ukuran * 0.09,
            child: Container(
              width: ukuran * 0.14,
              height: ukuran * 0.14,
              decoration: BoxDecoration(
                color: const Color(0xFF6EE7A8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF123F2B),
                  width: ukuran * 0.025,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
