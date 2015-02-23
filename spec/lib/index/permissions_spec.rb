require 'spec_helper'

describe "Waistband::Index - Permissions" do

  let(:index)  { Waistband::Index.new('events') }
  let(:index2) { Waistband::Index.new('events_with_permissions') }
  let(:index3) { Waistband::Index.new('events_with_env_permissions') }

  it "detaults all permissions to true when not found" do
    expect(index.send(:permissions)).to eql({
      'create' => true,
      'delete_index' => true,
      'destroy' => true,
      'read' => true,
      'write' => true
    })
  end

  it "allows overriding permissions" do
    expect(index2.send(:permissions)).to eql({
      'create' => false,
      'delete_index' => false,
      'destroy' => false,
      'read' => false,
      'write' => false
    })
  end

  it "allows environment specific overriding" do
    expect(index3.send(:permissions)).to eql({
      'create' => true,
      'delete_index' => false,
      'destroy' => true,
      'read' => true,
      'write' => true
    })
  end

  it "doesn't allow writing" do
    expect {
      index2.create!
    }.to raise_error(Waistband::Errors::Permissions::Create)
  end

  it "doesn't allow deleting" do
    expect {
      index2.delete!
    }.to raise_error(Waistband::Errors::Permissions::DeleteIndex)
  end

  it "doesn't allow destroying" do
    expect {
      index2.destroy!('123')
    }.to raise_error(Waistband::Errors::Permissions::Destroy)
  end

  it "doesn't allow reading" do
    expect {
      index2.read!('123')
    }.to raise_error(Waistband::Errors::Permissions::Read)
  end

  it "doesn't allow finding" do
    expect {
      index2.find!('123')
    }.to raise_error(Waistband::Errors::Permissions::Read)
  end

  it "doesn't allow read_resulting" do
    expect {
      index2.read_result!('123')
    }.to raise_error(Waistband::Errors::Permissions::Read)
  end

  it "doesn't allow writing" do
    expect {
      index2.save!('123', {ok: 'nook'})
    }.to raise_error(Waistband::Errors::Permissions::Write)
  end

end
