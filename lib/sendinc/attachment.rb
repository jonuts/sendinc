module Sendinc
  class Attachment
    def initialize(opts)
      if String === opts
        @path = opts
      else
        @file = opts[:file]
        @string = opts[:string]
        @filetype = opts[:filetype]
        @filename = opts[:filename]
        @path = opts[:path]
      end

    end
    attr_reader :file, :string, :filename, :filetype, :path
  end
end

