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

  describe 'sending valid message' do
    let(:mopts) do
      {
        to: 'foo@bar.com',
        subject: 'hello thar',
        body: 'wtf mate'
      }
    end

    context 'good response' do
      before do
        stub_request(:post, "https://rest.sendinc.com/message.json").to_return(body: '')
      end

      it 'sends successfully' do
        expect(client.mail(mopts)).to be
      end
    end
  end

  describe 'sending invalid message' do
    it 'bizzombs' do
      expect {client.mail}.to raise_error(Sendinc::MessageInvalidError)
    end
  end
end

describe Sendinc::Message  do
  let(:client) { Sendinc::Client.new(Faker::Internet.email, Faker::Internet.password) }

  describe '#new' do
    let(:message) { Sendinc::Message.new(client, mopts)}
    let(:mopts) { {} }

    it 'requires a client argument' do
      expect { Sendinc::Message.new }.to raise_error(ArgumentError)
    end

    it 'requires #client to be a client' do
      expect { Sendinc::Message.new('foo')}.to raise_error(ArgumentError)
      expect { Sendinc::Message.new(client) }.to_not raise_error
    end

    describe 'attachments' do
      it 'has empty list of attachments if none provided' do
        expect(message.attachments).to be_empty
      end

      it 'allows attachments to be sent in opts' do
        expect(Sendinc::Message.new(client, attachments: ['foo', 'bar']).attachments).to eql(%w(foo bar))
      end

      it 'allows attachments to be set in initializer block' do
        msg = Sendinc::Message.new(client) {|m| m.attach 'foo'}
        expect(msg.attachments).to eql(%w(foo))
      end
    end

    it 'has empty error list' do
      expect(message.error_list).to be_empty
    end

    describe 'message fields' do
      let(:to) { Faker::Internet.email}
      let(:cc) { Faker::Internet.email}
      let(:subject) { Faker::Hipster.sentence }
      let(:body) { Faker::Hipster.paragraph }

      [:to, :cc, :subject, :body].each do |field|
        describe "##{field}" do
          let(:mopts) { {field => send(field)}}

          it 'allows to field to be set from opts' do
            expect(message.send(field)).to eql(send(field))
          end

          it 'allows to field to be set from initializer block' do
            msg = Sendinc::Message.new(client) {|m| m.send("#{field}=", send(field))}
            expect(msg.send(field)).to eql(send(field))
          end
        end
      end
    end
  end

  describe 'invalid send' do
    subject(:message) { Sendinc::Message.new(client, mopts)}
    let(:mopts) { {} }

    before do
      message.valid?
    end

    context 'when missing all' do
      it 'is missing :to, :subject, body' do
        expect(message.error_list).to eql(%i(to subject body))
      end

      it 'cannot send' do
        expect {message.send!}.to raise_error(Sendinc::MessageInvalidError, /to, subject, body$/)
      end
    end

    context 'when missing :to' do
      let(:mopts) { {subject: 'foo', body: 'bar'} }

      it 'is missing :to' do
        expect(message.error_list).to eql(%i(to))
      end

      it 'cannot send' do
        expect {message.send!}.to raise_error(Sendinc::MessageInvalidError, /to$/)
      end
    end

    context 'when missing subject' do
      let(:mopts) { {to: 'foo', body: 'bar'} }

      it 'is missing :subject' do
        expect(message.error_list).to eql(%i(subject))
      end

      it 'cannot send' do
        expect {message.send!}.to raise_error(Sendinc::MessageInvalidError, /subject$/)
      end
    end

    context 'when missing :body' do
      let(:mopts) { {to: 'foo', subject: 'bar'} }

      it 'is missing :body' do
        expect(message.error_list).to eql(%i(body))
      end

      it 'cannot send' do
        expect {message.send!}.to raise_error(Sendinc::MessageInvalidError, /body$/)
      end
    end
  end

  describe 'valid send' do
    subject(:message) { Sendinc::Message.new(client, subject: 'lolwut', body: 'why, hello thar', to: 'foo@bar.com')}

    before do
      stub_request(:post, "https://rest.sendinc.com/message.json").to_return(status: 200, body: '')
    end

    it 'is a valid message' do
      expect(message).to be_valid
    end

    it 'can be sent' do
      expect(message.send!).to be
    end

    describe '#to_email' do
      it 'formats params correctly' do
        expect(message.to_email).to eql({
          subject: 'lolwut',
          message: 'why, hello thar',
          recipients: 'foo@bar.com',
          email: client.email
        })
      end
    end
  end
end
