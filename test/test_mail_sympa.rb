########################################################################
# test_mail_sympa.rb
#
# This is the test suite for the mail-sympa library. You should run
# these tests via the test rake task.
########################################################################
require 'test/unit'
require 'mail/sympa'

class MailSympaTest < Test::Unit::TestCase
  def setup
    @mail = Mail::Sympa.new
  end

  def test_server_basic_functionality
    assert_respond_to(@mail, :server)
    assert_nothing_raised{ @mail.server }
    assert_kind_of(String, @mail.server)
  end

  def teardown
    @mail = nil
  end
end
