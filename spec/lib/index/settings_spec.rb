require 'spec_helper'

describe "Waistband::Index -- Settings" do

  let(:index) { Waistband::Index.new('events') }
  let(:index2) { Waistband::Index.new('search') }

  it "permits turning refresh off" do
    settings = index.get_settings
    expect(settings['settings']['index']['refresh_interval']).to be_nil

    expect(index.refresh_off).to eql true

    settings = index.get_settings
    expect(settings['settings']['index']['refresh_interval']).to eql '-1'
  end

  it "permits turning on refresh" do
    settings = index.get_settings
    expect(settings['settings']['index']['refresh_interval']).to be_nil

    expect(index.refresh_off).to eql true

    settings = index.get_settings
    expect(settings['settings']['index']['refresh_interval']).to eql '-1'

    expect(index.refresh_on).to eql true

    settings = index.get_settings
    expect(settings['settings']['index']['refresh_interval']).to eql '1s'
  end

  it "respects the config's refresh interval when turning back on" do
    settings = index2.get_settings
    expect(settings['settings']['index']['refresh_interval']).to eql '5s'

    expect(index2.refresh_off).to eql true

    settings = index2.get_settings
    expect(settings['settings']['index']['refresh_interval']).to eql '-1'

    expect(index2.refresh_on).to eql true

    settings = index2.get_settings
    expect(settings['settings']['index']['refresh_interval']).to eql '5s'
  end

end
