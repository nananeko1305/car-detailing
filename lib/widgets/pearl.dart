import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The main action of a screen, on the pearl gradient: "Završi posao",
/// "Sačuvaj". Stretches to the width it is given.
class PearlButton extends StatelessWidget {
  const PearlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !busy;
    final radius = BorderRadius.circular(14);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: c.pearlGradient,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: height,
              child: Center(
                child: busy
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: c.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: c.onPrimary, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating "+ Novi termin" button.
class PearlFab extends StatelessWidget {
  const PearlFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: c.pearlGradient,
        boxShadow: [
          BoxShadow(
            color: c.pearl[1].withValues(alpha: 0.25),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 22, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: c.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: c.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A few water beads, as on a coated bonnet; decoration only.
class WaterBeads extends StatelessWidget {
  const WaterBeads({super.key, this.scale = 1});

  final double scale;

  static const _beads = [
    (dx: 0.0, dy: 2.0, r: 11.0),
    (dx: 32.0, dy: 18.0, r: 7.0),
    (dx: 60.0, dy: 0.0, r: 15.0),
    (dx: 48.0, dy: 40.0, r: 4.5),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 92 * scale,
        height: 50 * scale,
        child: Stack(
          children: [
            for (final b in _beads)
              Positioned(
                left: b.dx * scale,
                top: b.dy * scale,
                child: Container(
                  width: b.r * 2 * scale,
                  height: b.r * 2 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      radius: 0.8,
                      colors: [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.14),
                        c.pearl.first.withValues(alpha: 0.18),
                        c.pearl[1].withValues(alpha: 0.05),
                      ],
                      stops: const [0, 0.28, 0.7, 1],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Car Detailing" in pearl letters.
class PearlWordmark extends StatelessWidget {
  const PearlWordmark(this.text, {super.key, this.size = 21});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        colors: [
          Color.lerp(c.pearl[0], Colors.white, 0.25)!,
          Color.lerp(c.pearl[1], Colors.white, 0.15)!,
          Color.lerp(c.pearl[2], Colors.white, 0.1)!,
        ],
        stops: const [0, 0.55, 1],
      ).createShader(rect),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: c.display(size),
      ),
    );
  }
}
