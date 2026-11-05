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
