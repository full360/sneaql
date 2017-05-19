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
        @steps = JSON.parse(
          File.read(@params[:step_metadata_file_path])
        ).sort_by! { |h| h['step_number'] }
        @steps.map! do |j|
          {
            step_number: j['step_number'],
            step_file: j['step_file']
          }
        end
      end
    end
  end
end
