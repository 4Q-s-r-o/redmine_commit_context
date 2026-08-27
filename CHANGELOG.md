# Changelog

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
