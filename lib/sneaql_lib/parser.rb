require_relative 'tokenizer.rb'

module Sneaql
  module Core
    # Parses a step file into discrete statements.
    # Also performs validation of all Sneaql tags.
    class StepParser
      # array of raw statement text
      attr_reader :statements
      attr_reader :expression_handler

      # @param [String] file_path pathname to step file
      # @param [Sneaql::ExpressionHandler] expression_handler
      # @param [Sneaql::RecordsetManager] recordset_manager
      # @param [Logger] logger optional, if omitted default logger will be used
      def initialize(file_path, expression_handler, recordset_manager, logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)
        @expression_handler = expression_handler
        @recordset_manager = recordset_manager

        # parse the statements from the file and store them in an array
        # this is a simple text parsing based upon the /*- delimiter
        @statements = parse_statements_from_file(file_path)

        raise Sneaql::Exceptions::NoStatementsFoundInFile if @statements == []
      end

      # Performs the actual parsing from file
      # @param [String] file_path
      def parse_statements_from_file(file_path)
        @logger.info("parsing statements from step file #{file_path}")
        stmt = []
        File.read(file_path).split('/*-').each { |s| stmt << "/*-#{s.strip}" }
        # delete the first element because of the way it splits
        stmt.delete_at(0)
        @logger.info("#{stmt.length} statements found")
        stmt
      rescue => e
        @logger.error("file parsing error :#{e.message}")
        e.backtrace.each { |b| @logger.error b.to_s }
        raise Sneaql::Exceptions::StatementParsingError
      end

      # Extracts array of tokens from tag
      # @param [String] statement_text_with_command
      # @return [Array]
      def tag_splitter(statement_text_with_command)
        # updated to use tokenizer
        # splits out all the tag elements into an array
        # statement_text_with_command.split('-*/')[0].gsub('/*-', '').strip.split
        command = statement_text_with_command.split('-*/')[0].gsub('/*-', '').strip
        t = Sneaql::Core::Tokenizer.new
        t.tokenize(command)
      end

      # Returns command tag from statement at specified index.  Allows for
      # @param [Fixnum] indx index of statement in statements array
      # @return [Hash]
      def command_at_index(indx)
        parsed_tag = tag_splitter(@statements[indx])
        { command: parsed_tag[0], arguments: parsed_tag[1..parsed_tag.length - 1] }
      end

      # Validates the Sneaql command tag and arguments
      # @return [Boolean]
      def valid_arguments_in_all_statements?
        all_statements_valid = true
        @statements.each_with_index do |_s, i|
          cmd = command_at_index(i)
          @logger.debug("validating #{cmd}")
          unless statement_args_are_valid?(cmd)
            all_statements_valid = false
            @logger.info "argument validation error: #{cmd}"
          end
        end
        return all_statements_valid
      end

      # Checks to see if the arguments for a given command are valid.
      # This is done by calling the validate_args method of the command class.
      # @param [Hash] this_cmd parsed command tag
      # @return [Boolean]
      def statement_args_are_valid?(this_cmd)
        c = Sneaql::Core.find_class(:command, this_cmd[:command]).new(
          nil,
          @expression_handler,
          nil,
          @recordset_manager,
          nil,
          @logger
        )
        c.validate_args(this_cmd[:arguments])
      end
    end
  end
end
