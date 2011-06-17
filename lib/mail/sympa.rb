gem 'soap4r-ruby1.9' if RUBY_VERSION > '1.9'
require 'soap/rpc/driver'

# The Mail module serves as a namespace only.
module Mail
  # The Sympa module encapsulates the various Sympa server SOAP methods
  class Sympa
    # Error class raised in some cases if a Mail::Sympa method fails.
    class Error < StandardError; end

    # The version of the mail-sympa library.
    VERSION = '1.0.0'

    # The session cookie returned by the login method.
    attr_reader :cookie

    # The endpoint URL of the SOAP service.
    attr_reader :endpoint

    # The URN namespace. The default is 'urn:sympasoap'.
    attr_reader :namespace

    # Creates and returns a new Mail::Sympa object based on the +endpoint+
    # (the endpoint URL) and a +namespace+ which defaults to 'urn:sympasoap'.
    #
    # Example:
    #
    #   sympa = Mail::Sympa.new('http://your.sympa.home/sympasoap')
    #
    def initialize(endpoint, namespace = 'urn:sympasoap')
      @endpoint  = endpoint.to_s # Allow for URI objects
      @namespace = namespace

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

      @soap.add_method(
        'authenticateRemoteAppAndRun',
        'appname',
        'apppassword',
        'vars',
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
    #  sympa.login(email, password)
    #
    def login(email, password)
      @email    = email
      @password = password
      @cookie   = @soap.login(email, password)
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
    #  sympa.login(email, password)
    #
    #  sympa.lists.each{ |list| puts list }
    #
    def lists(topic='', sub_topic='')
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'lists', [topic, sub_topic])
    end

    # Returns an array of available mailing lists in complex object format,
    # i.e. these are SOAP::Mapping objects that you can call methods on.
    #
    # Example:
    #
    #  sympa = Mail::Sympa.new(url)
    #  sympa.login(email, password)
    #
    #  sympa.complex_lists.each{ |list|
    #    puts list.subject
    #    puts list.homepage
    #  }
    #
    def complex_lists(topic='', sub_topic='')
      raise Error, 'must login first' unless @cookie
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
    #  sympa.login(email, password)
    #
    #  info = sympa.info(list)
    #
    #  puts info.subject
    #  puts info.homepage
    #  puts info.isOwner
    #
    def info(list_name)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'info', [list_name])
    end

    # Returns an array of members that belong to the given +list_name+.
    #
    # Example:
    #
    #  sympa = Mail::Sympa.new(url)
    #  sympa.login(email, password)
    #
    #  sympa.review(list)
    #
    def review(list_name)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'review', [list_name])
    end

    # Returns an array of lists that the +user+ is subscribed to. The +user+
    # should include the proxy variable setup in the trusted_applications.conf
    # file.
    #
    # The +app_name+ is whatever is set in your trusted_applications.conf file.
    # The +app_password+ for that app must also be provided.
    #
    # Example:
    #
    #   sympa = Mail::Sympa.new(url)
    #   sympa.login(email, password)
    #
    #   # If vars contains USER_EMAIL
    #   sympa.which('USER_EMAIL=some_user@foo.com', 'my_app', 'my_password')
    #
    # An alternative is to use complex_lists + review, though it's slower.
    #
    def which(user, app_name, app_passwd)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateRemoteAppAndRun(app_name, app_passwd, user, 'which', [''])
    end

    # Same as the Sympa#which method, but returns an array of SOAP::Mapping
    # objects that you can call methods on.
    #
    def complex_which(user, app_name, app_passwd)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateRemoteAppAndRun(app_name, app_passwd, user, 'complexWhich', [''])
    end

    alias complexWhich complex_which

    # Returns a boolean indicating whether or not +user+ has +function+
    # on +list_name+. The two possible values for +function+ are 'editor'
    # and 'owner'.
    #
    def am_i?(user, list_name, function = 'editor')
      raise Error, 'must login first' unless @cookie

      unless ['editor', 'owner'].include?(function)
        raise Error, 'invalid function name "#{editor}"'
      end

      @soap.authenticateAndRun(@email, @cookie, 'amI', [list_name, function, user])
    end

    alias amI am_i?

    # Adds the given +email+ to +list_name+ using +name+ (gecos). If +quiet+
    # is set to true (the default) then no email notification is sent.
    #--
    # TODO: Determine why this method does not return a boolean.
    #
    def add(email, list_name, name, quiet=true)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'add', [list_name, email, name, quiet])
    end

    # Deletes the given +email+ from +list_name+. If +quiet+ is set to true
    # (the default) then no email notification is sent.
    #--
    # TODO: Determine why this method does not return a boolean.
    #
    def del(email, list_name, quiet=true)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'del', [list_name, email, quiet])
    end

    # Subscribes the currently logged in user to +list_name+. By default the
    # +name+ (gecos) will be the email address.
    #
    def subscribe(list_name, name = @email)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'subscribe', [list_name, name])
    end

    # Removes the currently logged in user from +list_name+.
    #
    def signoff(list_name)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'signoff', [list_name, @email])
    end

    alias delete del
    alias unsubscribe signoff
    alias url endpoint

    # Creates list +list_name+ with subject +subject+.  Returns boolean.
    #
    def create_list(list_name, subject, template='discussion_list', description=' ', topics=' ')
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'createList', [list_name, subject, template, description, topics])
    end

    alias createList create_list

    # Closes list +list_name+.  Returns boolean.
    #
    def close_list(list_name)
      raise Error, 'must login first' unless @cookie
      @soap.authenticateAndRun(@email, @cookie, 'closeList', [list_name])
    end

    alias closeList close_list

    # Run command in trusted context.
    def authenticate_remote_app_and_run(app_name, app_password, variables, service, parameters)
      @soap.authenticateRemoteAppAndRun( app_name, app_password, variables, service, parameters ) 
    end

    alias authenticateRemoteAppAndRun authenticate_remote_app_and_run

  end
end
