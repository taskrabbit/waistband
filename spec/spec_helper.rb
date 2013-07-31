ENV['RACK_ENV'] ||= 'test'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
APP_DIR ||= File.expand_path('../../', __FILE__)

require 'waistband'
require 'rspec'
require 'timecop'
require 'active_support/core_ext/integer/time'

Dir["#{APP_DIR}/spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

  config.before(:all) do
    Waistband.configure do |c|
      c.config_dir = "#{APP_DIR}/spec/config/waistband"
    end
  end

  config.before(:each) do |c|
    IndexHelper.destroy_all!
    IndexHelper.create_all!
  end

  config.after(:each) do
    Timecop.return
  end

end
