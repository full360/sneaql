require 'jdbc_helpers'

module Sneaql
  module Core
    # manages transform locking operations using a standardized
    # table for storing the locks.
    class TransformLockManager
      # set instance variables that will be used to manage the locks
      def initialize(params, logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)
        @transform_name = params[:transform_name]
        @transform_lock_id = params[:transform_lock_id]
        @transform_lock_table = params[:transform_lock_table]
        @jdbc_url = params[:jdbc_url]
        @db_user = params[:db_user]
        @db_pass = params[:db_pass]
        @database_manager = Sneaql::Core.find_class(
          :database,
          params[:database]
        ).new
      rescue => e
        @logger.error e.message
        e.backtrace.each { |b| @logger.error b}
      end

      # Creates a connection in the current JDBC context
      def create_jdbc_connection
        JDBCHelpers::ConnectionFactory.new(
          @jdbc_url,
          @db_user,
          @db_pass,
          @logger
        ).connection
      end

      # Checks to see if the current transform is locked
      # @return [Boolean]
      def acquire_lock
        # check to see if this transform is locked by
        # another transform returns true if locked
        jdbc_connection = create_jdbc_connection

        # initialize lock value
        lock_value = false

        if @database_manager.supports_transactions == true
          JDBCHelpers::Execute.new(
            jdbc_connection,
            @database_manager.begin_statement,
            @logger
          )
        end

        if @database_manager.supports_table_locking == true
          JDBCHelpers::Execute.new(
            jdbc_connection,
            @database_manager.lock_table_statement(@transform_lock_table),
            @logger
          )
        end

        # query the number of rows which match the condition...
        # should be 1 or 0... 1 indicating a lock
        r = JDBCHelpers::SingleValueFromQuery.new(
          jdbc_connection,
          %(select
            count(*)
          from
            #{@transform_lock_table}
          where
            transform_name='#{@transform_name}'
            and
            transform_lock_id!=#{@transform_lock_id};),
            @logger
        ).result

        # table is unlocked
        if r == 0
          l = JDBCHelpers::Execute.new(
            jdbc_connection,
            %{insert into #{@transform_lock_table}
              (
                transform_lock_id,
                transform_name,
                transform_lock_time
              )
              values
              (
                #{@transform_lock_id},
                '#{@transform_name}',
                current_timestamp
              );},
              @logger
          )

          if @database_manager.supports_transactions == true
            JDBCHelpers::Execute.new(
              jdbc_connection,
              @database_manager.commit_statement,
              @logger
            )
          end

          lock_value = true
        else
          if @database_manager.supports_transactions == true
            JDBCHelpers::Execute.new(
              jdbc_connection,
              @database_manager.rollback_statement,
              @logger
            )
          end
          lock_value = false
        end

        if lock_value == true
          @logger.info("#{@transform_name} transform lock acquired;")
        else
          @logger.info("#{@transform_name} is locked by another process")
        end
      ensure
        # close this connection
        jdbc_connection.close

        lock_value
      end

      # Removes transform lock if it's present.
      def remove_lock
        # get a fresh jdbc connection...
        # to avoid committing the main transform unnecessarily
        jdbc_connection = create_jdbc_connection

        if @database_manager.supports_transactions == true
          JDBCHelpers::Execute.new(
            jdbc_connection,
            @database_manager.begin_statement,
            @logger
          )
        end

        if @database_manager.supports_table_locking == true
          JDBCHelpers::Execute.new(
            jdbc_connection,
            @database_manager.lock_table_statement(@transform_lock_table),
            @logger
          )
        end

        # delete the lock record and commit
        JDBCHelpers::Execute.new(
          jdbc_connection,
          %(delete from #{@transform_lock_table}
          where transform_name='#{@transform_name}'
          and transform_lock_id=#{@transform_lock_id};),
          @logger
        )

        c = JDBCHelpers::Execute.new(
          jdbc_connection,
          @database_manager.commit_statement,
          @logger
        )
      ensure
        jdbc_connection.close

        return true
      end

      # TBD
      def lock_all_available_transforms
        # undefined at this time
      end
    end
  end
end
