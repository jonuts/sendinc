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

    def generate
      if file
        file
      elsif string
        generate_for_string
      elsif path
        generate_for_path
      else
        raise MessageInvalidError, 'attachment not provided'
      end
    end

    private

    def generate_for_string
      tmppath = [(filename || 'sendinc_attachment'), filetype].compact
      tmpfile = Tempfile.new tmppath
      begin
        tmpfile.write string
      ensure
        tmpfile.close
      end
      File.new(tmpfile.path, 'rb')
    end

    def generate_for_path
      if File.exists? path
        File.new(path, 'rb')
      else
        raise MessageInvalidError, 'file doesnt exist'
      end
    end
  end
end

