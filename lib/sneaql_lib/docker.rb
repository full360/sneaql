require 'json'

module Sneaql
  module Docker
    class LocalTransformDockerfile
      
      def initialize(repo_dir, repo_tag)
        @repo_dir = repo_dir
        @repo_tag = repo_tag
        @steps = JSON.parse(
          File.read("#{repo_dir}/sneaql.json")
        )
        
        create_step_files
        create_dockerfile
      end
      
      def create_step_files()
        @step_files = []
        @step_files << {
          docker_path: 'sneaql.json',
          local_path: 'sneaql.json' #File.expand_path("#{repo_dir}/sneaql.json")
        }
        
        @steps.each { |s| 
          @step_files << {
            docker_path: s['step_file'],
            local_path: s['step_file'] # File.expand_path(s['step_file'])
          }
        }
      end

      def dockerfile()
%{FROM full360/sneaql:latest
RUN mkdir /repo 
#{@step_files.map {|s| "ADD #{s[:local_path]} /repo/#{s[:docker_path]}"}.join("\n")}
}
      end

      def create_dockerfile
        Dir.chdir(@repo_dir) do
          puts "creating Dockerfile..."
          puts
          create_step_files
          puts dockerfile
          f = File.open('Dockerfile', 'w')
          f.puts(dockerfile)
          f.close
          puts
          puts "building docker image..."
          puts `docker build --no-cache -t #{@repo_tag} . `
          #Docker::Image.build_from_dir('.')
          puts
          puts "image build complete"
        end
      end
    end
  end
end