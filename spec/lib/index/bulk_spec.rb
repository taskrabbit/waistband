require 'spec_helper'

describe "Waistband::Index -- Bulk" do

  let(:index)  { Waistband::Index.new('search') }

  it "permits bulk saving items" do
    saved = index.bulk([
      {action: :index, id: 987, body: {name: 'Peter', last_name: 'Johnson'}},
      {action: :index, id: 123, body: {name: 'Mary', last_name: 'Lamb'}},
      {action: :index, id: 4221, body: {name: 'Rhonda', last_name: 'Runner'}}
    ])

    expect(saved).to eql true

    data1 = index.find(987)
    data2 = index.find(123)
    data3 = index.find(4221)

    expect(data1).to eql({'name' => 'Peter', 'last_name' => 'Johnson'})
    expect(data2).to eql({'name' => 'Mary', 'last_name' => 'Lamb'})
    expect(data3).to eql({'name' => 'Rhonda', 'last_name' => 'Runner'})
  end

  it "permits bulk saving and updating" do
    saved = index.bulk([
      {action: :index, id: 987, body: {name: 'Peter', last_name: 'Johnson'}},
      {action: :index, id: 123, body: {name: 'Mary', last_name: 'Lamb'}},
      {action: :index, id: 4221, body: {name: 'Rhonda', last_name: 'Runner'}}
    ])

    expect(saved).to eql true

    data1 = index.find(987)
    data2 = index.find(123)
    data3 = index.find(4221)

    expect(data1).to eql({'name' => 'Peter', 'last_name' => 'Johnson'})
    expect(data2).to eql({'name' => 'Mary', 'last_name' => 'Lamb'})
    expect(data3).to eql({'name' => 'Rhonda', 'last_name' => 'Runner'})

    updated = index.bulk([
      {action: :update, id: 123, body: {doc: {last_name: 'J.'}}},
      {action: :update, id: 4221, body: {doc: {name: 'Rhondy'}}},
    ])

    expect(updated).to eql true

    data1 = index.find(987)
    data2 = index.find(123)
    data3 = index.find(4221)

    expect(data1).to eql({'name' => 'Peter', 'last_name' => 'Johnson'})
    expect(data2).to eql({'name' => 'Mary', 'last_name' => 'J.'})
    expect(data3).to eql({'name' => 'Rhondy', 'last_name' => 'Runner'})
  end

end
