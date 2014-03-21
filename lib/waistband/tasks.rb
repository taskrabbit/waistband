require 'waistband'

namespace :waistband do

  desc "migrate the indeces schema from the `waistband_schema.yml` file"
  task :migrate! => :environment do
    CouchPotato::ViewProcessor.create_all_views! verbose: true
  end

end
