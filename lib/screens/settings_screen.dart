// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class SettingsScreen extends StatefulWidget {
  final GameSettings settings;
  final Function(GameSettings) onSave;
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onBack,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _local;

  @override
  void initState() {
    super.initState();
    _local = widget.settings.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF1E1B4B), Color(0xFF000033)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSetting(
                          label: 'Rows',
                          child: _StyledDropdown<int>(
                            value: _local.rows,
                            items: [7, 9, 11, 13, 15],
                            labelBuilder: (v) => '$v',
                            onChanged: (v) => setState(() => _local.rows = v!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSetting(
                          label: 'Columns',
                          child: _StyledDropdown<int>(
                            value: _local.cols,
                            items: [7, 9, 11, 13, 15],
                            labelBuilder: (v) => '$v',
                            onChanged: (v) => setState(() => _local.cols = v!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSetting(
                          label: 'Board Shape',
                          child: _StyledDropdown<BoardTemplate>(
                            value: _local.template,
                            items: BoardTemplate.values,
                            labelBuilder: (v) => _templateLabel(v),
                            onChanged: (v) => setState(() => _local.template = v!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSetting(
                          label: 'Min Group',
                          child: _StyledDropdown<int>(
                            value: _local.minGroupSize,
                            items: [2, 3, 4, 5],
                            labelBuilder: (v) => '$v',
                            onChanged: (v) => setState(() => _local.minGroupSize = v!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSetting(
                          label: 'Sound',
                          child: Switch(
                            value: _local.soundEnabled,
                            activeColor: const Color(0xFF22C55E),
                            onChanged: (v) => setState(() => _local.soundEnabled = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(0xFF6B46C1), width: 3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HOW TO PLAY',
                          style: TextStyle(
                            color: Color(0xFFD8B4FE),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRule('🎯', 'Tap a group of 2+ same-colored shapes to remove them.'),
                        _buildRule('⭐', 'Collect all prize cells — or clear the entire board — to win.'),
                        _buildRule('🚫', 'No valid moves left? Game over.'),
                        _buildRule('📐', 'Min Group sets the smallest group you can tap.'),
                        _buildRule('🔄', 'Use the rotate buttons to shift gravity and open new moves.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _SettingsButton(
                          label: 'SAVE & BACK',
                          color: const Color(0xFF22C55E),
                          shadowColor: const Color(0xFF166534),
                          onTap: () {
                            widget.onSave(_local);
                            widget.onBack();
                          },
                        ),
                        const SizedBox(height: 14),
                        _SettingsButton(
                          label: 'BACK',
                          color: const Color(0xFF3B82F6),
                          shadowColor: const Color(0xFF1E3A8A),
                          onTap: widget.onBack,
                        ),
                      ],
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

  Widget _buildRule(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetting({required String label, required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        child,
      ],
    );
  }

  String _templateLabel(BoardTemplate t) {
    switch (t) {
      case BoardTemplate.rectangle: return 'Rectangle';
      case BoardTemplate.diamond:   return 'Diamond';
      case BoardTemplate.cross:     return 'Cross';
      case BoardTemplate.circle:    return 'Circle';
      case BoardTemplate.staircase: return 'Staircase';
      case BoardTemplate.corners:   return 'Corners';
      case BoardTemplate.triangle:  return 'Triangle';
      case BoardTemplate.random:    return 'Random';
    }
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: DropdownButton<T>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        dropdownColor: Colors.white,
        items: items
            .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    labelBuilder(i),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;

  const _SettingsButton({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 5))],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
