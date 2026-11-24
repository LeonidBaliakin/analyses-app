import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'orange_palette.dart';

@immutable
class AppSelectOption<T> {
  const AppSelectOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A controlled selection field shared by settings, filters and forms.
/// The owner supplies the saved value, including after a failed save.
class AppSelect<T> extends StatefulWidget {
  const AppSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T>? onChanged;

  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  final _controller = MenuController();
  final _focusNode = FocusNode();
  final _selectedOptionFocus = FocusNode();
  bool _open = false;

  void _onOpen() {
    setState(() => _open = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.isOpen) _selectedOptionFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _selectedOptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context);
    final selected = widget.options.firstWhere((o) => o.value == widget.value);
    final enabled = widget.onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: p.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => MenuAnchor(
            controller: _controller,
            childFocusNode: _focusNode,
            consumeOutsideTap: true,
            crossAxisUnconstrained: false,
            alignmentOffset: const Offset(0, 6),
            onOpen: _onOpen,
            onClose: () => setState(() => _open = false),
            style: MenuStyle(
              alignment: AlignmentDirectional.bottomStart,
              minimumSize: WidgetStatePropertyAll(
                Size(constraints.maxWidth, 0),
              ),
              maximumSize: WidgetStatePropertyAll(
                Size(
                  constraints.maxWidth,
                  math.min(360, MediaQuery.sizeOf(context).height * .6),
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(p.card),
              surfaceTintColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              shadowColor: WidgetStatePropertyAll(p.ink.withValues(alpha: .16)),
              elevation: const WidgetStatePropertyAll(8),
              side: WidgetStatePropertyAll(BorderSide(color: p.line)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
            ),
            menuChildren: [
              for (final option in widget.options)
                Semantics(
                  selected: option.value == widget.value,
                  child: MenuItemButton(
                    focusNode: option.value == widget.value
                        ? _selectedOptionFocus
                        : null,
                    onPressed: enabled
                        ? () => widget.onChanged!(option.value)
                        : null,
                    leadingIcon: option.icon == null
                        ? null
                        : Icon(option.icon, size: 20),
                    trailingIcon: option.value == widget.value
                        ? const Icon(Icons.check_rounded, size: 20)
                        : const SizedBox(width: 20),
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        option.value == widget.value ? p.accent : p.ink,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused) ||
                            option.value == widget.value) {
                          return p.accentSoft;
                        }
                        return Colors.transparent;
                      }),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: Text(
                      option.label,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
            ],
            builder: (context, controller, child) => CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                  if (enabled && !controller.isOpen) controller.open();
                },
              },
              child: Semantics(
                label: widget.label,
                expanded: _open,
                child: OutlinedButton(
                  focusNode: _focusNode,
                  onPressed: enabled
                      ? () => controller.isOpen
                            ? controller.close()
                            : controller.open()
                      : null,
                  style: ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(
                      Size.fromHeight(56),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    backgroundColor: WidgetStatePropertyAll(
                      enabled ? p.paper : p.card,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      enabled ? p.ink : p.muted,
                    ),
                    side: WidgetStateProperty.resolveWith(
                      (states) => BorderSide(
                        color: _open || states.contains(WidgetState.focused)
                            ? p.accent
                            : p.line,
                        width: _open || states.contains(WidgetState.focused)
                            ? 1.5
                            : 1,
                      ),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selected.icon != null) ...[
                        Icon(
                          selected.icon,
                          size: 20,
                          color: enabled ? p.accent : p.muted,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          selected.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        _open
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: p.muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
