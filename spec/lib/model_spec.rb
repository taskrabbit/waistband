require 'spec_helper'

describe Waistband::Model do

  class Log < Waistband::Model

    with_index  :events
    columns     :log, :user_id, :content
    stringify   :content
    defaults    user_id: 999

    validates :content

    def before_save
      self.log = true
    end

  end

  describe Log do

    let(:log) { Log.new(user_id: 1, content: "oh yeah!") }

    describe '.first' do

      before { IndexHelper.prepare! }

      it "returns first element by created_at" do
        logs = 10.times.to_a.map do |i|
          Timecop.travel((i + 1).minutes.from_now) do
            Log.create(user_id: 1, content: "something we wanna log!")
          end
        end

        Log.index.refresh
        Log.first.id.should eql logs.first.id
      end

      it "returns a Log object" do
        Log.create(user_id: 1, content: "something we wanna log!")
        Log.index.refresh
        Log.first.should be_a Log
      end

    end

    describe '.last' do

      before { IndexHelper.prepare! }

      it "returns last element by created_at" do
        logs = 10.times.to_a.map do |i|
          Timecop.travel((i + 1).minutes.from_now) do
            Log.create(user_id: 1, content: "something we wanna log!")
          end
        end

        Log.index.refresh
        Log.last.id.should eql logs.last.id
      end

      it "returns a Log object" do
        Log.create(user_id: 1, content: "something we wanna log!")
        Log.index.refresh
        Log.last.should be_a Log
      end

    end

    describe '.find' do

      it "loads the log from elastic search" do
        log.save
        stored_log = Log.find(log.id)

        stored_log.id.should eql log.id
        stored_log.user_id.should eql log.user_id
        stored_log.content.should eql log.content
      end

    end

    describe '.create' do

      it "saves the log to elastic search" do
        stored_log = Log.create(log.attributes)

        stored_log.id.should be_present
        stored_log.id.length.should eql 40

        stored_log.user_id.should eql log.user_id
        stored_log.content.should eql log.content
      end

    end

    it "blows up when initializing with invalid column name" do
      expect { Log.new(bla: 'test') }.to raise_error(ArgumentError, "bla is not a valid column name!")
    end

    it "permits initializing with `nil` as attributes" do
      expect { Log.new(nil) }.to_not raise_error
    end

    it "initializes correctly with valid column names" do
      log.user_id.should eql 1
      log.content.should eql "oh yeah!"
    end

    it "stringifies denoted fields" do
      log = Log.new(user_id: 1, content: {ok: true})
      log.save

      Log.index.read(log.id)['content'].should eql "{:ok=>true}"
      log.content.should eql "{:ok=>true}"

      log = Log.create(user_id: 1, content: {ok: true})

      Log.index.read(log.id)['content'].should eql "{:ok=>true}"
      log.content.should eql "{:ok=>true}"
    end

    it "automatically creates relationships" do
      User ||= double
      User.should_receive(:find).with(1).once
      log.user
    end

    it "permits directly setting the relationship" do
      User  ||= double
      admin   = double(id: 3)

      log.user = admin

      log.user_id.should eql 3

      User.should_receive(:find).with(3).once
      log.user
    end

    describe '#save' do

      it "auto generates id when saving" do
        log.save
        log.id.should be_present
        log.id.length.should eql 40
      end

      it "sets timestamps" do
        log.save
        log.created_at.should be_a Fixnum
        log.updated_at.should be_a Fixnum
      end

      it "doesn't modify created_at on updates" do
        log.save
        created_at = log.created_at
        updated_at = log.updated_at

        Timecop.travel(5.seconds.from_now) do
          log.save
          updated_at.should_not eql log.updated_at
          created_at.should eql log.created_at
        end
      end

      it "doesn't mark id and timestamps if save fails" do
        log.should_receive(:store!).once.and_return('{"ok":false}')
        log.save

        log.id.should be_nil
        log.created_at.should be_nil
        log.updated_at.should be_nil
      end

      it "if the id was previously set and the save fails, the id sticks" do
        log.id = 123
        log.should_receive(:store!).once.and_return('{"ok":false}')
        log.save

        log.id.should eql 123
      end

      it "persists to elastic search" do
        log.save

        stored = Log.index.read(log.id)

        stored['id'].should eql log.id
        stored['user_id'].should eql log.user_id
        stored['content'].should eql log.content
      end

      it "sets default values" do
        log = Log.new(content: "some new stuff")
        log.save.should be_true

        log.user_id.should eql 999
      end

      it "validates fields" do
        log = Log.new
        log.should_not be_valid

        log.errors.should eql ["content cannot be nil"]
      end

      it "sets the model type" do
        log.save
        Log.index.read(log.id)['model_type'].should eql 'log'
      end

    end

  end

end
