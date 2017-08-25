require 'logger'

module Sneaql
  module Core
    #manages stored recordsets in sneaql transforms
    class RecordsetManager
      attr_reader :recordset

      def initialize(expression_manager, logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)
        @expression_manager = expression_manager
        @recordset = {}
      end

      # Stores a recordset if it is in a valid format.
      # @param [String] name name for recordset
      # @param [Array<Hash>] rs recordset to store
      def store_recordset(name, rs)
        raise Sneaql::RecordsetIsNotAnArray unless rs.class == Array
        raise Sneaql::RecordsetContainsInconsistentOrInvalidTypes unless recordset_valid?(rs)
        recordset[name] = rs
      end

      # Deletes a recordset if it exists
      # @param [String] name name for recordset to delete
      def remove_recordset(name)
        if @recordset.has_key?(name)
          @recordset.delete(name)
        end
      end
      
      # Validates recordset.  Must be an array of hashes with identical keys.
      # @param [Array<Hash>] rs recordset to validate
      def recordset_valid?(rs)
        return false unless rs.class == Array
        # empty recordset is valid
        return true if rs == []
        r1 = rs[0].keys

        rs.each do |record|
          return false unless record.class == Hash
          return false unless r1 == record.keys
          record.keys {|k| puts k; return false unless valid_element_data_types.include?(record[k].class)}
        end
        true
      end

      # Ruby data types that are valid as recordset fields.
      # @return [Array<Class>]
      def valid_element_data_types
        [Fixnum, String, Float]
      end

      # Validates that the string will make a valid recordset name.
      # @param [String] name
      # @return [Boolean]
      def valid_recordset_name?(name)
        return false unless name.match(/^\w+/)
        h = {}
        h[name] == 1
      rescue
        return false
      else
        return true
      end

      # Validates that the recordset name doesn't conflict with session var names
      # @param [String] name
      # @return [Boolean]
      def recordset_name_conflicts_with_variables?(name)
        @expression_manager.session_variables.key?(name)
      end

      # Parses a recordset expression.
      # @param [Array<Hash>] args
      # @return [Array<Hash>]
      def parse_recordset_expression(args)
        # takes in argument array as an argument
        # returns array of expressions to be checked at run time
        args.delete_at(0) # get rid of the first element, recordset ref
        args.each_slice(4).to_a.map{ |x| { condition: x[0].downcase, field: x[1], operator: x[2], expression: x[3]} }
      end

      # applies a conditional expression set against a record.
      # @param [Hash] record
      # @param [Array<Hash>] expressions
      # @return [Boolean]
      def evaluate_expression_against_record(record, expressions)
        conditions = []
        expressions.each do |exp|
          @logger.debug("applying #{exp} to #{record}")
          raw_result = @expression_manager.compare_expressions(
            exp[:operator],
            @expression_manager.evaluate_expression(record[exp[:field]]),
            @expression_manager.evaluate_expression(exp[:expression])
          )
          if exp[:condition] == 'include'
            conditions << raw_result
          elsif exp[:condition] == 'exclude'
            conditions << !raw_result
          end
        end
        return !conditions.include?(false)
      end
    end
  end
end