require 'spec_helper'

describe Sendinc do
  it 'has a version number' do
    expect(Sendinc::VERSION).not_to be nil
  end
end

describe Sendinc::Client do
  let(:client) { Sendinc::Client.new(Faker::Internet.email, Faker::Internet.password) }

  describe '#info' do
    before do
      # stub_request
      stub_request(:get, "https://rest.sendinc.com/account.json").to_return(status: 200, body: {account: stubresp}.to_json)
    end

    let(:info) { client.info }
    let(:stubresp) { { name: Faker::Name.name }}

    context 'already assigned @account' do
      let(:cachedval) { {name: Faker::Name.name} }

      before do
        client.instance_variable_set :@account, Sendinc::Account.new(cachedval)
      end

      it "returns the cached val" do
        expect(info.name).to eql(Sendinc::Account.new(cachedval).name)
      end
    end

    context 'empty @account' do
      it 'returns the new val' do
        expect(info.name).to eql(Sendinc::Account.new(stubresp).name)
      end
    end
  end
end

