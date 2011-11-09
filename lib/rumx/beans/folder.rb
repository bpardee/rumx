module Rumx
  module Beans
    # Bean that contains child beans.  Since all beans have this functionality, this is
    # essentially just a Bean that has no attributes or operations.
    class Folder
      include Bean
    end
  end
end
