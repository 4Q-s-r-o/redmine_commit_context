require_relative '../test_helper'

class RepositoryBadgeTest < ActiveSupport::TestCase
  RepositoryDouble = Struct.new(:identifier, :url, :id)

  def test_identifier_for_returns_identifier_when_present
    repository = RepositoryDouble.new('main', 'file:///srv/git/main.git', 1)
    assert_equal 'main', RedmineCommitContext::RepositoryBadge.identifier_for(repository)
  end

  def test_identifier_for_falls_back_to_url_basename_when_identifier_blank
    repository = RepositoryDouble.new('', 'file:///srv/git/legacy-app.git', 2)
    assert_equal 'legacy-app', RedmineCommitContext::RepositoryBadge.identifier_for(repository)
  end

  def test_identifier_for_strips_git_suffix_only_once
    repository = RepositoryDouble.new(nil, 'file:///srv/git/vendor/tools.git', 3)
    assert_equal 'tools', RedmineCommitContext::RepositoryBadge.identifier_for(repository)
  end

  def test_identifier_for_two_repositories_with_same_basename_in_different_directories
    repo_a = RepositoryDouble.new(nil, 'file:///srv/git/team-a/shared.git', 4)
    repo_b = RepositoryDouble.new(nil, 'file:///srv/git/team-b/shared.git', 5)

    identifier_a = RedmineCommitContext::RepositoryBadge.identifier_for(repo_a)
    identifier_b = RedmineCommitContext::RepositoryBadge.identifier_for(repo_b)

    # Known MVP limitation: badge identifier is derived from the URL
    # basename only, so two repositories with an identical basename but
    # different parent directories display the same badge label and color.
    # Setting a repository "identifier" in Redmine disambiguates them.
    assert_equal identifier_a, identifier_b
    assert_equal RedmineCommitContext::RepositoryBadge.color_index_for(identifier_a),
                 RedmineCommitContext::RepositoryBadge.color_index_for(identifier_b)
  end

  def test_color_index_for_is_deterministic
    index_1 = RedmineCommitContext::RepositoryBadge.color_index_for('main')
    index_2 = RedmineCommitContext::RepositoryBadge.color_index_for('main')
    assert_equal index_1, index_2
    assert_includes(0..7, index_1)
  end
end
