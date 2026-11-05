import 'package:flutter_test/flutter_test.dart';

import '../../tool/next_version.dart';

String? next(String? tag, List<CommitMessage> commits) =>
    nextVersion(lastTag: tag, commits: commits)?.toString();

void main() {
  group('nextVersion', () {
    test('starts from 0.0.0 when there is no tag, so feat gives 0.1.0', () {
      expect(next(null, const [CommitMessage('feat: first')]), '0.1.0');
    });

    test('without a tag a non-feat gives 0.0.1', () {
      expect(next(null, const [CommitMessage('docs: readme')]), '0.0.1');
    });

    test('feat bumps the minor version and resets the patch', () {
      expect(
        next('v0.1.3', const [
          CommitMessage('fix: a'),
          CommitMessage('feat(atoms): b'),
        ]),
        '0.2.0',
      );
    });

    test('fix, refactor, ci and the rest bump the patch', () {
      for (final type in [
        'fix',
        'refactor',
        'perf',
        'docs',
        'test',
        'ci',
        'chore',
        'build',
        'style',
      ]) {
        expect(next('v1.4.2', [CommitMessage('$type: change')]), '1.4.3');
      }
    });

    test('non-conventional subjects bump the patch', () {
      expect(
        next('v0.2.0', const [
          CommitMessage('Update stuff'),
          CommitMessage('feature: not a type'),
        ]),
        '0.2.1',
      );
    });

    test('malformed subjects never count as feat or breaking', () {
      for (final subject in [
        'feat:x',
        'feat : x',
        'feat!(x): y',
        'feat(a(b)): y',
        'feat(x)!:y',
        'feat: ',
      ]) {
        expect(
          next('v1.0.0', [CommitMessage(subject)]),
          '1.0.1',
          reason: subject,
        );
      }
    });

    test('well-formed subjects with a scope or a bang count', () {
      expect(next('v1.0.0', const [CommitMessage('feat(a-b): y')]), '1.1.0');
      expect(next('v1.0.0', const [CommitMessage('fix(a)!: y')]), '2.0.0');
    });

    test('breaking on 0.x bumps the minor version', () {
      expect(next('v0.3.1', const [CommitMessage('fix!: drop prop')]), '0.4.0');
    });

    test('breaking from 1.0.0 bumps the major version', () {
      expect(
        next('v1.2.3', const [CommitMessage('feat(button)!: rename prop')]),
        '2.0.0',
      );
    });

    test('a BREAKING CHANGE footer counts as breaking', () {
      const commit = CommitMessage(
        'refactor: rework tokens',
        'Details.\n\nBREAKING CHANGE: AppSpacing.x is gone',
      );
      expect(next('v0.5.0', const [commit]), '0.6.0');
      expect(next('v2.0.0', const [commit]), '3.0.0');
    });

    test('a BREAKING-CHANGE footer is accepted too', () {
      const commit = CommitMessage('fix: x', 'BREAKING-CHANGE: y');
      expect(next('v1.0.0', const [commit]), '2.0.0');
    });

    test('a BREAKING CHANGE line outside the footer paragraph is ignored', () {
      const commit = CommitMessage(
        'docs: explain the footer',
        'Example:\nBREAKING CHANGE: shown as a sample\n\nMore text.\n\n'
            'Refs: #1',
      );
      expect(next('v1.0.0', const [commit]), '1.0.1');
    });

    test('a footer followed by a Signed-off-by paragraph still counts', () {
      const commit = CommitMessage(
        'fix: x',
        'BREAKING CHANGE: y\n\nSigned-off-by: A Dev <a@b.c>',
      );
      expect(next('v1.0.0', const [commit]), '2.0.0');
    });

    test('a footer followed by a Co-authored-by paragraph still counts', () {
      const commit = CommitMessage(
        'fix: x',
        'Why.\n\nBREAKING CHANGE: y\n\nCo-authored-by: A Dev <a@b.c>',
      );
      expect(next('v1.0.0', const [commit]), '2.0.0');
    });

    test('a footer block spread over two trailing paragraphs counts', () {
      const commit = CommitMessage(
        'fix: x',
        'Why.\n\nBREAKING CHANGE: y\n\nRefs: #1\nReviewed-by: B\n\n'
            'Signed-off-by: A',
      );
      expect(next('v0.5.0', const [commit]), '0.6.0');
    });

    test('a breaking footer above a prose paragraph is ignored', () {
      const commit = CommitMessage(
        'fix: x',
        'BREAKING CHANGE: y\n\nSome closing prose, not a footer.',
      );
      expect(next('v1.0.0', const [commit]), '1.0.1');
    });

    test('a one-paragraph body that only mentions the footer is ignored', () {
      const commit = CommitMessage(
        'docs: explain breaking changes',
        'Use a footer like\nBREAKING CHANGE: describe it',
      );
      expect(next('v1.0.0', const [commit]), '1.0.1');
    });

    test('breaking wins over feat', () {
      expect(
        next('v1.0.0', const [
          CommitMessage('feat: a'),
          CommitMessage('fix!: b'),
        ]),
        '2.0.0',
      );
    });

    test('returns null when there are no commits', () {
      expect(next('v0.1.0', const []), isNull);
    });

    test('accepts tags with or without the v prefix', () {
      expect(next('0.1.0', const [CommitMessage('fix: a')]), '0.1.1');
    });
  });

  group('latestReleaseTag', () {
    test('returns null for no tags', () {
      expect(latestReleaseTag(const []), isNull);
    });

    test('picks the highest version, not the last or alphabetical one', () {
      expect(latestReleaseTag(['v0.9.0', 'v0.10.0', 'v0.2.0']), 'v0.10.0');
    });

    test('ignores prerelease tags', () {
      expect(latestReleaseTag(['v0.1.0', 'v0.2.0-rc1']), 'v0.1.0');
    });

    test('ignores invalid tags', () {
      expect(
        latestReleaseTag([
          'v1.2',
          'v1',
          'vNext',
          '1.5.0',
          'v0.1.0',
          'v1.2.3.4',
        ]),
        'v0.1.0',
      );
    });

    test('ignores tags with leading zeros', () {
      expect(latestReleaseTag(['v0.1.0', 'v0.02.0', 'v00.3.0']), 'v0.1.0');
      expect(latestReleaseTag(['v0.02.0']), isNull);
    });

    test('returns null when no tag is a strict release', () {
      expect(latestReleaseTag(['v0.2.0-rc1', 'v1.2']), isNull);
    });

    test('picks the highest of several tags on one commit', () {
      expect(latestReleaseTag(['v0.1.0', 'v0.1.1', 'v0.1.0']), 'v0.1.1');
    });

    test('keeps the higher tag when a lower one is merged later', () {
      expect(latestReleaseTag(['v0.2.0', 'v0.1.1']), 'v0.2.0');
      expect(latestReleaseTag(['v0.1.1', 'v0.2.0']), 'v0.2.0');
    });

    test('a prerelease after a release leaves the release as the base', () {
      final tag = latestReleaseTag(['v0.1.0', 'v0.2.0-rc1']);
      expect(next(tag, const [CommitMessage('fix: a')]), '0.1.1');
    });

    test('ignores blank lines in the tag list', () {
      expect(latestReleaseTag(['', 'v0.1.0', '']), 'v0.1.0');
    });
  });

  group('parseLog', () {
    String entry(String parents, String subject, [String body = '']) =>
        '$parents\x1f$subject\x1f$body\x1e';

    test('parses subjects and bodies', () {
      final commits = parseLog(
        '${entry('aaa', 'feat: a', 'Body.\n\nBREAKING CHANGE: x')}\n'
        '${entry('bbb', 'fix: b')}',
      );
      expect(commits.map((c) => c.subject), ['feat: a', 'fix: b']);
      expect(commits.first.body, 'Body.\n\nBREAKING CHANGE: x');
      expect(commits.last.body, isEmpty);
    });

    test('drops merge commits, whatever their subject or body say', () {
      final commits = parseLog(
        '${entry('aaa bbb', 'Merge pull request #5 from x/y', 'feat: from PR')}'
        '${entry('ccc', 'fix: real')}',
      );
      expect(commits.map((c) => c.subject), ['fix: real']);
    });

    test('keeps a single-parent commit whose subject starts with Merge', () {
      final commits = parseLog(entry('aaa', 'Merge conflicts doc: explain'));
      expect(commits, hasLength(1));
    });

    test('keeps a root commit with no parents', () {
      final commits = parseLog(entry('', 'chore: init'));
      expect(commits.map((c) => c.subject), ['chore: init']);
    });

    test('only merge commits leave nothing to release', () {
      final commits = parseLog(entry('aaa bbb', 'Merge branch main'));
      expect(next('v0.1.0', commits), isNull);
    });

    test('empty output gives no commits', () {
      expect(parseLog(''), isEmpty);
    });
  });

  group('SemVer', () {
    test('tryParse rejects anything that is not X.Y.Z', () {
      expect(SemVer.tryParse('v1.2'), isNull);
      expect(SemVer.tryParse('latest'), isNull);
      expect(SemVer.tryParse('v1.2.3-rc.1'), isNull);
      expect(SemVer.tryParse('v1.02.3'), isNull);
      expect(SemVer.tryParse('v1.0.0'), isNotNull);
    });

    test('compareTo orders numerically', () {
      expect(const SemVer(0, 10, 0).compareTo(const SemVer(0, 9, 9)), 1);
      expect(const SemVer(1, 0, 0).compareTo(const SemVer(1, 0, 0)), 0);
      expect(const SemVer(0, 1, 1).compareTo(const SemVer(0, 2, 0)), -1);
    });
  });
}
