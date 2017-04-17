require 'zip/zip'
require 'fileutils'
require 'logger'

#top level namespace for sneaql objects
module Sneaql
  # contains the base classes for the extendable parts of sneaql:
  #   commands (the actual commands specified in sneaql tags)
  #   repo_managers (used to pull the sql files from a remote or local source)
  #   metadata managers (to get information about each step)
  # in addition to the base classes, the mapped class/class_map
  # utilities are used to provide a dynamic class system
  # this class system allows you to register a class under a type
  # you can later look up the class by type and a text identifier
  # then instantiate a new instance from there
  module Core
    # global map of all classes
    @@class_map = {}

    # allows external access to class_map for testing purposes
    def self.class_map
      @@class_map
    end

    # adds a new class to the map
    # @param [Symbol] type class type (user settable, can be :command, :repo_manager, etc)
    # @param [Hash] mapped_class_hash in the format { text: text, mapped_class: mapped_class }
    def self.add_mapped_class(type, mapped_class_hash)
      @@class_map[type] == [] unless @@class_map.keys.include?(type)
      @@class_map[type] << mapped_class_hash
    end

    # makes sure that the type exists before appending the class information
    # @param [Symbol] type class type (user settable, can be :command, :repo_manager, etc)
    def self.insure_type_exists(type)
      @@class_map[type] = [] unless @@class_map.key?(type)
    end

    # returns the class referenced by the type/text combination
    # @param [Symbol] type class type (user settable, can be :command, :repo_manager, etc)
    # @param [String] text to when searching within this type
    # @return [Class] returns the class you are searching for
    def self.find_class(type, text)
      @@class_map[type].each do |t|
        return t[:mapped_class] if t[:text] == text
      end
    end

    # Handles registration of a class to the class_map
    # Ignores duplicate definitions if they occur
    class RegisterMappedClass
      # Registers the class into the class_map.
      # @param [Symbol] type class type (user settable, can be :command, :repo_manager, etc)
      # @param [String] text to when searching within this type
      # @param [Class] mapped_class class to be returned when search matches type and text
      def initialize(type, text, mapped_class)
        Sneaql::Core.insure_type_exists(type)
        # check to see if the reference text is already being used by this type
        unless Sneaql::Core.class_map[type].map { |c| c[:text] }.include?(text)
          Sneaql::Core.add_mapped_class(
            type,
            { text: text, mapped_class: mapped_class }
          )
        end
      end
    end

    # Base class for SneaQL command tags
    class SneaqlCommand
      # this is the base object for a sneaql command
      # subclass this and override the action method
      # @param [Object] jdbc_connection JDBC connection object to database
      # @param [Sneaql::Core::ExpressionHandler] expression_handler
      # @param [Sneaql::Core::RecordsetManager] recordset_manager
      # @param [String] statement SQL statement provided in body, with all variables resolved
      # @param [Logger] logger object otherwise will default to new Logger
      def initialize(jdbc_connection, expression_handler, recordset_manager, statement, logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)

        @jdbc_connection = jdbc_connection
        @expression_handler = expression_handler
        @statement = statement
        @recordset_manager = recordset_manager
      end

      # override this method with the actual code for your command
      def action
        nil
      end

      # override with an array in the form [:expression, :operator]
      def arg_definition
        []
      end

      # override this if you have a complex tag structure
      # @param [Array] args argument array to validate
      # @return [Boolean] true if all arguments are valid
      def validate_args(args)
        return false if args.length != arg_definition.length
        return true if (arg_definition == []) and (args == [])
        valid = []
        args.each_with_index do |a, i|
          case
          when arg_definition[i] == :variable then
            valid << valid_variable?(a)
          when arg_definition[i] == :expression then
            valid << valid_expression?(a)
          when arg_definition[i] == :operator then
            valid << valid_operator?(a)
          when arg_definition[i] == :recordset then
            valid << valid_recordset?(a)
          else valid << false end
        end
        @logger.debug("arg validation results: #{valid}")
        !valid.include?(false)
      end

      # validates that the value is a valid variable name
      # @param [String] a value to test
      # @return [Boolean]
      def valid_variable?(a)
        @expression_handler.valid_session_variable_name?(a.to_s.strip)
      end

      # validates that the value is a valid expression
      # @param [String, Float, Fixnum] a value to test
      # @return [Boolean]
      def valid_expression?(a)
        @expression_handler.valid_expression_reference?(a.to_s.strip)
      end

      # validates that the value is a valid operator
      # @param [String] a value to test
      # @return [Boolean]
      def valid_operator?(a)
        @expression_handler.valid_operators.include?(a.to_s.strip)
      end

      # validates that the value is a valid recordset name
      # @param [String] a value to test
      # @return [Boolean]
      def valid_recordset?(a)
        @recordset_manager.valid_recordset_name?(a.to_s.strip)
      end

      private

      # these are set during initialize
      # reference to jdbc connection object
      attr_accessor :jdbc_connection

      # reference to expression handler object for this transform
      attr_accessor :expression_handler

      # actual sql statement with all variables dereferenced
      attr_accessor :statement
    end # class

    # base class for repo managers
    class RepoDownloadManager
      # this is the directory that the repo operates in
      attr_reader :repo_base_dir

      # @param [Hash] params parameters passed to transform will be passed here
      # @param [Logger] logger object otherwise will default to new Logger
      def initialize(params, logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)

        @repo_base_dir = "#{params[:repo_base_dir]}/#{params[:transform_name]}"
        @params = params

        # perform the actual actions of managing the repo
        manage_repo
      end

      # method to drop and rebuild the specified directory
      # all files and subdirectories will be destroyed
      # @param [String] directory
      def drop_and_rebuild_directory(directory)
        @logger.info("dropping and recreating repo directory #{directory}")
        FileUtils.remove_dir(directory) if Dir.exist?(directory)
        FileUtils.mkdir_p(directory)
      end

      # override in your implementation
      def manage_repo
        nil
      end

      # copied this from the internet
      # http://www.markhneedham.com/blog/2008/10/02/ruby-unzipping-a-file-using-rubyzip/
      def unzip_file(file, destination)
        ::Zip::ZipFile.open(file) do |zip_file|
          zip_file.each do |f|
            f_path = File.join(destination, f.name)
            FileUtils.mkdir_p(File.dirname(f_path))
            zip_file.extract(f, f_path) unless File.exist?(f_path)
          end
        end
      end
    end

    # abstracted to allow this metadata to come from any source
    class StepMetadataManager
      # value should be array of metadata hashes in the form `{ step_number: j['step_number'], step_file: j['step_file'] }`
      attr_reader :steps

      # @param [Hash] params parameters passed to transform will be passed here
      # @param [Logger] logger object otherwise will default to new Logger
      def initialize(params, logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)
        @params = params
        manage_steps
      end

      # override with a method that will override steps with an array of
      # steps in the format :step_number, :step_file
      def manage_steps
        nil
      end
    end
  end
end
