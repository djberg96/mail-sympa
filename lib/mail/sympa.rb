require 'soap/rpc/driver'

# The Mail module serves as a namespace only.
module Mail
  # The Sympa module encapsulates the various Sympa server SOAP methods
  class Sympa
    # Error class raised in some cases if a Mail::Sympa method fails.
    class Error < StandardError; end

    # The session cookie returned by the login method.
    attr_reader :cookie

    # The endpoint URL of the SOAP service.
    attr_reader :endpoint

    # A boolean indicating whether remote applications should be trusted.
    attr_reader :trusted

    # The URN namespace. The default is 'urn:sympasoap'.
    attr_reader :namespace

    # Creates and returns a new Mail::Sympa object based on the +endpoint+
    # (the endpoint URL) and a +namespace+ which defaults to 'urn:sympasoap'.
    #
    # The +trusted+ argument determines whether or not to trust a particular
    # application to act as a proxy instead of authenticating the end user
    # itself.
    #
    def initialize(endpoint, trusted = false, namespace = 'urn:sympasoap')
      @endpoint  = endpoint.to_s # Allow for URI objects
      @namespace = namespace
      @trusted   = trusted

      @soap = SOAP::RPC::Driver.new(endpoint, namespace)

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
    # Example:
    #
    #  sympa = Mail::Sympa.new(url)
    #  sympa.login(user, password)
    #
    def login(email, password) 
      @email = email
      @password = password
      @cookie = @soap.login(email, password)
    end

    # Returns an array of available mailing lists based on +topic+ and
    # +sub_topic+. If +sub_topic+ is nil then all sub-topics are returned.
    # If +topic+ is nil then all lists are returned.
    #
    # The returned lists contains an array of strings. If you prefer objects
    # with methods corresponding to keys, see complex_lists instead.
    #
    # Example:
    #
    #  sympa = Mail::Sympa.new(url)
    #  sympa.login(user, password)
    #
    #  sympa.lists.each{ |list| puts list }
    #
    def lists(topic='', sub_topic='')
      raise Error 'must login first' unless @cookie
      args = [topic, sub_topic]
      @soap.authenticateAndRun(@email, @cookie, 'lists', args)
    end

    # Returns an array of available mailing lists in complex object format,
    # i.e. these are SOAP::Mapping objects that you can call methods on.
    #
    # Example:
    #
    #  sympa = Mail::Sympa.new(url)
    #  sympa.login(user, password)
    #
    #  sympa.complex_lists.each{ |list|
    #    puts list.subject
    #    puts list.homepage
    #  }
    #
    def complex_lists(topic='', sub_topic='')
      raise Error 'must login first' unless @cookie
      args = [topic, sub_topic]
      @soap.authenticateAndRun(@email, @cookie, 'complexLists', args)
    end

    alias complexLists complex_lists

    # Returns a description about the given +list_name+. This is a
    # SOAP::Mapping object.
    #
    # Example:
    #
    #  sympa = Mail::Sympa.new(url)
    #  sympa.login(user, password)
    #
    #  sympa.info(list)
    #
    def info(list_name)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'info', [list_name])
    end

    # Returns an array of members that belong to the given +list_name+.
    # Example:
    #
    #  sympa = Mail::Sympa.new(url)
    #  sympa.login(user, password)
    #
    #  sympa.review(list)
    #
    def review(list_name)
      raise Error 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'review', [list_name])
    end

    alias url endpoint
  end
end
