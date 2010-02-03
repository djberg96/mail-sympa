require 'soap/rpc/driver'

# The Mail module serves as a namespace only.
module Mail
  # The Sympa module encapsulates the various Sympa server SOAP methods
  class Sympa
    # Error class raised if any of the Sympa methods fail.
    class Error < StandardError; end

    # The session cookie returned by the login method.
    attr_reader :cookie

    # Creates and returns a new Mail::Sympa object based on the +url+ (the
    # endpoint URL) and a +namespace+ which defaults to 'urn:sympasoap'.
    #
    def initialize(url, namespace = 'urn:sympasoap')
      @url = url.to_s # Allows URI objects
      @namespace = namespace
      @soap = SOAP::RPC::Driver.new(url, namespace)

      @email    = nil
      @password = nil
      @cookie   = nil

      @soap.add_method('login', 'email', 'password')
  
      @soap.add_method(
        'authenticateAndRun',
        'email',
        'cookie',
        'service',
        'parameters'
      )
    end

    # Authenticate with the Sympa server. This method must be called before
    # any other methods can be used successfully.
    #
    def login(email, password) 
      @email = email
      @password = password
      @cookie = @soap.login(email, password)
    end

    # Returns a list of available mailing lists based on +topic+ and
    # +sub_topic+. If +sub_topic+ is nil then all sub-topics are returned.
    # If +topic+ is nil then all lists are returned.
    #
    def lists(topic='', sub_topic='')
      raise Error 'must login first' unless @cookie
      args = [topic, sub_topic]
      @soap.authenticateAndRun(@email, @password, 'lists', args)
    end
  end
end
