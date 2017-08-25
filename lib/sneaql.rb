require 'jdbc_helpers'
require 'logger'

require_relative 'sneaql_lib/exceptions.rb'
require_relative 'sneaql_lib/core.rb'
require_relative 'sneaql_lib/repo_manager.rb'
require_relative 'sneaql_lib/step_manager.rb'
require_relative 'sneaql_lib/parser.rb'
require_relative 'sneaql_lib/expressions.rb'
require_relative 'sneaql_lib/recordset.rb'
require_relative 'sneaql_lib/docker.rb'
require_relative 'sneaql_lib/tokenizer.rb'

# module for sneaql
module Sneaql
  # Manages and executes a SneaQL transform.
  class Transform
    attr_reader :current_step
    attr_reader :current_statement
    attr_reader :start_time
    attr_reader :end_time
    attr_reader :exit_code
    attr_reader :transform_error
    attr_reader :status

    # Valid transform statuses
    # :initializing, :connecting_to_database, :running, :completed, :error
    # @return [Array] array of valid transform statuses
    def valid_statuses
      [:initializing, :connecting_to_database, :running, :completed, :error, :validating, :validated]
    end

    # Sets the current status of the transform.
    # Must be a valid status type or it will not be set.
    # Override this if you want to implement a custom status communication to
    # an external target.
    # @param [Symbol] status
    # @see valid_status
    def current_status(status)
      @status = status if valid_statuses.include?(status)
    end

    # Creates a SneaQL transform object.
    # @example
    #   t=Sneaql::Transform.new({
    #     transform_name: 'test-transform',
    #     repo_base_dir: "test/fixtures/test-transform",
    #     repo_type: 'local',
    #     jdbc_url: 'jdbc:sqlite:memory',
    #     db_user: 'dbuser',
    #     db_pass: 'password',
    #     step_metadata_manager_type: 'local_file',
    #     step_metadata_file_path: "test/fixtures/test-transform/steps.json"
    #   }, logger)
    #
    #   t.run
    # @param [Hash] params various parameters are passed to define the transform
    # @param [Logger] logger customer logger if provided (otherwise default logger is created)
    def initialize(params, logger = nil)
      # initialzing and basic parameter stuff
      @logger = logger ? logger : Logger.new(STDOUT)
      @start_time = Time.new.utc
      current_status(:initializing)
      @params = params
      @exit_code = 0
      @transform_name = @params[:transform_name]
      @jdbc_url = @params[:jdbc_url]
      @db_user = @params[:db_user]
      @db_pass = @params[:db_pass]
      
      # build fancy objects for processing the transform
      @expression_handler = create_expression_handler
      @recordset_manager = create_recordset_manager
      @exception_manager = create_exception_manager
      @repo_manager = create_repo_manager
      @steps = create_metadata_manager
      @parsed_steps = create_parsed_steps(@steps)
      
      run if @params[:run] == true
    end

    # validate the transform.
    def validate
      current_status(:validating)
      validate_parsed_steps(@parsed_steps)
    rescue Sneaql::Exceptions::TransformIsLocked => e
      @transform_error = e
      @logger.info(e.message)
    rescue Sneaql::Exceptions::SQLTestExitCondition => e
      @transform_error = nil
      @logger.info(e.message)
    rescue => e
      @exit_code = 1
      @transform_error = e
      current_status(:error)
      @logger.error(e.message)
      e.backtrace { |b| @logger.error b }
    ensure
      @end_time = Time.new.utc

      if @transform_error.nil?
        current_status(:validated)
      else
        current_status(:error)
      end

      @logger.info("#{@transform_name} validation time #{@end_time - @start_time}s")
      @logger.info("#{@transform_name} exit code: #{@exit_code} status: #{@status}")
    end

    # Runs the actual transform.
    def run
      current_status(:validating)
      validate_parsed_steps(@parsed_steps)
      current_status(:connecting_to_database)
      @jdbc_connection = create_jdbc_connection
      current_status(:running)
      iterate_steps_and_statements
    rescue Sneaql::Exceptions::SQLTestExitCondition => e
      @transform_error = nil
      @logger.info(e.message)
    rescue => e
      @exit_code = 1
      @transform_error = e
      current_status(:error)
      @logger.error(e.message)
      e.backtrace { |b| @logger.error b }
    ensure
      @jdbc_connection.close if @jdbc_connection
      @end_time = Time.new.utc

      if @transform_error.nil?
        current_status(:completed)
      else
        current_status(:error)
      end

      @logger.info("#{@transform_name} runtime #{@end_time - @start_time}s")
      @logger.info("#{@transform_name} exit code: #{@exit_code} status: #{@status}")
    end

    # Creates an ExpressionHandler object
    # @return [Sneaql::Core::ExpressionHandler]
    def create_expression_handler
      Sneaql::Core::ExpressionHandler.new(@logger)
    end

    # Creates ExceptionHandler object
    def create_exception_manager
      Sneaql::Exceptions::ExceptionManager.new(@logger)
    end

    # Creates a RepoDownloadManager object
    # The actual object returns depends upon params[:repo_type] provided at initialize.
    # @return [Sneaql::Core::RepoDownloadManager]
    def create_repo_manager
      Sneaql::Core.find_class(:repo_manager, @params[:repo_type]).new(@params, @logger)
    end

    # Creates a StepMetadataManager object
    # The actual object returns depends upon params[:step_metadata_manager_type] provided at initialize.
    # @return [Sneaql::Core::StepMetadataManager]
    def create_metadata_manager
      Sneaql::Core.find_class(
        :step_metadata_manager,
        @params[:step_metadata_manager_type]
      ).new(@params, @logger).steps
    end

    # Creates a StepParser object for each step file defined by the metadata manager.
    # @param [Array] steps takes an array of step definitions
    # @return [Array] of Sneaql::Core::StepParser
    def create_parsed_steps(steps)
      steps.map do |s|
        {
          parser: Sneaql::Core::StepParser.new(
            "#{@repo_manager.repo_base_dir}/#{s[:step_file]}",
            @expression_handler,
            @recordset_manager,
            @logger
          ),
          step_number: s[:step_number]
        }
      end
    end

    # Validates the arguments for all tags.
    # @param [Array<Sneaql::Core::StepParser>] steps
    def validate_parsed_steps(steps)
      steps.each do |s|
        raise Sneaql::Exceptions::StatementParsingError unless s[:parser].valid_arguments_in_all_statements?
      end
    end

    # Creates an RecordsetManager object
    # @return [Sneaql::Core::RecordsetManager]
    def create_recordset_manager
      Sneaql::Core::RecordsetManager.new(@expression_handler, @logger)
    end

    # Creates a JDBC connection
    # JDBC drivers must loaded into jruby before this will work.
    def create_jdbc_connection
      # db specific driver should have been handled by the calling procedure
      current_status(:connecting_to_database)
      JDBCHelpers::ConnectionFactory.new(
        @jdbc_url,
        @db_user,
        @db_pass,
        @logger
      ).connection
    end

    # Performs the actual work of running the transform steps.
    # This method operates within the context of a single
    # database session across all steps.  If it fails, it will
    # not rollback automatically unless that is the default RDBMS
    # behavior for a connection that closes before a commit.
    def iterate_steps_and_statements
      @parsed_steps.each_with_index do |this_step, i|
        # raise any lingering errors not handled in previous step
        raise @exception_manager.pending_error if @exception_manager.pending_error != nil
        # set this so that other processes can poll the state
        @current_step = this_step[:step_number]
        # within a step... iterate through each statement
        this_step[:parser].statements.each_with_index do |this_stmt, stmt_index|
          # set this so that other processes can poll the state
          @current_statement = stmt_index + 1
          
          # log the pending error
          @exception_manager.output_pending_error
          
          # log some useful info
          @logger.info("step: #{@current_step} statement: #{@current_statement}")
          @expression_handler.output_all_session_variables

          # get the command hash for the current statement
          this_cmd = this_step[:parser].command_at_index(stmt_index)
          @logger.debug(this_cmd)

          # evaluate any variable references in the arguments
          if this_cmd[:arguments]
            this_cmd[:arguments].map! { |a| @expression_handler.evaluate_expression(a) }
          end

          begin
            # find the class assciated with this command
            k = Sneaql::Core.find_class(:command, this_cmd[:command])
            
            # if there is an error... check to see if this is the error handler
            if @exception_manager.pending_error != nil
              unless k == Sneaql::Core::Commands::SneaqlOnError
                raise @exception_manager.pending_error
              end
            end
            
            # instantiate a new instance of the command class
            # and call it's action method with arguments
            c = k.new(
              @jdbc_connection,
              @expression_handler,
              @exception_manager,
              @recordset_manager,
              @expression_handler.evaluate_all_expressions(this_stmt),
              @logger
            )
            
            # performs the work of the current command
            c.action(*this_cmd[:arguments])

            # check if there was an error from the action
            if @exception_manager.pending_error != nil
              # if there was an error... check to see if this is the last stmt in step
              if stmt_index == (this_step[:parser].statements.length - 1)
                # last step... so we know there is no error handler in this step
                # therefore we should propagate the error
                raise @exception_manager.pending_error
              end
            end

          rescue Sneaql::Exceptions::SQLTestStepExitCondition => e
            @logger.info e.message
            break
          end
        end
      end
    rescue => e
      @logger.error(e.message)
      e.backtrace.each { |r| @logger.error(r) }
    end
  end
end
