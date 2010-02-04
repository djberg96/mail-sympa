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
    @mail = Mail::Sympa.new(@@url)
    @user = 'postmaster@' # Add your domain here
    @pass = 'XXXXXX'      # Set the passwd here
  end

  # Because most methods won't work without logging in first
  def login
    @mail.login(@user, @passwd)
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

  test "namespace is a readonly attrubite" do
    assert_raise(NoMethodError){ @mail.namespace = 'foo' }
  end

  def teardown
    @mail = nil
    @user = nil
    @pass = nil
  end

  def self.shutdown
    @@url = nil
  end
end
