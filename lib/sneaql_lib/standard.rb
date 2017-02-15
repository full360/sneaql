module Sneaql
  # Classes to manage DB objects for standard SneaQL deployment.
  module Standard
    # Manages execution of a standard transform
    class StandardTransform
      
      attr_accessor {
        :jdbc_url,
        :db_user,
        :db_pass
      }
      
      def initialize()
        # set parameters
        
        # determine database type
        
      end
      
      def execute_all_transforms()
      
      end
      
      def execute_single_transform(transform_name)
        
      end
      
    end
  end
end