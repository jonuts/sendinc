module Sendinc
  MessageInvalidError = Class.new(StandardError)

  class Message
    REQUIRED_FIELDS = %i(to subject body).freeze

    def initialize(client, opts={})
      raise ArgumentError, "client must be a `Sendinc::Client`" unless Sendinc::Client === client
      @client = client

      @attachments = []
      @error_list = []

      @to = opts.delete :to
      @cc = opts.delete :cc
      @subject = opts.delete :subject
      @body = opts.delete :body

      Array(opts.delete(:attachments)).each do |attachment|
        attach attachment
      end
      yield self if block_given?
    end

    attr_accessor :subject, :body, :to, :cc
    attr_reader :client, :attachments, :error_list

    # path<string>:: Must be path to an existing file on the filesystem
    def attach(opts={})
      attachments << Attachment.new(opts)
    end

    def valid?
      error_list.clear

      REQUIRED_FIELDS.each do |field|
        error_list << field unless send(field)
      end
      error_list.empty?
    end

    def send!
      raise MessageInvalidError, "Message missing the following fields: #{error_list.join(', ')}" unless valid?

      client.post '/message.json', to_email
      true
    end

    def to_email
      {
        subject: subject,
        message: body,
        email: client.email,
        recipients: to
      }.tap {|opts|
        opts[:cc] = cc if cc
        attachments.each.with_index {|attachment, idx|
          opts[:"att_#{idx}"] = attachment.generate
        }
      }
    end
  end
end

