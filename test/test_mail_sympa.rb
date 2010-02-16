########################################################################
# test_mail_sympa.rb
#
# This is the test suite for the mail-sympa library. You should run
# these tests via the test rake task.
########################################################################
require 'rubygems'
gem 'test-unit'

require 'test/unit'
require 'resolv'
require 'mail/sympa'

class MailSympaTest < Test::Unit::TestCase
  def self.startup
    @@url = "http://" + Resolv.getaddress('sympa') + "/sympasoap"
  end

  def setup
    @mail  = Mail::Sympa.new(@@url)
    @user  = 'postmaster@globe.gov' # Add your domain here
    @pass  = 'XXXXXXXX'             # Set the passwd here
    @topic = 'testlist'
    @nosub = 'partners'
  end

  # Because most methods won't work without logging in first
  def login
    @mail.login(@user, @pass)
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

  test "trusted method basic functionality" do
    assert_respond_to(@mail, :trusted)
    assert_nothing_raised{ @mail.trusted }
    assert_boolean(@mail.trusted)
  end

  test "trusted method expected result" do
    assert_false(@mail.trusted)
  end

  test "trusted method is a readonly attribute" do
    assert_raise(NoMethodError){ @mail.trusted = false }
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
    assert_kind_of(Array, @mail.lists(@topic))
    assert_kind_of(Array, @mail.lists(@topic, @topic))
  end

  test "lists method returns empty array if topic or subtopic is not found" do
    login
    assert_equal([], @mail.lists('bogus'))
    assert_equal([], @mail.lists(@topic, 'bogus'))
  end

  test "lists method accepts a maximum of two arguments" do
    assert_raise(ArgumentError){ @mail.lists(@topic, @topic, @topic) }
  end

  # Cl

  test "complex_lists method basic functionality" do
    login
    assert_respond_to(@mail, :complex_lists)
    assert_nothing_raised{ @mail.complex_lists }
  end

  test "complex_lists method with no arguments returns all lists" do
    login
    assert_kind_of(Array, @mail.lists)
    assert_kind_of(SOAP::Mapping::Object, @mail.complex_lists.first)
  end

  test "complex_lists method accepts a topic and subtopic" do
    login
    assert_kind_of(Array, @mail.complex_lists(@topic))
    assert_kind_of(Array, @mail.complex_lists(@topic, @topic))
  end

  test "lists method returns empty array if topic or subtopic is not found" do
    login
    assert_equal([], @mail.complex_lists('bogus'))
    assert_equal([], @mail.complex_lists(@topic, 'bogus'))
  end

  test "lists method accepts a maximum of two arguments" do
    assert_raise(ArgumentError){ @mail.complex_lists(@topic, @topic, @topic) }
  end

  test "info method basic functionality" do
    login
    assert_respond_to(@mail, :info)
    assert_nothing_raised{ @mail.info(@topic) }
  end

  test "info method expected results" do
    login
    assert_kind_of(SOAP::Mapping::Object, @mail.info(@topic))
  end

  test "review method basic functionality" do
    login
    assert_respond_to(@mail, :review)
    assert_nothing_raised{ @mail.review(@topic) }
  end

  test "review method returns expected results" do
    login
    assert_kind_of(Array, @mail.review(@topic))
    assert_kind_of(String, @mail.review(@topic).first)
  end

  test "review method returns 'no_subscribers' if list has no subscribers" do
    login
    assert_equal(['no_subscribers'], @mail.review(@nosub))
  end

  test "review method raises an error if list isn't found" do
    assert_raise(Soap::FaultError){ @mail.review('bogus') }
  end

  def teardown
    @mail = nil
    @user = nil
    @pass = nil
    @topic = nil
  end

  def self.shutdown
    @@url = nil
  end
end