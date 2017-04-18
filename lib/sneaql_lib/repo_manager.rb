require 'git'
require 'open-uri'

require_relative 'base.rb'

module Sneaql
  # Classes to manage repositories full of SneaQL code.
  module RepoManagers

    # tells you the repo type based upon the url
    # either git or http
    # @param [String] repo_url
    def self.repo_type_from_url(repo_url)
      return 'git' if repo_url.match(/\.*git.*/i)
      return 'http' if repo_url.match(/\.*http.*/i)
    end

    # pulls a branch from a remote git repo
    class GitRepoManager < Sneaql::Core::RepoDownloadManager
      Sneaql::Core::RegisterMappedClass.new(
        :repo_manager,
        'git',
        Sneaql::RepoManagers::GitRepoManager
      )

      # Pulls down the repo and checks out the branch.
      def manage_repo
        drop_and_rebuild_directory(@repo_base_dir)
        clone_repo(@params[:repo_url])
        checkout_branch(@params[:git_branch])
      end

      # Clones a git repo to the local file system.
      # @param [String] repo_uri
      def clone_repo(repo_uri)
        Dir.chdir(@repo_base_dir) do
          @logger.info("cloning git repo #{repo_uri}")
          @local_repo = Git.clone(repo_uri, @repo_base_dir)
        end
      end

      # Checks out specified branch/commit from local repo.
      # @param [String] branch
      def checkout_branch(branch)
        Dir.chdir(@repo_base_dir) do
          @logger.info("checking out branch #{branch}")
          @local_repo.checkout(branch.to_s)
        end
      end
    end

    # pulls single archive file from http/https source
    class HttpStoreRepoManager < Sneaql::Core::RepoDownloadManager
      Sneaql::Core::RegisterMappedClass.new(
        :repo_manager,
        'http',
        Sneaql::RepoManagers::HttpStoreRepoManager
      )

      # Pulls a zip file from an HTTP store down to local file system
      # then unzips it for use in transform.
      def manage_repo
        drop_and_rebuild_directory(@repo_base_dir)
        pull_transform_repo_from_http_store(@params[:repo_url])
        if @params[:compression] == 'zip'
          unzip_file("#{@repo_base_dir}/#{File.basename(@params[:repo_url])}", @repo_base_dir)
        end
      end

      # Pulls the transfrom to local file system.
      # @param [String] repo_url
      def pull_transform_repo_from_http_store(repo_url)
        @logger.info "repo #{repo_url} to #{@repo_base_dir}/#{File.basename(repo_url)}"
        File.write("#{@repo_base_dir}/#{File.basename(repo_url)}", open(repo_url).read)
      end
    end

    # refers to repo in local file system
    class LocalFileSystemRepoManager < Sneaql::Core::RepoDownloadManager
      Sneaql::Core::RegisterMappedClass.new(
        :repo_manager,
        'local',
        Sneaql::RepoManagers::LocalFileSystemRepoManager
      )

      # Repo is simply a local file system reference.
      def manage_repo
        # overrides the value created by the
        # constructor with the directory provided
        @repo_base_dir = @params[:repo_base_dir]
      end
    end
  end
end
