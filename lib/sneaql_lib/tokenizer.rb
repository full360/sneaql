module Sneaql
  module Core
    @@valid_tokenizer_states = [
      :outside_word,
      :in_word,
      :in_string_literal,
      :in_string_literal_escape
    ]

    # these are the states that can be jumped between during tokenization.
    # @return [Array<Symbol>]
    def self.valid_tokenizer_states
      @@valid_tokenizer_states
    end

    @@tokenizer_state_map = {
      whitespace: {
        outside_word: [:no_action],
        in_word: [:outside_word],
        in_string_literal: [:concat],
        in_string_literal_escape: [:concat]
      },
      escape: {
        outside_word: [:error],
        in_word: [:error],
        in_string_literal: [:in_string_literal_escape],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
      word: {
        outside_word: [:new_token, :concat, :in_word],
        in_word: [:concat],
        in_string_literal: [:concat],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
      colon: {
        outside_word: [:new_token, :concat, :in_word],
        in_word: [:concat],
        in_string_literal: [:concat],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
      singlequote: {
        outside_word: [:new_token, :concat, :in_string_literal],
        in_word: [:error],
        in_string_literal: [:concat, :outside_word],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
      openbrace: {
        outside_word: [:new_token, :concat, :in_word],
        in_word: [:error],
        in_string_literal: [:concat],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
      closebrace: {
        outside_word: [:error],
        in_word: [:concat],
        in_string_literal: [:concat],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
      operator: {
        outside_word: [:new_token, :concat, :in_word],
        in_word: [:concat],
        in_string_literal: [:concat],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
      nonword: {
        outside_word: [:new_token, :concat, :in_word],
        in_word: [:concat],
        in_string_literal: [:concat],
        in_string_literal_escape: [:concat, :in_string_literal]
      },
    }

    # state machine for use when iterating through the character
    # classifications of a given command. pass in the character c
    # classification and current state and you will receive an
    # array of actions to execute in sequence. these actions
    # include the ability to change state.
    # @return [Hash]
    def self.tokenizer_state_map
      @@tokenizer_state_map
    end

    # used to process a command string into an array of tokens.
    # the handling here is pretty basic and geared toward providing
    # string literal functionality.
    # a string literal is enclosed in single quotes, with backslash
    # as an escape character. the only escapable characters
    # are single quotes and backslashes.
    # this process does not interpret whether or not a token
    # is valid in any way, it only seeks to break it down reliably.
    # string literal tokens will not have escape characters removed,
    # and will be enclosed in single quotes.
    class Tokenizer
      # classifies a single character during lexical parsing
      # @param [String] input_char single character to classify
      # @return [Symbol] classification for character
      def classify(input_char)
        # whitespace delimits tokens not in string lteral
        return :whitespace if input_char.match(/\s/)

        # escape character can escape itself
        return :escape if input_char.match(/\\/)

        # any word character
        return :word if input_char.match(/\w/)

        # colon is used to represent variables
        return :colon if input_char.match(/\:/)

        # indicates start of string literal
        return :singlequote if input_char.match(/\'/)

        # deprecated, old variable reference syntax
        return :openbrace if input_char.match(/\{/)
        return :closebrace if input_char.match(/\}/)

        # comparison operator chars
        return :operator if input_char.match(/\=|\>|\<|\=|\!/)

        # any non-word characters
        return :nonword if input_char.match(/\W/)
      end

      # returns an array with a classification for each character
      # in input string
      # @param [String] string
      # @return [Array<Symbol>] array of classification symbols
      def classify_all(string)
        classified = []
        string.split('').each do |x|
          classified << classify(x)
        end
        classified
      end

      # returns an array of tokens.
      # @param [String] string command string to tokenize
      # @return [Array<String>] tokens in left to right order
      def tokenize(string)
        # perform lexical analysis
        classified = classify_all(string)

        # set initial state
        state = :outside_word

        # array to collect tokens
        tokens = []

        # will be rebuilt for each token
        current_token = ''

        # iterate through each character
        classified.each_with_index do |c, i|
          # perform the actions appropriate to character
          # classification and current state
          Sneaql::Core.tokenizer_state_map[c][state].each do |action|
            case
            when action == :no_action then
              nil
            when action == :new_token then
              # rotate the current token if it is not empty string
              tokens << current_token unless current_token == ''
              current_token = ''
            when action == :concat then
              # concatenage current character to current token
              current_token += string[i]
            when action == :error then
              raise 'tokenization error'
            when Sneaql::Core.valid_tokenizer_states.include?(action)
              # if the action is a state name, set the state
              state = action
            end
          end
        end
        # close current token if not empty
        tokens << current_token unless current_token == ''

        # return array of tokens
        tokens
      end
    end
  end
end
