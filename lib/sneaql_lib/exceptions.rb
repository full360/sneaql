module Sneaql
  # Exceptions for SneaQL
  module Exceptions
    class ExceptionManager
      attr_accessor :pending_error
      attr_accessor :last_iterated_record
      
      def initialize(logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)
      end
      
      def output_pending_error
        @logger.error "pending error: #{@pending_error}" if @pending_error
      end
    end
     
    # Base error class for Sneaql
    class BaseError < StandardError; end

    # Exception used to to gracefully exit test
    class UnhandledException < BaseError
      def initialize(msg = 'Previous error was not handled.')
        super
      end
    end
    
    # Exception used to to gracefully exit test
    class SQLTestExitCondition < BaseError
      def initialize(msg = 'Exit condition met by test, this is not an error')
        super
      end
    end

    # Exception used to gracefully exit test step
    class SQLTestStepExitCondition < BaseError
      def initialize(msg = 'Exit condition for this step has been met, this is not an error')
        super
      end
    end

    # Transform is locked by another process.  This is a
    # possibility when using the LockManager
    class TransformIsLocked < BaseError
      def initialize(msg = 'This transform is locked by another process')
        super
      end
    end

    # Recordset check failure indicator
    class RecordsetContainsInconsistentOrInvalidTypes < BaseError
      def initialize(msg = 'Recordsets must have identical keys in every record')
        super
      end
    end

    # Recordset check failure indicator
    class RecordsetIsNotAnArray < BaseError
      def initialize(msg = 'Recordset must be an array of hashes with identical keys')
        super
      end
    end

    # General error evaluating expression.
    class ExpressionEvaluationError < BaseError
      def initialize(msg = 'Error evaluating expression')
        super
      end
    end

    # Comparison operator must be explicitly supported.
    class InvalidComparisonOperator < BaseError
      def initialize(msg = 'Invalid or no comparison operator provided')
        super
      end
    end

    # Error raised during parser validation process
    class StatementParsingError < BaseError
      def initialize(msg = 'General error parsing Sneaql tag and statement')
        super
      end
    end

    # Sneaql step files must not be empty
    class NoStatementsFoundInFile < BaseError
      def initialize(msg = 'No statements found in step file.')
        super
      end
    end

    # Sneaql command tags must be formed correctly
    class MalformedSneaqlCommandsInStep < BaseError
      def initialize(msg = 'Sneaql command tag is malformed.')
        super
      end
    end
  end
end
