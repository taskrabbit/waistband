ENV['RACK_ENV'] ||= 'test'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
APP_DIR ||= File.expand_path('../../', __FILE__)

require 'waistband'
require 'rspec'
require 'timecop'
require 'active_support/core_ext/integer/time'
require 'debugger'

Dir["#{APP_DIR}/spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|


  Waistband.configure do |c|
    c.config_dir = "#{APP_DIR}/spec/config/waistband"
  end

  config.around(:each) do |example|
    IndexHelper.delete_all
    IndexHelper.create_all
    example.run
    IndexHelper.delete_all
  end

  config.after(:each) do
    Timecop.return
  end

end
