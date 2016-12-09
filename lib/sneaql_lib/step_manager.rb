require 'json'

module Sneaql
  # Managers for transform steps
  module StepManagers
    # source step metadata from a json file
    class JSONFileStepManager < Sneaql::Core::StepMetadataManager
      Sneaql::Core::RegisterMappedClass.new(
        :step_metadata_manager,
        'local_file',
        Sneaql::StepManagers::JSONFileStepManager
      )
  
      # Manages steps from a local JSON file.
      def manage_steps
        @steps = JSON.parse(File.read(@params[:step_metadata_file_path])).sort_by! { |h| h['step_number'] }
        @steps.map! { |j| { step_number: j['step_number'], step_file: j['step_file'] } }
      end
    end
  
    # source step metadata from a standardized table in the target database
    class TransformStepTableManager < Sneaql::Core::StepMetadataManager
      Sneaql::Core::RegisterMappedClass.new(
        :step_metadata_manager,
        'transform_steps_table',
        Sneaql::StepManagers::TransformStepTableManager
      )
      
      # Manages steps based in a standardized table.
      def manage_steps
        jdbc_connection = JDBCHelpers::ConnectionFactory.new(
          @params[:jdbc_url],
          @params[:db_user],
          @params[:db_pass]
        ).connection
  
        @steps = JDBCHelpers::QueryResultsToArray.new(
          jdbc_connection,
          %(select
            transform_step
            ,sql_file_path_in_repo
          from
            #{@params[:transform_steps_table]}
          where
            transform_name='#{@params[:transform_name]}'
            and
            is_active=#{ if @params[:database_manager].has_boolean then 'true' else 1 end }
          order by
            transform_step asc;)
        ).results
  
        @steps.map! do |s| 
          { step_number: s['transform_step'], step_file: s['sql_file_path_in_repo'] }
        end
  
        jdbc_connection.close
      end
    end
  end
end
