# Changelog

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
