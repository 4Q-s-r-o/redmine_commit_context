require 'digest/md5'

module RedmineCommitContext
  # Deterministic display identifier + color bucket for a repository badge.
  module RepositoryBadge
    COLOR_COUNT = 8

    # Falls back to the URL basename when the repository has no identifier
    # (e.g. the default/only repository of a project).
    def self.identifier_for(repository)
      return nil if repository.nil?

      identifier = repository.identifier
      return identifier if identifier.present?

      basename = File.basename(repository.url.to_s)
      basename = basename.sub(/\.git\z/, '')
      basename.presence || "repo-#{repository.id}"
    end

    def self.color_index_for(identifier)
      Digest::MD5.hexdigest(identifier.to_s).to_i(16) % COLOR_COUNT
    end
  end
end
