module RedmineCommitContext
  # Aggregates file-change counts (added/modified/deleted) for a set of
  # changesets in a single query, to avoid N+1 queries on
  # changeset.filechanges when rendering a list of revisions.
  module ChangeStats
    EMPTY_COUNTS = { added: 0, modified: 0, deleted: 0 }.freeze

    def self.for_changesets(changesets)
      ids = Array(changesets).map(&:id)
      return {} if ids.empty?

      counts = {}
      Change.where(changeset_id: ids).group(:changeset_id, :action).count.each do |(changeset_id, action), count|
        bucket = bucket_for(action)
        entry = (counts[changeset_id] ||= EMPTY_COUNTS.dup)
        entry[bucket] += count
      end
      counts
    end

    def self.bucket_for(action)
      case action
      when 'A' then :added
      when 'D' then :deleted
      else :modified
      end
    end
    private_class_method :bucket_for
  end
end
