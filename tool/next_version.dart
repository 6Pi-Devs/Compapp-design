// Computes the next release version from the git history. Run from the
// repository root: `dart tool/next_version.dart` prints `X.Y.Z`.
//
// Exit codes: 0 version printed, 1 nothing to release, 2 git failed,
// 3 the computed tag already exists.
import 'dart:io';

enum Bump { patch, minor, major }

class SemVer implements Comparable<SemVer> {
  const new(this.major, this.minor, this.patch);

  /// Parses a strict `X.Y.Z` with an optional leading `v`, or returns null.
  /// Prerelease and build suffixes are rejected.
  static SemVer? tryParse(String tag) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(tag.trim());
    if (match == null) return null;
    return SemVer(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final int major;
  final int minor;
  final int patch;

  SemVer apply(Bump bump) => switch (bump) {
    Bump.major => SemVer(major + 1, 0, 0),
    Bump.minor => SemVer(major, minor + 1, 0),
    Bump.patch => SemVer(major, minor, patch + 1),
  };

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class CommitMessage {
  const new(this.subject, [this.body = '']);

  final String subject;
  final String body;
}

/// The highest strict `vX.Y.Z` tag among [tags], or null. Prerelease tags
/// (`v0.2.0-rc1`), tags without the `v` prefix and anything that is not
/// exactly three numeric parts are ignored.
String? latestReleaseTag(Iterable<String> tags) {
  SemVer? best;
  for (final tag in tags) {
    final trimmed = tag.trim();
    if (!trimmed.startsWith('v')) continue;
    final version = SemVer.tryParse(trimmed);
    if (version == null) continue;
    if (best == null || version.compareTo(best) > 0) best = version;
  }
  return best == null ? null : 'v$best';
}

/// Format string for `git log` that [parseLog] understands.
const logFormat = '%P%x1f%s%x1f%b%x1e';

/// Parses the output of `git log --format=[logFormat]`. Merge commits (two or
/// more parents) are dropped: their subject and body only repeat a PR title.
List<CommitMessage> parseLog(String raw) {
  final commits = <CommitMessage>[];
  for (final entry in raw.split('\x1e')) {
    if (entry.trim().isEmpty) continue;
    final parts = entry.trim().split('\x1f');
    if (parts.length < 2) continue;
    final parents = parts[0].trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parents.length > 1) continue;
    commits.add(CommitMessage(parts[1], parts.length > 2 ? parts[2] : ''));
  }
  return commits;
}

/// Next version for [commits] made since [lastTag] (`null` when there is no
/// release tag yet, which starts from 0.0.0).
///
/// Only well-formed Conventional Commits count. A breaking change bumps the
/// major version, or the minor one while the base is 0.x. Otherwise a `feat`
/// bumps the minor version and anything else the patch version. Returns null
/// when there are no commits to release.
SemVer? nextVersion({
  required String? lastTag,
  required List<CommitMessage> commits,
}) {
  final base =
      (lastTag == null ? null : SemVer.tryParse(lastTag)) ??
      const SemVer(0, 0, 0);
  if (commits.isEmpty) return null;

  var bump = Bump.patch;
  for (final commit in commits) {
    if (_isBreaking(commit)) {
      return base.apply(base.major >= 1 ? Bump.major : Bump.minor);
    }
    if (_conventionalType(commit.subject) == 'feat') bump = Bump.minor;
  }
  return base.apply(bump);
}

// type, optional (scope) without nested parentheses, optional !, colon, one
// space and a description.
final _conventional = RegExp(r'^(\w+)(\([^()]*\))?(!)?: \S');

String? _conventionalType(String subject) =>
    _conventional.firstMatch(subject)?.group(1)?.toLowerCase();

bool _isBreaking(CommitMessage commit) {
  if (_conventional.firstMatch(commit.subject)?.group(3) != null) return true;
  final paragraphs = commit.body.trim().split(RegExp(r'\n\s*\n'));
  return RegExp(
    '^BREAKING[ -]CHANGE:',
    multiLine: true,
  ).hasMatch(paragraphs.last);
}

String? _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) return null;
  return (result.stdout as String).trim();
}

void main() {
  final tagList = _git(['tag', '--merged', 'HEAD', '--list', 'v*']);
  if (tagList == null) {
    stderr.writeln('Could not read the git tags. Fetch the full history.');
    exit(2);
  }
  final lastTag = latestReleaseTag(tagList.split('\n'));
  final range = lastTag == null ? 'HEAD' : '$lastTag..HEAD';
  final log = _git(['log', '--format=$logFormat', range]);
  if (log == null) {
    stderr.writeln('Could not read the git history. Fetch the full history.');
    exit(2);
  }

  final next = nextVersion(lastTag: lastTag, commits: parseLog(log));
  if (next == null) {
    stderr.writeln(
      'No commits since ${lastTag ?? 'the start'}: nothing to release.',
    );
    exit(1);
  }
  if (_git(['rev-parse', '-q', '--verify', 'refs/tags/v$next']) != null) {
    stderr.writeln('Tag v$next already exists: refusing to reuse it.');
    exit(3);
  }
  stdout.writeln(next);
}
