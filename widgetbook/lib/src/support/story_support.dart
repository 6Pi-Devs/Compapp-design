import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/widgets.dart';

/// The padding every use case sits in, so goldens and the semantics host show
/// the component with room around it.
Widget useCaseFrame({required Widget child}) {
  return Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child);
}

/// Freezes motion for a use case, as the system's "reduce motion" setting
/// does. Spinners and other loops stand still, so goldens are deterministic
/// and `pumpAndSettle` can finish.
class FrozenMotion extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    );
  }
}

/// Owns a [WidgetStatesController] that holds [states], so a use case can show
/// a state a static builder cannot reach by gesture, such as pressed.
class StatesControllerHost extends StatefulWidget {
  const new({required this.states, required this.builder, super.key});

  final Set<WidgetState> states;
  final Widget Function(BuildContext context, WidgetStatesController controller)
  builder;

  @override
  State<StatesControllerHost> createState() => _StatesControllerHostState();
}

class _StatesControllerHostState extends State<StatesControllerHost> {
  late final WidgetStatesController _controller = WidgetStatesController(
    widget.states,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Owns a [TextEditingController] that starts with [text], so a use case can
/// show a filled field and the controller is disposed with it.
class TextControllerHost extends StatefulWidget {
  const new({required this.text, required this.builder, super.key});

  final String text;
  final Widget Function(BuildContext context, TextEditingController controller)
  builder;

  @override
  State<TextControllerHost> createState() => _TextControllerHostState();
}

class _TextControllerHostState extends State<TextControllerHost> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  )..selection = TextSelection.collapsed(offset: widget.text.length);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// A focus node that always reports focus, so a use case can show the focused
/// look of a field in every golden scenario. Only one widget can really hold
/// the primary focus, and the four scenarios of a golden render side by side.
class _FocusedNode extends FocusNode {
  @override
  bool get hasFocus => true;
}

/// Owns a [FocusNode] that reports focus (see [_FocusedNode]) and disposes it.
class FocusedNodeHost extends StatefulWidget {
  const new({required this.builder, super.key});

  final Widget Function(BuildContext context, FocusNode focusNode) builder;

  @override
  State<FocusedNodeHost> createState() => _FocusedNodeHostState();
}

class _FocusedNodeHostState extends State<FocusedNodeHost> {
  final FocusNode _node = _FocusedNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _node);
}

/// Holds a value a playground lets the user change by interaction (a switch
/// flipped, a chip selected). A knob gives the [initial] value: when the knob
/// changes, the value is reset to it, and in between the interaction drives
/// the local state.
class SeededState<T> extends StatefulWidget {
  const new({required this.initial, required this.builder, super.key});

  final T initial;
  final Widget Function(
    BuildContext context,
    T value,
    ValueChanged<T> onChanged,
  )
  builder;

  @override
  State<SeededState<T>> createState() => _SeededStateState<T>();
}

class _SeededStateState<T> extends State<SeededState<T>> {
  late T _value = widget.initial;

  @override
  void didUpdateWidget(SeededState<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _value,
    (value) => setState(() => _value = value),
  );
}
