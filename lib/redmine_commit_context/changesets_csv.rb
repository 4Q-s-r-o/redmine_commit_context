require 'csv'

module RedmineCommitContext
  # CSV export for the version/filter revisions pages. Row set and content
  # mirror the HTML list exactly (same author fallback, same first-line-only
  # commit message) so the two never disagree on what "the list" contains.
  module ChangesetsCsv
    COLUMNS = %w[repository revision author date added modified deleted message].freeze

    def self.generate(changesets)
      changesets = Array(changesets)
      counts = RedmineCommitContext::ChangeStats.for_changesets(changesets)

      CSV.generate do |csv|
        csv << COLUMNS
        changesets.each do |changeset|
          entry = counts[changeset.id] || RedmineCommitContext::ChangeStats::EMPTY_COUNTS
          author = changeset.author
          author_name = author.is_a?(String) ? author : author.name

          csv << [
            RedmineCommitContext::RepositoryBadge.identifier_for(changeset.repository),
            changeset.revision.to_s,
            author_name,
            changeset.committed_on,
            entry[:added],
            entry[:modified],
            entry[:deleted],
            changeset.comments.to_s.each_line.first.to_s.strip
          ]
        end
      end
    end
  end
end
