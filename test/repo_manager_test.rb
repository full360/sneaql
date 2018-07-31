require_relative "helpers/helper"

require_relative "#{$base_path}/lib/sneaql_lib/repo_manager.rb"

class TestRepoManager < Minitest::Test
  def test_local_repo
    r = Sneaql::RepoManagers::LocalFileSystemRepoManager.new(
      { repo_base_dir: "#{$base_path}/test/fixtures/test-transform" }
    )

    assert_equal(
      "#{$base_path}/test/fixtures/test-transform",
      r.repo_base_dir
    )

    [
      'begin.sql',
      'commit.sql',
      'insert.sql',
      'records.sql',
      'steps.json'
    ].each do |f|
      assert_equal(
        true,
        File.exist?("#{r.repo_base_dir}/#{f}")
      )
    end
  end

#  def test_http_store_repo
#    r = Sneaql::RepoManagers::HttpStoreRepoManager.new(
#      {
#        repo_base_dir: "#{$base_path}/test/tmp/",
#        repo_url: 'https://github.com/full360/jdbc-helpers/archive/master.zip',
#        compression: 'zip'
#      }
#    )
#
#    assert_equal(
#      true,
#      File.exist?("#{$base_path}/test/tmp/jdbc-helpers-master/README.md")
#    )
#  end

#  def test_git_repo
#    r = Sneaql::RepoManagers::GitRepoManager.new(
#      {
#        repo_base_dir: "#{$base_path}/test/tmp/",
#        repo_url: 'git@github.com:full360/jdbc-helpers.git',
#        git_branch: 'master'
#      }
#    )
#
#    assert_equal(
#      true,
#      File.exist?("#{$base_path}/test/tmp/README.md")
#    )
#  end
end
