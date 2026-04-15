import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MapControls extends StatelessWidget {
  final bool tracking;
  final bool pitchActive;
  final VoidCallback onToggleTracking;
  final VoidCallback onTogglePitch;

  const MapControls({
    required this.tracking,
    required this.pitchActive,
    required this.onToggleTracking,
    required this.onTogglePitch,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          onPressed: onToggleTracking,
          active: tracking,
          child: FaIcon(
            FontAwesomeIcons.locationArrow,
            size: 16,
            color: tracking ? Colors.white : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 5),
        _ControlButton(
          onPressed: onTogglePitch,
          active: pitchActive,
          child: SvgPicture.asset(
            'assets/icons/angle-icon.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              pitchActive ? Colors.white : (Colors.grey[700] ?? Colors.grey),
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool active;

  const _ControlButton({
    required this.onPressed,
    required this.child,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? Colors.blue[600] : Colors.white,
          foregroundColor: active ? Colors.white : Colors.grey[700],
          elevation: active ? 4 : 2,
          shadowColor: Colors.black38,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          side: active
              ? BorderSide.none
              : BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: child,
      ),
    );
  }
}
