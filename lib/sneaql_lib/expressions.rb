require 'logger'
require 'time'

module Sneaql
  module Core
    # Handles variables, expression evaluation, and comparisons.
    # A single ExpressionHandler is created per transform.  This
    # object will get passed around to the various commands as well
    # as other manager objects attached to the transform class.
    class ExpressionHandler
      # @param [Hash] environment_variables pass in a set of ENV
      # @param [Logger] logger object otherwise will default to new Logger
      def initialize(logger = nil)
        @logger = logger ? logger : Logger.new(STDOUT)
        @environment_variables = filtered_environment_variables
        validate_environment_variables unless ENV['SNEAQL_DISABLE_SQL_INJECTION_CHECK']
        @environment_variables.freeze
        @session_variables = {}
      end

      # @param [String] var_name identifier for variable
      # @param [String, Fixnum, Float] var_value value to store, expressions here will not be evaluated
      def set_session_variable(var_name, var_value)
        @logger.info("setting session var #{var_name} to #{var_value}")
        raise "can't set variable #{var_name}" unless valid_session_variable_name?(var_name)
        @session_variables[var_name] = var_value
      end

      # validates that this would make a suitable variable name
      # @param [String] var_name
      # @return [Boolean]
      def valid_session_variable_name?(var_name)
        r = var_name.to_s.match(/^\w+$/) && !var_name.to_s.match(/env\_\w*/) && !var_name.to_s.match(/^\d+/) ? true : false
        @logger.debug("validating #{var_name} as valid variable identifier indicates #{r}")
        r
      end

      # @param [String] var_name identifier for variable
      # @return [String, Fixnum, Float]
      def get_session_variable(var_name)
        @session_variables[var_name]
      end

      # convenience method, outputs all session variables to the logger
      def output_all_session_variables
        @logger.debug("current session variables: #{@session_variables}")
      end

      # @param [String] var_name identifier for environment variable as defined in ENV
      # @return [String]
      def get_environment_variable(var_name)
        @environment_variables[var_name]
      end

      # @param [String] expression either a numeric constant, string constant in '',
      # or reference to session or environment variable
      # @return [String, Fixnum, Float]
      def evaluate_expression(expression)
        return expression unless expression.class == String

        # first handle empty string
        if expression == "''"
          return ''

        # reference to an environment variable
        # :env_var_name or :ENV_var_name
        # env variable references are case insensitive in this case
        elsif expression =~ /^\:env\_\w+/i
          return @environment_variables[expression.gsub(/\:env\_/i, '').strip]

        # reference to a variable
        # ANSI dynamic SQL :var_name
        # variable names are case sensitive
        elsif expression =~ /^\:\w+/
          return @session_variables[expression.gsub(/\:/, '').strip]

        # deprecated
        elsif expression =~ /^\{.*\}$/
          @logger.warn('{var_name} deprecated. use dynamic SQL syntax :var_name')
          return @session_variables[expression.gsub(/\{|\}/, '').strip]

        # boolean
        elsif ['true', 'false'].include?(expression.downcase)
          @logger.debug "handling #{expression} as boolean"
          return true if expression.downcase == 'true'
          return false if expression.downcase == 'false'

        # string literal enclosed in single quotes

        elsif expression.match(/^\s*\'.*\'\s*$/)
          return expression.strip[1..expression.strip.length - 2]

        # else assume it is a numeric literal
        # need some better thinking here
        else
          return expression.strip
        end
      rescue => e
        @logger.error("error evaluating expression: #{e.message}")
        e.backtrace.each { |b| @logger.error(b.to_s) }
        raise Sneaql::Exceptions::ExpressionEvaluationError
      end

      # evaluates all expressions in a given SQL statement.
      #   replaces...
      #     environment variables in the form :env_HOSTNAME
      #     session variables in the form :variable_name
      #     session variables in the deprecated form {variable_name}
      # @param [String] statement SQL statement to have all expressions evaluated
      # @return [String] SQL statement with all variable references resolved
      def evaluate_all_expressions(statement)
        evaluate_session_variables(statement)
        evaluate_environment_variables(statement)
        evaluate_session_variables_braces(statement)
        return statement
      rescue => e
        @logger.error "evaluation error #{e.message}"
        e.backtrace.each { |b| logger.error b.to_s }
        raise Sneaql::Exceptions::ExpressionEvaluationError
      end

      # evaluates all environment variables in a given SQL statement.
      #   replaces...
      #     environment variables in the form :env_HOSTNAME
      # variables are sorted and reversed before performing substitutions
      # this prevents :var from partially overwriting :var_foo
      # @param [String] statement SQL statement to have all environment variables evaluated
      # @return [String] SQL statement with all variable references resolved
      def evaluate_session_variables(statement)
        # replaces :var_name in provided statement
        @session_variables.keys.sort.reverse.each do |k|
          statement.gsub!(/\:#{k}/, @session_variables[k].to_s)
        end
      end

      # evaluates all session variables in a given SQL statement.
      #   replaces...
      #     session variables in the form :variable_name
      # variables are sorted and reversed before performing substitutions
      # this prevents :var from partially overwriting :var_foo
      # @param [String] statement SQL statement to have all session variables evaluated
      # @return [String] SQL statement with all variable references resolved
      def evaluate_environment_variables(statement)
        # replace env vars in the form :env_HOSTNAME
        @environment_variables.keys.sort.reverse.each do |e|
          statement.gsub!(/\:env\_#{e}/i, @environment_variables[e])
        end
      end

      # evaluates all session variables in a given SQL statement.
      #   replaces...
      #     session variables in the deprecated form {variable_name}
      # @param [String] statement SQL statement to have all deprecated form variable references evaluated
      # @return [String] SQL statement with all variable references resolved
      # @deprecated
      def evaluate_session_variables_braces(statement)
        # deprecated
        @session_variables.keys.each do |k|
          statement.gsub!(/\{#{k}\}/, @session_variables[k].to_s)
        end
      end

      # validates that this would make a suitable reference at run time.
      # checks to see this is single quoted string, :variable_name, {var_name) or number (1, 1.031, etc.)
      # @param [String] expr value to check
      def valid_expression_reference?(expr)
        expr.to_s.match(/(^\s*\'.+\'\s*$|^\:\w+$|^\{\w+\}$|^\d+$|^\d+\.\d*$|true|false)/i) ? true : false
      end

      # Operators valid for expression comparison
      # @return [Array<String>]
      def valid_operators
        ['=', '!=', '>', '<', '>=', '<=', 'like', 'notlike']
      end

      # provides a standardized method of comparing two expressions.
      # note that this only works for variables and constants.
      # current version supports float, integer, and contigious strings.
      # as of 0.0.13 expressions need to be evaluated before being passed
      # @param [String] operator comparison operator @see valid_operators
      # @param [String] exp1 expression for left operand
      # @param [String] exp2 expression for right operand
      def compare_expressions(operator, exp1, exp2)
        unless valid_operators.include?(operator)
          raise Sneaql::Exceptions::InvalidComparisonOperator
        end

        @logger.debug "evaluating #{exp1} #{operator} #{exp2}"

        # evaluate exps and coerce data types
        coerced = coerce_data_types(
          exp1,
          exp2
        )

        compare_values(operator, coerced[0], coerced[1])
      end

      # coerces the data types for both expressions to match for valid comparison
      # @param [String, Float, Fixnum] exp1 expression for left operand
      # @param [String, Float, Fixnum] exp2 expression for right operand
      # @return [Array<Float, Fixnum, String>] returns array with both input expressions coerced to the same data type
      def coerce_data_types(exp1, exp2)
        # coerce data types to make for a good comparison
        @logger.debug("coercing types #{[exp1.class, exp2.class]}")
        if exp1.class == exp2.class
          nil # nothing to do... continue with comparison
        elsif array_has_boolean_value?([exp1, exp2])
          # if one of the values is an actual Boolean object...
          unless [coerce_boolean(exp1), coerce_boolean(exp2)].include?(nil)
            exp1 = coerce_boolean(exp1)
            exp2 = coerce_boolean(exp2)
          end
        elsif exp1.class == Time
          tmp = coerce_datetime(exp2)
          if tmp
            exp2 = tmp
          else
            exp1, exp2 = exp1.to_s, exp2.to_s
          end
        elsif exp2.class == Time
          tmp = coerce_datetime(exp1)
          if tmp
            exp1 = tmp
          else
            exp1, exp2 = exp1.to_s, exp2.to_s
          end
        elsif [exp1.class, exp2.class].include?(Float)
          # if either is a float then make sure they are both floats
          exp1 = exp1.to_f
          exp2 = exp2.to_f
        elsif [exp1.class, exp2.class].include?(Fixnum)
          # otherwise... if one is an integer make them both integers
          exp1 = exp1.to_i
          exp2 = exp2.to_i
        end
        @logger.debug("coerced types #{[exp1.class, exp2.class]}")
        [exp1, exp2]
      end

      def coerce_datetime(obj)
        retobj = nil
        case
          when obj.class == Fixnum then retobj = Time.at(obj)
          when obj.class == String then retobj = Time.parse(obj)
          when obj.class == Time then retobj = obj
        end
        retobj
      end

      # checks to see if any element of the array has a boolean value
      # @param [Array<Object>] arr array of objects
      # @return [Boolean]
      def array_has_boolean_value?(arr)
        tmp = arr.map { |e| e.class }
        # [exp1.class, exp2.class].include?(FalseClass) || [exp1.class, exp2.class].include?(TrueClass)
        tmp.include?(FalseClass) || tmp.include?(TrueClass)
      end

      # evaluates string or fixnum values to coerce into boolean
      # @param [Object] value
      # @return [Object]
      def coerce_boolean(value)
        retval = nil
        if array_has_boolean_value?([value])
          retval = value
        elsif value.class == Fixnum
          retval = true if value == 1
          retval = false if value.zero?
        elsif value.class == String
          retval = text_to_boolean(value)
        end
        retval
      end

      # converts text representation of boolean to boolean
      # @param [String] value
      # @return [Boolean]
      def text_to_boolean(value)
        case value.downcase.strip
        when 'f', 'false', '0'
          retval = false
        when 't', 'true', '1'
          retval = true
        end
        retval
      end

      # performs the actual comparison between two values
      # @param [String] operator comparison operator @see valid_operators
      # @param [String] exp1 expression for left operand
      # @param [String] exp2 expression for right operand
      # @return [Boolean]
      def compare_values(operator, exp1, exp2)
        # below are all the valid comparison operators
        @logger.debug("comparing #{exp1} #{operator} #{exp2}")
        case operator
        when '=' then return exp1 == exp2
        when '!=' then return exp1 != exp2
        when '>=' then return exp1 >= exp2
        when '<=' then return exp1 <= exp2
        when '>' then return exp1 > exp2
        when '<' then return exp1 < exp2
        when 'like' then return like_operator(exp1, exp2)
        when 'notlike' then return !like_operator(exp1, exp2)
        end
      end

      # performs SQL style LIKE comparison between inputs
      # @param [String] left_operand
      # @param [String] like_right_operand this will be the like expression
      # @return [Boolean]
      def like_operator(left_operand, like_right_operand)
        # converts to string before comparison
        left_operand.to_s.match(wildcard_to_regex(like_right_operand.to_s)) ? true : false
      end

      # converts a SQL LIKE wildcard expression to a Regexp
      # @param [String] wildcard like expression
      # @return [Regexp] returns regexp object for use in match comparison
      def wildcard_to_regex(wildcard)
        Regexp.new("^#{wildcard}$".gsub('%', '.*').gsub('_', '.'))
      end

      # create a hash built from supplied environment variables.
      # if SNEAQL_AVAILABLE_ENV_VARS is provided (as a comma delimited list)
      # only the listed values are included.
      # return <Hash>
      def filtered_environment_variables
        env_vars = {}
        if ENV['SNEAQL_AVAILABLE_ENV_VARS']
          @logger.debug('filtering environment variables')
          available = ENV['SNEAQL_AVAILABLE_ENV_VARS'].split(',')
          ENV.keys.each { |k| env_vars[k] = ENV[k] if available.include?(k) }
        else
          @logger.debug('setting environment variables')
          ENV.keys.each { |k| env_vars[k] = ENV[k] }
        end
        env_vars
      end

      # basic regex filtering to help combat sql injection
      # by way of environment variables
      # @param [String] value value for validation
      # @return [Boolean] returns true if value is safe
      def sql_injection_filter(value)
        return false if value.to_s.match(/(\'|\;|(drop|alter).*(table|user|view|column|database|schema|function|sequence|procedure))/i)
        true
      end

      # insures that all environment variables pass SQL injection test
      def validate_environment_variables
        @environment_variables.keys.each do |k|
          unless sql_injection_filter(@environment_variables[k])
            raise 'SQL Injection Filter Error'
          end
        end
      end
    end
  end
end
