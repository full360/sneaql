require 'jdbc_helpers'
require_relative 'base.rb'
require_relative 'exceptions.rb'

module Sneaql
  module Core
    # Core Sneaql language command tags.
    # You can create your own tags by extending 
    # Sneaql::Core::SneaqlCommand and overriding the
    # action method.  You should also override arg_definition
    # and potentially validate_args if have a complex argument
    # structure.
    module Commands
      # assigns a session variable to a provided value
      class SneaqlAssign < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'assign',
          Sneaql::Core::Commands::SneaqlAssign
        )

        # @param [String] var_name
        # @param [String] value expression (must be a string)
        def action(var_name, value)
          @expression_handler.set_session_variable(var_name, value)
        end

        # argument types
        def arg_definition
          [:variable, :expression]
        end
      end

      # assigns a session variable to a value returned from a sql query
      class SneaqlAssignResult < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'assign_result',
          Sneaql::Core::Commands::SneaqlAssignResult
        )

        # run the query... then assign the result to a session variable
        # @param [String] target_var_name
        def action(target_var_name)
          @expression_handler.set_session_variable(
            target_var_name,
            sql_result
          )
        end

        # argument types
        def arg_definition
          [:variable]
        end

        # returns value at first row/field in result set
        def sql_result
          JDBCHelpers::SingleValueFromQuery.new(
            @jdbc_connection,
            @statement,
            @logger
          ).result
        end
      end

      # executes a sql statement
      class SneaqlExecute < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'execute',
          Sneaql::Core::Commands::SneaqlExecute
        )

        # execute sql statement
        # last_statement_rows_affected is always set...
        def action
          @expression_handler.set_session_variable(
            'last_statement_rows_affected',
            rows_affected
          )
        end

        # @return [Fixnum] rows affected by SQL statement
        def rows_affected
          JDBCHelpers::Execute.new(
            @jdbc_connection,
            @statement,
            @logger
          ).rows_affected
        end
      end

      # executes a sql statement if the condition evaluates to true
      class SneaqlExecuteIf < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'execute_if',
          Sneaql::Core::Commands::SneaqlExecuteIf
        )

        # @param [String] left_value expression as left operand
        # @param [String] operator comparison operator supported by expression handler
        # @param [String] right_value expression as right operand
        def action(left_value, operator, right_value)
          if @expression_handler.compare_expressions(operator, left_value, right_value)
            @expression_handler.set_session_variable(
              'last_statement_rows_affected',
              rows_affected
            )
          end
        end

        # argument types
        def arg_definition
          [:expression, :operator, :expression]
        end

        # @return [Fixnum] rows affected by SQL statement
        def rows_affected
          JDBCHelpers::Execute.new(
            @jdbc_connection,
            @statement,
            @logger
          ).rows_affected
        end
      end

      # compares the result of a sql statement against an argument
      # raises error if the comparison does not evaluate to true
      # the first field of the first record is used for the comparison
      class SneaqlTest < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'test',
          Sneaql::Core::Commands::SneaqlTest
        )

        # @param [String] operator comparison operator supported by expression handler
        # @param [String] value_to_test expression as right operand
        def action(operator, value_to_test)
          unless @expression_handler.compare_expressions(
            operator,
            sql_result,
            value_to_test
          )
            raise Sneaql::Exceptions::SQLTestExitCondition
          end
        end

        # argument types
        def arg_definition
          [:operator, :expression]
        end

        # returns value at first row/field in result set
        def sql_result
          JDBCHelpers::SingleValueFromQuery.new(
            @jdbc_connection,
            @statement,
            @logger
          ).result
        end
      end

      # raises an error to exit the transform if the condition evaluates to true
      class SneaqlExitIf < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'exit_if',
          Sneaql::Core::Commands::SneaqlExitIf
        )

        # @param [String] operand1 expression as left operand
        # @param [String] operator comparison operator supported by expression handler
        # @param [String] operand2 expression as right operand
        def action(operand1, operator, operand2)
          if @expression_handler.compare_expressions(operator, operand1, operand2)
            raise Sneaql::Exceptions::SQLTestExitCondition
          end
        end

        # argument types
        def arg_definition
          [:expression, :operator, :expression]
        end
      end

      # raises an error to exit the transform step if the comdition evaluates to true
      # note that this error needs to be handled accordingly in the calling
      # procedure as all other errors will end the transform
      class SneaqlExitStepIf < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'exit_step_if',
          Sneaql::Core::Commands::SneaqlExitStepIf
        )

        # @param [String] operand1 expression as left operand
        # @param [String] operator comparison operator supported by expression handler
        # @param [String] operand2 expression as right operand
        def action(operand1, operator, operand2)
          if @expression_handler.compare_expressions(operator, operand1, operand2)
            raise Sneaql::Exceptions::SQLTestStepExitCondition
          end
        end

        # argument types
        def arg_definition
          [:expression, :operator, :expression]
        end
      end

      # runs the query then stores the array of hashes into the recordset hash
      class SneaqlRecordsetFromQuery < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'recordset',
          Sneaql::Core::Commands::SneaqlRecordsetFromQuery
        )

        # @param [String] recordset_name name of the recordset in which to store the results
        def action(recordset_name)
          r = query_results
          @logger.debug "adding #{r.length} recs as #{recordset_name}"
          @recordset_manager.store_recordset(recordset_name, r)
        end

        # argument types
        def arg_definition
          [:recordset]
        end

        # @return [Array] returns array of hashes from SQL results
        def query_results
          JDBCHelpers::QueryResultsToArray.new(
            @jdbc_connection,
            @statement,
            @logger
          ).results
        end
      end

      # iterates a recordset and runs the sql statement for each record
      class SneaqlIterateRecordset < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'iterate',
          Sneaql::Core::Commands::SneaqlIterateRecordset
        )

        # @param [*Array] args parameters for recordset expression in the format
        def action(*args)
          if args.size == 1
            iterate_all_records(*args)
          elsif ((args.size - 1) % 4) == 0
            iterate_records_conditionally(*args)
          end
        end

        # custom method for argument validation
        # @param [Array] args
        # @return [Boolean]
        def validate_args(args)
          if args.size == 1
            return valid_recordset?(args[0])
          elsif ((args.size - 1) % 4) == 0
            valid = []
            valid << valid_recordset?(args[0])
            args[1..args.length - 1].each_slice(4) do |s|
              if ['include', 'exclude'].include?(s[0])
                valid << true
              else
                valid << false
              end
              # field names have the same rules as recordset names for now
              valid << valid_recordset?(s[1])
              valid << valid_operator?(s[2])
              valid << valid_expression?(s[3])
            end
            !valid.include?(false)
          else
            return false
          end
        end

        # @param [String] recordset recordset to iterate
        def iterate_all_records(recordset)
          @logger.info "iterating recordset #{recordset}..."
          @recordset_manager.recordset[recordset].each_with_index do |i, n|
            @logger.debug("#{n + 1} of #{recordset}: #{i}")
            tmp = @statement
            i.keys.each { |k| tmp = tmp.gsub(":#{recordset}.#{k}", i[k].to_s) }
            @expression_handler.set_session_variable(
              'last_statement_rows_affected',
              rows_affected_current_statement(tmp)
            )
          end
        end

        # @param [*Array] args all the arguments passed to the calling function
        def iterate_records_conditionally(*args)
          recordset = args.to_a[0]
          @logger.info "iterating recordset #{recordset}..."
          conditions = @recordset_manager.parse_recordset_expression(args.to_a)
          @recordset_manager.recordset[recordset].each_with_index do |i, n|
            @logger.debug("#{n + 1} of #{recordset}: #{i}")
            next unless @recordset_manager.evaluate_expression_against_record(i, conditions)
            tmp = @statement
            i.keys.each { |k| tmp = tmp.gsub(":#{recordset}.#{k}", i[k].to_s) }
            @expression_handler.set_session_variable(
              'last_statement_rows_affected',
              rows_affected_current_statement(tmp)
            )
          end
        end

        # @return [Fixnum] rows affected by the SQL statement
        def rows_affected_current_statement(stmt)
          JDBCHelpers::Execute.new(
            @jdbc_connection,
            stmt,
            @logger
          ).rows_affected
        end
      end

      # stores all the file paths matching the dir glob into a recordset
      class SneaqlRecordsetFromDirGlob < Sneaql::Core::SneaqlCommand
        Sneaql::Core::RegisterMappedClass.new(
          :command,
          'rs_from_local_dir',
          Sneaql::Core::Commands::SneaqlRecordsetFromDirGlob
        )

        # @param [String] recordset_name
        # @param [String] dirglob directory glob with optional wildcards
        def action(recordset_name, dirglob)
          r = Dir.glob(dirglob)
          r.map! { |d| { 'path_name' => d.to_s } }
          @logger.debug "adding #{r.length} recs as #{recordset_name}"
          @recordset_manager.store_recordset(recordset_name, r)
        end
      end
    end
  end
end
