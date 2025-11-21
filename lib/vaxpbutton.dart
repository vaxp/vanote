import 'package:flutter/material.dart';

class VaxpButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const VaxpButton({super.key, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// زر ماك مع تأثير hover (لزر التكبير/إلغاء التكبير)
class HoverVaxpButton extends StatefulWidget {
  final Color color;
  final VoidCallback onPressed;

  const HoverVaxpButton({super.key, required this.color, required this.onPressed});

  @override
  State<HoverVaxpButton> createState() => _HoverVaxpButtonState();
}

class _HoverVaxpButtonState extends State<HoverVaxpButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _hovering ? widget.color.withOpacity(0.7) : widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
