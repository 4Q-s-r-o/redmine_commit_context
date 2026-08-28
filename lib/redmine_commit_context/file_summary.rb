module RedmineCommitContext
  # Aggregated "N files in M repositories" summary for a set of changesets,
  # in a single query over `changes` (no N+1). Repository objects are taken
  # from the already-preloaded changesets rather than queried again.
  module FileSummary
    Entry = Struct.new(:repository, :file_count, keyword_init: true)

    def self.for_changesets(changesets)
      changesets = Array(changesets)
      ids = changesets.map(&:id)
      return [] if ids.empty?

      repository_by_id = changesets.each_with_object({}) do |changeset, memo|
        memo[changeset.repository_id] ||= changeset.repository
      end

      counts = Change.joins(:changeset).
        where(:changeset_id => ids).
        group("#{Changeset.table_name}.repository_id").
        distinct.
        count(:path)

      counts.map do |repository_id, file_count|
        Entry.new(:repository => repository_by_id[repository_id], :file_count => file_count)
      end.sort_by { |entry| RedmineCommitContext::RepositoryBadge.identifier_for(entry.repository).to_s }
    end

    def self.total_files(entries)
      entries.sum(&:file_count)
    end
  end
end
