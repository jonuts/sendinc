module Sendinc
  class Client
    def initialize(email, password)
      @email = email
      @password = password
    end

    attr_reader :email, :password

    def info
      return @account if @account
      response = get '/account.json'
      @account = Account.new response["account"]
    end

    def mail(opts={}, &blkopts)
      message = Message.new(self, opts, &blkopts)
      message.send!
    end

    def get(endpoint)
      response = RestClient.get build_url(endpoint)
      JSON.parse response.body
    end

    def post(endpoint, payload)
      RestClient.post build_url(endpoint), payload
    end

    private

    def build_url(path)
      "https://#{CGI::escape(email)}:#{CGI::escape(password)}@rest.sendinc.com#{path}"
    end
  end
end
