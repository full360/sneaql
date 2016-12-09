module Sneaql
  # Classes to manage DB objects for standard SneaQL deployment.
  module Standard
    # Facilitate creation/recreation of database table objects
    # for standard SneaQL deployment.
    class DBObjectCreator
      attr_accessor :jdbc_connection

      # @param [Object] jdbc_connection
      # @param [Sneaql::Core::DatabaseManager] database_manager
      # @param [Logger] logger
      def initialize(jdbc_connection, database_manager, logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)
        @jdbc_connection = jdbc_connection
        @database_manager = database_manager
      end

      # Drops and recreates the primary transform table.
      # @param [String] transform_table_name fully qualified name for this table
      # @return [Boolean]
      def recreate_transforms_table(transform_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          "drop table if exists #{ transform_table_name };",
          @logger
        )
        create_transforms_table(transform_table_name)
        return true
      end

      # Creates the primary transform table.
      # @param [String] transform_table_name fully qualified name for this table
      # @return [Boolean]
      def create_transforms_table(transform_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          transforms_table_create_statement(transform_table_name),
          @logger
        )
        return true
      end
      
      # Coerces a boolean to the appropriate value for the database type.
      # May return a 0 or 1 in RDBMS where boolean is not supported.
      # @param [Boolean] boolean_value
      # @return [Boolean, Fixnum]
      def coerce_boolean(boolean_value)
        if @database_manager.has_boolean 
          boolean_value 
        else 
          boolean_value == true ? 1 : 0 
        end
      end
      
      # Create table statement for primary transform table.
      # @param [String] transform_table_name fully qualified name for this table
      # @return [String]
      def transforms_table_create_statement(transform_table_name)
        %{create table if not exists #{ transform_table_name }
          (
          	transform_name varchar(255) not null
          	,sql_repository varchar(255)
          	,sql_repository_branch varchar(255)
          	,sql_s3_endpoint varchar(255)
          	,is_active #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }

          	,notify_on_success #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }
          	,notify_on_non_precondition_failure #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }
          	,notify_on_precondition_failure #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }

          	,updated_ts timestamp
          );}
      end
      
      # Creates a record in the transforms table.
      # @param [String] transform_table_name
      # @param [Hash] params Hash of parameters with symbols matching column names
      def create_transform(transform_table_name, params)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          create_transform_statement(transform_table_name, params),
          @logger
        )
      end

      # @param [String] transform_table_name
      # @param [Hash] params Hash of parameters with symbols matching column names
      def create_transform_statement(transform_table_name, params)
        %{insert into #{transform_table_name}
          (
            transform_name
            ,repository_type
            ,sql_repository
            ,sql_repository_branch
            ,s3_endpoint
            ,is_active
            ,notify_on_success
            ,notify_on_non_precondition_failure
            ,notify_on_precondition_failure
            ,updated_ts
          )
          values
          (
            '#{params[:transform_name]}'
            ,#{params[:repository_type]}'
            ,'#{params[:sql_repository]}'
            ,'#{params[:sql_repository_branch]}'
            ,'#{params[:sql_s3_endpoint]}'
            ,#{coerce_boolean(params[:notify_on_success])}
            ,#{coerce_boolean(params[:notify_on_non_precondition_failure])}
            ,#{coerce_boolean(params[:notify_on_precondition_failure])}
            ,current_timestamp
          );}
      end
      
      # Drops and recreates the transform steps table.
      # @param [String] transform_steps_table_name fully qualified name for this table
      # @return [Boolean]
      def recreate_transform_steps_table(transform_steps_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          "drop table if exists #{ transform_steps_table_name };",
          @logger
        )
        create_transform_steps_table(transform_steps_table_name)
        return true
      end

      # Creates the transform steps table.
      # @param [String] transform_steps_table_name fully qualified name for this table
      # @return [Boolean]
      def create_transform_steps_table(transform_steps_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          transform_steps_table_create_statement(transform_steps_table_name),
          @logger
        )
        return true
      end

      # Create table statement for transform steps table.
      # @param [String] transform_steps_table_name fully qualified name for this table
      # @return [String]
      def transform_steps_table_create_statement(transform_steps_table_name)
        %{create table if not exists #{ transform_steps_table_name }
          (
          	transform_name varchar(255) not null
          	,transform_step integer not null
          	,sql_file_path_in_repo varchar(1024)
          	,is_active #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }
          	,is_precondition #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }
          	,updated_ts timestamp
          );}
      end

      # Drops and recreates the transform lock table.
      # @param [String] transform_lock_table_name fully qualified name for this table
      # @return [Boolean]
      def recreate_transform_lock_table(transform_lock_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          "drop table if exists #{ transform_lock_table_name };",
          @logger
        )
        create_transform_lock_table(transform_lock_table_name)
        return true
      end

      # Creates the transform lock table.
      # @param [String] transform_lock_table_name fully qualified name for this table
      # @return [Boolean]
      def create_transform_lock_table(transform_lock_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          transform_lock_table_create_statement(transform_lock_table_name),
          @logger
        )
        return true
      end

      # Create table statement for transform lock table.
      # @param [String] transform_lock_table_name fully qualified name for this table
      # @return [String]
      def transform_lock_table_create_statement(transform_lock_table_name)
        %{create table if not exists #{ transform_lock_table_name }
          (
          	transform_lock_id bigint
          	,transform_name varchar(255)
          	,transform_lock_time timestamp
          );}
      end

      # Drops and recreates the transform log table.
      # @param [String] transform_log_table_name fully qualified name for this table
      # @return [Boolean]
      def recreate_transform_log_table(transform_log_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          "drop table if exists #{ transform_log_table_name };",
          @logger
        )
        create_transform_log_table(transform_log_table_name)
        return true
      end

      # Creates the transform log table.
      # @param [String] transform_log_table_name fully qualified name for this table
      # @return [Boolean]
      def create_transform_log_table(transform_log_table_name)
        JDBCHelpers::Execute.new(
          @jdbc_connection,
          transform_log_table_create_statement(transform_log_table_name),
          @logger
        )
        return true
      end

      # Create table statement for transform log table.
      # @param [String] transform_log_table_name fully qualified name for this table
      # @return [String]
      def transform_log_table_create_statement(transform_log_table_name)
        %{create table if not exists #{ transform_log_table_name }
          (
          	transform_run_id bigint
          	,transform_lock_id bigint
          	,transform_name varchar(255)
          	,transform_step integer
          	,transform_statement integer
          	,all_steps_complete #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }
          	,failed_in_precondition #{ if @database_manager.has_boolean then 'boolean' else 'smallint' end }
          	,message varchar(65000)
          	,transform_start_time timestamp
          	,transform_end_time timestamp
          );}
      end
    end
  end
end