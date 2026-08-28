module RedmineCommitContext
  # The revisions-for-version and revisions-for-filter pages surface exactly
  # the same data as the issue's "Associated revisions" tab, so they are
  # gated on the same permission that already governs that data:
  # `:view_changesets` (core, "repository" module) -- the permission
  # `Changeset.visible` itself filters on. Gating on `:browse_repository`
  # instead would decouple the gate from the data: a user could see the link
  # but get an always-empty list (browse_repository without view_changesets),
  # or have the data but never see the entry point (view_changesets without
  # browse_repository).
  module Permissions
    REVISIONS = :view_changesets

    # Whether the user has REVISIONS in at least one project (optionally
    # restricted to a single project and its subprojects). Cheap existence
    # check, safe to call before rendering a link.
    def self.revisions_visible_anywhere?(user, project = nil)
      scope = project ? Project.allowed_to(user, REVISIONS, :project => project) : Project.allowed_to(user, REVISIONS)
      scope.exists?
    end
  end
end
