# Changelog

## 0.3.0

- Revisions for a version: the version show page (`/versions/:id`) now lists
  every revision linked to an issue that belongs to the version, using the
  same compact one-line rendering as the issue tab. Paginated; includes a
  CSV export link.
- Revisions for issues: a new "Show revisions" link, under a "Revisions"
  heading in the issues index sidebar, opens a page listing the revisions
  linked to the issues matched by the current filter — including saved
  queries (`query_id`), ad-hoc URL filters, and cross-module tag filters
  such as `sprint:current`. Filtering itself is entirely delegated to
  `IssueQuery`, the same way `IssuesController` does it. That page also
  shows the saved-queries sidebar, so it navigates like the issues list.
- Both new pages show an aggregated "N files in M repositories" summary
  above the revisions list, with a collapsible per-repository breakdown.
- Both new pages support CSV export (`repository, revision, author, date,
  added, modified, deleted, message`), respecting the same permissions as
  the HTML view.
- The issue tab's rendering logic has been extracted into a shared partial
  (`commit_context/_revisions`), reused by the new version and filter
  pages. Its markup is unchanged, with one deliberate exception: `#123`-style
  issue references in the commit message are now clickable links to that
  issue (permission-checked, same as everywhere else in Redmine) — this
  applies everywhere the shared partial is used, issue tab included.
- The sidebar link and the new controller both independently re-check
  `:view_changesets` — the permission that already governs which
  changesets `Changeset.visible` returns — before showing anything.
  A user with no repository-viewing permission in any project never sees
  the link and gets a 403/login redirect on a direct hit.

## 0.2.0

- New plugin setting "Show project name for revisions from other projects"
  (on by default) to hide the per-row project prefix on Redmine instances
  where every changeset already belongs to the current issue's project.
- Commit message now wraps onto its own full-width line instead of being
  truncated with an ellipsis when it doesn't fit next to the other columns,
  with a little extra bottom padding so a wrapped message stays visually
  separated from the next revision.
- Commit date is now rendered the same way as elsewhere in Redmine
  (relative time, e.g. "14 days ago", with the exact date/time on hover)
  instead of the absolute timestamp.

## 0.1.0

- Initial MVP release.
- Compact one-line rendering of associated revisions on the issue view:
  repository badge, short SHA with link to revision, author, commit date,
  `+A ~M −D` file-change counts, diff link, first line of the commit
  message.
- Header with revision and repository counts.
- Deterministic, color-coded repository badges.
- Aggregated single-query file-change counts (no N+1 on `filechanges`).
- English, Czech and Slovak translations.
