import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/atoms/app_chip.dart';
import 'package:compapp_design/src/atoms/app_text_field.dart';
import 'package:compapp_design/src/models/task_composer_view.dart';
import 'package:compapp_design/src/models/task_submission.dart';
import 'package:compapp_design/src/models/task_suggestion.dart';
import 'package:compapp_design/src/models/task_target.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The form that logs what someone did: a field for the name of the task, the
/// known tasks that match it, chips to tie it to a room or a thing, and the
/// button that logs it.
///
/// It composes [AppTextField], [AppChip] and [AppButton] and takes plain data
/// ([TaskComposerView]) and four callbacks: [onQuery] with the text as it is
/// typed, [onPick] with the id of the chosen suggestion, [onLink] with the
/// room or item to tie the task to (or null when the chip that is on is
/// pressed again, to untie it) and [onSubmit] with the name and the link of
/// what is logged. The app owns the text, the suggestions and the link: it
/// answers [onQuery] with a new view whose query is the text, and a query it
/// changes by itself (a picked suggestion, an emptied form after logging)
/// replaces what is in the field. The field keeps its focus and its caret
/// across views. The texts sent through [onQuery] are remembered until the app
/// answers: a query that comes back as one of them, even late and after more
/// was typed, is an echo and leaves the field alone, so only a change the app
/// makes by itself replaces the text.
///
/// The button logs the name once the field has something other than spaces, by
/// a tap or by the keyboard's done key, and calls [onSubmit] with a
/// [TaskSubmission]: the name in the field without the spaces around it, even
/// when the app has not yet heard the last key, and the link.
///
/// Matching, which the app does, ignores case and extra
/// spaces like the backend catalog, so the same task is never offered twice:
/// the composer also leaves out a suggestion whose title is the same as an
/// earlier one by that rule. While the view is submitting the button waits,
/// the field is read-only (it keeps its focus and its look), and the
/// suggestions and the chips are disabled, so the form cannot change under the
/// request.
///
/// A link is told by the chip's check and its border, never by color alone,
/// and an item is a dashed chip where a room is solid. For assistive
/// technology the form is a container; the suggestions are a list named by
/// [TaskComposerView.suggestionsLabel] whose items are single button nodes
/// (the title and the subtitle together, so the spoken name is the visible
/// text); the chips are a container named by [TaskComposerView.targetsLabel].
///
/// It is a plain column that takes its height from its content and needs a
/// bounded width. It grows with large text instead of clipping, the chips and
/// the suggestions wrapping and nothing clamped, and it mirrors in
/// right-to-left. It has no motion of its own besides the button's spinner.
class TaskComposer extends StatefulWidget {
  const new({
    required this.view,
    required this.onQuery,
    required this.onPick,
    required this.onLink,
    required this.onSubmit,
    super.key,
  });

  final TaskComposerView view;

  /// Called with the text of the field every time it changes.
  final ValueChanged<String> onQuery;

  /// Called with the id of the chosen suggestion.
  final ValueChanged<String> onPick;

  /// Called with the target to link, or null to remove the link.
  final ValueChanged<TaskTarget?> onLink;

  /// Called with the name, without the spaces around it, and the link.
  final ValueChanged<TaskSubmission> onSubmit;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  @override
  State<TaskComposer> createState() => _TaskComposerState();
}

class _TaskComposerState extends State<TaskComposer> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.view.query,
  );

  /// The texts sent through onQuery that the app has not answered yet. A query
  /// that comes back as one of them is the echo of what was typed, possibly
  /// late, and never replaces the field.
  final List<String> _sent = [];

  static const int _maxSent = 64;

  void _onChanged(String text) {
    _sent.add(text);
    if (_sent.length > _maxSent) _sent.removeAt(0);
    widget.onQuery(text);
  }

  @override
  void didUpdateWidget(TaskComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.view.query;
    if (query == oldWidget.view.query) return;
    final echo = _sent.indexOf(query);
    if (echo >= 0) {
      _sent.removeRange(0, echo + 1);
      return;
    }
    // The app changed the query itself (a pick, a reset).
    _sent.clear();
    if (query != _controller.text) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Whether the name in the field, not the query of the view (the app may not
  /// have heard the last key yet), has more than spaces and nothing is
  /// waiting.
  bool _canSubmit(String text) =>
      !widget.view.submitting && text.trim().isNotEmpty;

  void _submit() {
    final text = _controller.text;
    if (!_canSubmit(text)) return;
    widget.onSubmit(
      TaskSubmission(name: text.trim(), target: widget.view.linked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    assert(
      _unique(view.suggestions.map((s) => s.id)),
      'The ids of the suggestions are the row keys',
    );
    assert(
      _unique(view.rooms.map((r) => r.id)),
      'The ids of the rooms are the chip keys',
    );
    assert(
      _unique(view.items.map((i) => i.id)),
      'The ids of the items are the chip keys',
    );
    assert(
      view.linked == null ||
          (view.linked!.kind == TaskTargetKind.room
                  ? view.rooms.map((r) => r.id)
                  : view.items.map((i) => i.id))
              .contains(view.linked!.id),
      'The linked target is one of the rooms or items',
    );
    final scheme = Theme.of(context).colorScheme;
    final suggestions = _distinct(view.suggestions);
    final hasTargets = view.rooms.isNotEmpty || view.items.isNotEmpty;

    return Semantics(
      key: const Key('tasks.composer'),
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.form,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: TaskComposer._gap,
            children: [
              // The field comes first and never moves, so it keeps its focus
              // while the sections under it come and go.
              AppTextField(
                key: const Key('tasks.composer.field'),
                label: view.label,
                controller: _controller,
                hint: view.hint,
                helperText: view.helperText,
                readOnly: view.submitting,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onChanged: _onChanged,
                onSubmitted: (_) => _submit(),
              ),
              if (suggestions.isNotEmpty)
                _Suggestions(
                  key: const ValueKey('suggestions'),
                  label: view.suggestionsLabel,
                  suggestions: suggestions,
                  enabled: !view.submitting,
                  onPick: widget.onPick,
                ),
              if (hasTargets)
                _Targets(
                  key: const ValueKey('targets'),
                  view: view,
                  onLink: widget.onLink,
                ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => AppButton(
                  key: const Key('tasks.composer.submit'),
                  label: view.submitLabel,
                  onPressed: _canSubmit(value.text) ? _submit : null,
                  loading: view.submitting,
                  loadingSemanticLabel: view.loadingLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The suggestions without any whose title is the same, ignoring case and
  /// extra spaces, as an earlier one.
  static List<TaskSuggestion> _distinct(List<TaskSuggestion> suggestions) {
    final seen = <String>{};
    return [
      for (final suggestion in suggestions)
        if (seen.add(_normalize(suggestion.title))) suggestion,
    ];
  }

  static bool _unique(Iterable<String> ids) {
    final list = ids.toList();
    return list.length == list.toSet().length;
  }
}

/// A task name the way the backend catalog compares it: without the spaces at
/// the ends, with every run of spaces as one, and in lower case.
String _normalize(String name) =>
    name.trim().split(RegExp(r'\s+')).join(' ').toLowerCase();

/// The list of known tasks that match what is typed, one button per task.
class _Suggestions extends StatelessWidget {
  const new({
    required this.label,
    required this.suggestions,
    required this.enabled,
    required this.onPick,
    super.key,
  });

  final String label;
  final List<TaskSuggestion> suggestions;
  final bool enabled;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: const Key('tasks.composer.suggestions'),
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.list,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < suggestions.length; i++) ...[
              if (i > 0)
                SizedBox(
                  height: AppSizes.hairline,
                  child: ColoredBox(color: scheme.outlineVariant),
                ),
              _Suggestion(
                key: ValueKey(suggestions[i].id),
                suggestion: suggestions[i],
                onTap: enabled ? () => onPick(suggestions[i].id) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One suggestion: its title and subtitle as one button.
class _Suggestion extends StatelessWidget {
  const new({required this.suggestion, required this.onTap, super.key});

  final TaskSuggestion suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = suggestion.subtitle;
    final enabled = onTap != null;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.listItem,
      child: TextButton(
        key: Key('tasks.composer.suggestion.${suggestion.id}'),
        onPressed: onTap,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.fromHeight(AppSizes.controlLg),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
          ),
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: WidgetStatePropertyAll(
            enabled ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            ),
          ),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                suggestion.title,
                textAlign: TextAlign.start,
                style: AppTypography.labelLg.copyWith(
                  color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chips that tie the task to a room or an item, rooms first.
class _Targets extends StatelessWidget {
  const new({required this.view, required this.onLink, super.key});

  final TaskComposerView view;
  final ValueChanged<TaskTarget?> onLink;

  @override
  Widget build(BuildContext context) {
    final linked = view.linked;
    final enabled = !view.submitting;

    Widget chip(TaskTargetKind kind, String id, String label) {
      final target = TaskTarget(kind, id);
      final selected = linked == target;
      return AppChip(
        key: Key('tasks.composer.${kind.name}.$id'),
        label: label,
        kind: kind == TaskTargetKind.room ? AppChipKind.room : AppChipKind.item,
        selected: selected,
        onTap: enabled ? () => onLink(selected ? null : target) : null,
      );
    }

    return Semantics(
      key: const Key('tasks.composer.targets'),
      container: true,
      explicitChildNodes: true,
      label: view.targetsLabel,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final room in view.rooms)
            chip(TaskTargetKind.room, room.id, room.name),
          for (final item in view.items)
            chip(TaskTargetKind.item, item.id, item.name),
        ],
      ),
    );
  }
}
