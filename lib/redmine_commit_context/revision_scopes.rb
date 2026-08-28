module RedmineCommitContext
  # Builds the changeset scopes for the version and filter revisions pages.
  # `Changeset.visible` is mandatory in both: it is the only thing standing
  # between a filter/version that spans multiple projects and a user pulling
  # commits out of a repository they have no permission to see.
  module RevisionScopes
    def self.for_version(version)
      Changeset.visible.
        joins(:issues).
        where(:issues => { :fixed_version_id => version.id }).
        includes(:repository, :user).
        distinct.
        order(:committed_on)
    end

    # `issue_scope` is expected to be an Issue scope with visibility and
    # query filters already applied (IssueQuery#base_scope) -- it handles
    # issue visibility, Changeset.visible handles changeset visibility;
    # neither substitutes for the other.
    def self.for_issue_scope(issue_scope)
      Changeset.visible.
        joins(:issues).
        where(:issues => { :id => issue_scope.select(:id) }).
        includes(:repository, :user).
        distinct.
        order(:committed_on)
    end
  end
end
