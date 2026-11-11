import 'package:compapp_design/src/models/item_view.dart';
import 'package:compapp_design/src/models/room_view.dart';
import 'package:compapp_design/src/models/task_suggestion.dart';
import 'package:compapp_design/src/models/task_target.dart';
import 'package:flutter/foundation.dart';

/// What a task composer draws, as plain data: the [query] typed so far, the
/// [suggestions] the app found for it, the [rooms] and [items] a task can be
/// tied to, which of them is [linked], and the words around them.
///
/// Every string is the app's, already localized. [label] names the field and
/// is visible, [hint] is its placeholder and [helperText] is a line under it,
/// which the app uses to say that the name is a new task. [suggestionsLabel]
/// is the spoken name of the list of suggestions and [targetsLabel] the spoken
/// name of the chips that link a room or an item; neither is visible.
/// [submitLabel] is the visible label of the button, and while [submitting]
/// the button waits, with [loadingLabel] as its spoken value, and nothing else
/// can be changed.
///
/// The ids of the suggestions, of the rooms and of the items are the keys of
/// their rows and chips, so each list must have unique ids. Which suggestions
/// match the query is the app's decision: matching ignores case and extra
/// spaces, as the backend catalog does, so the same task is never offered
/// twice, and the composer also leaves out a suggestion whose title is
/// the same as an earlier one by that rule.
@immutable
class TaskComposerView {
  const new({
    required this.query,
    required this.suggestions,
    required this.rooms,
    required this.items,
    required this.label,
    required this.suggestionsLabel,
    required this.targetsLabel,
    required this.submitLabel,
    this.linked,
    this.hint,
    this.helperText,
    this.submitting = false,
    this.loadingLabel,
  }) : assert(label != '', 'The field needs a label'),
       assert(suggestionsLabel != '', 'The list needs a spoken name'),
       assert(targetsLabel != '', 'The chips need a spoken name'),
       assert(submitLabel != '', 'The button needs a label');

  final String query;
  final List<TaskSuggestion> suggestions;
  final List<RoomView> rooms;
  final List<ItemView> items;
  final TaskTarget? linked;
  final String label;
  final String? hint;
  final String? helperText;
  final String suggestionsLabel;
  final String targetsLabel;
  final String submitLabel;
  final bool submitting;
  final String? loadingLabel;

  @override
  bool operator ==(Object other) =>
      other is TaskComposerView &&
      other.query == query &&
      listEquals(other.suggestions, suggestions) &&
      listEquals(other.rooms, rooms) &&
      listEquals(other.items, items) &&
      other.linked == linked &&
      other.label == label &&
      other.hint == hint &&
      other.helperText == helperText &&
      other.suggestionsLabel == suggestionsLabel &&
      other.targetsLabel == targetsLabel &&
      other.submitLabel == submitLabel &&
      other.submitting == submitting &&
      other.loadingLabel == loadingLabel;

  @override
  int get hashCode => Object.hash(
    query,
    Object.hashAll(suggestions),
    Object.hashAll(rooms),
    Object.hashAll(items),
    linked,
    label,
    hint,
    helperText,
    suggestionsLabel,
    targetsLabel,
    submitLabel,
    submitting,
    loadingLabel,
  );
}
