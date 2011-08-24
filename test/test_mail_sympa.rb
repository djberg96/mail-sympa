##############################################################################
# test_mail_sympa.rb
#
# This is the test suite for the mail-sympa library. You should run these
# tests via the test rake task.
#
# In order for these tests to run successfully you must use the dbi-dbrc
# library, and create an entry for 'test_sympa'. The user name should include
# the full domain, e.g. foo@bar.org. and the driver should be set to the URL:
#
# test_sympa postmaster@foo.org xxx http://foo.bar.org/sympasoap
#
# For all tests to complete successfully, you must use admin credentials.
##############################################################################

require 'mail/sympa'

silence_warnings do
  require 'rubygems'
  gem 'test-unit'

  require 'dbi/dbrc'
  require 'test/unit'
end

class MailSympaTest < Test::Unit::TestCase
  def self.startup
    @@info = DBI::DBRC.new('test_sympa')
    @@url  = @@info.driver
  end

  def setup
    @mail  = Mail::Sympa.new(@@url)
    @user  = @@info.user
    @pass  = @@info.passwd
    @list  = 'testlist'
    @nosub = 'partners'
  end

  def create_list(name)
    begin
      @mail.info(name)
    rescue
      begin
        @mail.create_list(name, name)
      rescue => e
        fail "list does not exist and could not be created: #{name} - #{e.to_s}"
      end
    end
  end

  # Because most methods won't work without logging in first
  def login
    @mail.login(@user, @pass)
  end

  test "version constant is expected value" do
    assert_equal('1.1.0', Mail::Sympa::VERSION)
  end

  test "endpoint method basic functionality" do
    assert_respond_to(@mail, :endpoint)
    assert_nothing_raised{ @mail.endpoint }
    assert_kind_of(String, @mail.endpoint)
  end

  test "endpoint method returns expected result" do
    assert_equal(@@url, @mail.endpoint)
  end

  test "endpoint method is a readonly attribute" do
    assert_raise(NoMethodError){ @mail.endpoint = 'foo' }
  end

  test "namespace method basic functionality" do
    assert_respond_to(@mail, :namespace)
    assert_nothing_raised{ @mail.namespace }
    assert_kind_of(String, @mail.namespace)
  end

  test "namespace method returns expected result" do
    assert_equal("urn:sympasoap", @mail.namespace)
  end

  test "namespace method is a readonly attrubite" do
    assert_raise(NoMethodError){ @mail.namespace = 'foo' }
  end

  test "login method basic functionality" do
    assert_respond_to(@mail, :login)
  end

  test "login method works as expected with proper credentials" do
    assert_nothing_raised{ @mail.login(@user, @pass) }
    assert_not_nil(@mail.cookie)
    assert_kind_of(String, @mail.login(@user, @pass))
  end

  test "login method raises an error if the credentials are invalid" do
    assert_raise(SOAP::FaultError){ @mail.login('bogus', 'bogus') }
  end

  test "login method requires two arguments" do
    assert_raise(ArgumentError){ @mail.login }
    assert_raise(ArgumentError){ @mail.login('bogus') }
  end

  test "lists method basic functionality" do
    login
    assert_respond_to(@mail, :lists)
    assert_nothing_raised{ @mail.lists }
  end

  test "lists method with no arguments returns all lists" do
    login
    assert_kind_of(Array, @mail.lists)
    assert_kind_of(String, @mail.lists.first)
  end

  test "lists method accepts a topic and subtopic" do
    login
    create_list(@list)
    assert_kind_of(Array, @mail.lists(@list))
    assert_kind_of(Array, @mail.lists(@list, @list))
  end

  test "lists method returns empty array if topic or subtopic is not found" do
    login
    assert_equal([], @mail.lists('bogus'))
    assert_equal([], @mail.lists(@list, 'bogus'))
  end

  test "lists method accepts a maximum of two arguments" do
    assert_raise(ArgumentError){ @mail.lists(@list, @list, @list) }
  end

  test "complex_lists method basic functionality" do
    login
    assert_respond_to(@mail, :complex_lists)
    assert_nothing_raised{ @mail.complex_lists }
  end

  test "complex_lists method with no arguments returns all lists" do
    login
    # we need to create a list here for systems that are being tested without lists
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_kind_of(Array, @mail.lists)
    assert_kind_of(SOAP::Mapping::Object, @mail.complex_lists.first)
    @mail.close_list(list_name)
  end

  test "complex_lists method accepts a topic and subtopic" do
    login
    assert_kind_of(Array, @mail.complex_lists(@list))
    assert_kind_of(Array, @mail.complex_lists(@list, @list))
  end

  test "complex_lists method returns empty array if topic or subtopic is not found" do
    login
    assert_equal([], @mail.complex_lists('bogus'))
    assert_equal([], @mail.complex_lists(@list, 'bogus'))
  end

  test "complex_lists method accepts a maximum of two arguments" do
    assert_raise(ArgumentError){ @mail.complex_lists(@list, @list, @list) }
  end

  test "info method basic functionality" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_respond_to(@mail, :info)
    assert_nothing_raised{ @mail.info(list_name) }
    @mail.close_list(list_name)
  end

  test "info method expected results" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_kind_of(SOAP::Mapping::Object, @mail.info(list_name))
    @mail.close_list(list_name)
  end

  test "review method basic functionality" do
    login
    assert_respond_to(@mail, :review)
    assert_nothing_raised{ @mail.review(@list) }
  end

  test "review method returns expected results" do
    login
    assert_kind_of(Array, @mail.review(@list))
    assert_kind_of(String, @mail.review(@list).first)
  end

  test "review method returns 'no_subscribers' if list has no subscribers" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_equal(['no_subscribers'], @mail.review(list_name))
    @mail.close_list(list_name)
  end

  test "review method raises an error if list isn't found" do
    login
    assert_raise(SOAP::FaultError){ @mail.review('bogusxxxyyyzzz') }
  end

  test "which basic functionality" do
    assert_respond_to(@mail, :which)
  end

  test "complex_which basic functionality" do
    assert_respond_to(@mail, :complex_which)
  end

  test "complexWhich is an alias for complex_which" do
    assert_alias_method(@mail, :complexWhich, :complex_which)
  end

  test "am_i basic functionality" do
    login
    assert_respond_to(@mail, :am_i?)
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_nothing_raised{ @mail.am_i?(@user, list_name) }
    assert_nothing_raised{ @mail.am_i?(@user, list_name, 'owner') }
    @mail.close_list(list_name)
  end

  test "am_i returns expected result" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_boolean(@mail.am_i?(@user, list_name))
    @mail.close_list(list_name)
  end

  test "am_i function name must be owner or editor" do
    assert_raise(Mail::Sympa::Error){ @mail.am_i?(@user, @list, 'bogus') }
  end

  test "amI is an alias for am_i?" do
    assert_alias_method(@mail, :amI, :am_i?)
  end

  test "add basic functionality" do
    assert_respond_to(@mail, :add)
  end

  test "add returns expected result" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    notify("The documentation says this should return a boolean")
    assert_boolean(@mail.add('test@foo.com', list_name, 'test'))
    @mail.close_list(list_name)
  end

  test "add requires at least three arguments" do
    assert_raise(ArgumentError){ @mail.add }
    assert_raise(ArgumentError){ @mail.add('test@foo.com') }
    assert_raise(ArgumentError){ @mail.add('test@foo.com', @list) }
  end

  test "del basic functionality" do
    assert_respond_to(@mail, :del)
  end

  test "del returns expected result" do
    login
    notify("The documentation says this should return a boolean")
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    @mail.add('test@foo.com', list_name, 'test')
    assert_boolean(@mail.del('test@foo.com', list_name))
    @mail.close_list(list_name)
  end

  test "delete is an alias for del" do
    assert_alias_method(@mail, :delete, :del)
  end

  test "del requires at least two arguments" do
    assert_raise(ArgumentError){ @mail.delete }
    assert_raise(ArgumentError){ @mail.delete('test@foo.com') }
  end

  test "subscribe basic functionality" do
    assert_respond_to(@mail, :subscribe)
  end

  test "subscribe expected results" do
    login
    assert_boolean(@mail.subscribe(@list, 'test'))
  end

  test "subscribe requires at least one argument" do
    assert_raise(ArgumentError){ @mail.subscribe }
  end

  test "signoff basic functionality" do
    assert_respond_to(@mail, :signoff)
  end

  test "signoff expected results" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    @mail.subscribe(list_name)
    assert_boolean(@mail.signoff(list_name))
    @mail.close_list(list_name)
  end

  test "unsubscribe is an alias for signoff" do
    assert_alias_method(@mail, :unsubscribe, :signoff)
  end

  test "signoff requires one argument only" do
    assert_raise(ArgumentError){ @mail.signoff }
    assert_raise(ArgumentError){ @mail.signoff(@user, @list) }
  end

  test "create_list basic functionality" do
    assert_respond_to(@mail, :create_list)
  end

  test "create_list returns expected result" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    assert_boolean(@mail.create_list(list_name, 'Test List'))
    @mail.close_list(list_name)
  end

  test "create_list requires at least two arguments" do
    assert_raise(ArgumentError){ @mail.create_list }
    assert_raise(ArgumentError){ @mail.create_list("test-#{Time.now.to_i.to_s}") }
  end

  test "close_list basic functionality" do
    assert_respond_to(@mail, :close_list)
  end

  test "close_list returns expected result" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    notify("The documentation says this should return a boolean")
    assert_boolean(@mail.close_list(list_name))
  end

  test "close_list requires one argument only" do
    assert_raise(ArgumentError){ @mail.close_list }
    assert_raise(ArgumentError){ @mail.close_list("A", "B")}
  end

  test "authenticate_remote_app_and_run basic functionality" do
    assert_respond_to(@mail, :authenticate_remote_app_and_run)
    assert_respond_to(@mail, :authenticateRemoteAppAndRun)
  end

  test "authenticate_remote_app_and_run requires five arguments" do
    assert_raise(ArgumentError){ @mail.authenticate_remote_app_and_run }
    assert_raise(ArgumentError){ @mail.authenticate_remote_app_and_run("A") }
    assert_raise(ArgumentError){ @mail.authenticate_remote_app_and_run("A", "B") }
    assert_raise(ArgumentError){ @mail.authenticate_remote_app_and_run("A", "B", "C") }
    assert_raise(ArgumentError){ @mail.authenticate_remote_app_and_run("A", "B", "C", "D") }
    assert_raise(ArgumentError){ @mail.authenticate_remote_app_and_run("A", "B", "C", "D", "E", "F") }
  end

  test "add moderation privileges basic functionality" do
    assert_respond_to(@mail, :add_admin_user)
  end

  test "add_admin_user requires three arguments" do
    assert_raise(ArgumentError){ @mail.add_admin_user}
    assert_raise(ArgumentError){ @mail.add_admin_user("A","B") }
    assert_raise(ArgumentError){ @mail.add_admin_user("A", "B", "C", "D", "E") }
  end

  test "add_admin_user requires a valid role" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    @mail.add('test@foo.com', list_name, 'Test EmailAccount')
    assert_raise(SOAP::FaultError){ @mail.add_admin_user('test@foo.com', list_name, 'meow') }
    @mail.close_list(list_name)
  end

  test "add_admin_user returns expected result" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    @mail.add('test@foo.com', list_name, 'Test EmailAccount')
    assert_boolean(@mail.add_admin_user('test@foo.com', list_name, 'editor'))
    @mail.close_list(list_name)
    notify("#{list_name} should have an editor")
  end

  test "del moderation privileges basic functionality" do
    assert_respond_to(@mail, :del_admin_user)
  end

  test "del_admin_user requires three arguments" do
    assert_raise(ArgumentError){ @mail.del_admin_user}
    assert_raise(ArgumentError){ @mail.del_admin_user("A", "B") }
    assert_raise(ArgumentError){ @mail.del_admin_user("A", "B", "C", "D", "E") }
  end

  test "del_admin_user raises an error if the user is not already an admin user" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    @mail.add('test@foo.com', list_name, 'Test EmailAccount')
    assert_raise(SOAP::FaultError){ @mail.del_admin_user('test@foo.com', list_name, 'editor') }
    @mail.close_list(list_name)
  end

  test "del_admin_user returns expected result" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    @mail.add('test@foo.com', list_name, 'Test EmailAccount')
    @mail.add_admin_user('test@foo.com', list_name, 'editor')
    assert_boolean(@mail.del_admin_user('test@foo.com', list_name, 'editor'))
    @mail.close_list(list_name)
  end

  test "chnage list scenari basic functionality" do
    assert_respond_to(@mail, :change_list_scenari)
  end

  test "change_list_scenari requires two arguments" do
    assert_raise(ArgumentError){ @mail.change_list_scenari}
    assert_raise(ArgumentError){ @mail.change_list_scenari("A") }
    assert_raise(ArgumentError){ @mail.change_list_scenari("A", "B", "C", "D") }
  end

  test "change_list_scenari raises an error if the scenario does not exist" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_raise(SOAP::FaultError){ @mail.change_list_scenari(list_name, 'fake_scenario') }
    @mail.close_list(list_name)
  end

  test "change_list_scenari returns expected result" do
    login
    list_name = "test-#{Time.now.to_i.to_s}"
    @mail.create_list(list_name, 'Test List')
    assert_boolean(@mail.change_list_scenari(list_name, 'private'))
    notify("#{list_name} should be set to private now")
    @mail.close_list(list_name)
  end

  def teardown
    @mail = nil
    @user = nil
    @pass = nil
    @list = nil
  end

  def self.shutdown
    @@url  = nil
    @@info = nil
  end
end
