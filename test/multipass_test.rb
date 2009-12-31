$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'test/unit'
require 'multipass'
#require 'active_support'

module MultiPassTests
  def test_encodes_multipass
    expected = MultiPass.encode_64(@key.encrypt(@output.to_json), @mp.url_safe?)
    assert_equal expected, @mp.encode(@input)
  end

  def test_encodes_multipass_with_class_method
    if @mp.url_safe?
      expected = MultiPass.encode_64(@key.encrypt(@output.to_json), @mp.url_safe?)
      assert_equal expected, MultiPass.encode('example', 'abc', @input)
    else
      # skip, there's no way to disable url safe base64 strings
    end
  end

  def test_decodes_multipass
    encoded = @mp.encode(@input)
    assert_equal @input, @mp.decode(encoded)
  end

  def test_decodes_multipass_with_class_method
    encoded = @mp.encode(@input)
    assert_equal @input, MultiPass.decode('example', 'abc', encoded)
  end

  def test_invalidates_bad_string
    assert_raises MultiPass::DecryptError do
      @mp.decode("abc")
    end
  end

  def test_invalidates_bad_json
    assert_raises MultiPass::JSONError do
      @mp.decode(@key.encrypt64("abc"))
    end
    assert_raises MultiPass::JSONError do
      @mp.decode(@key.encrypt64("{a"))
    end
  end

  def test_invalidates_old_expiration
    encrypted = @key.encrypt64(@input.merge(:expires => (Time.now - 1)).to_json)
    assert_raises MultiPass::ExpiredError do
      @mp.decode(encrypted)
    end
  end
end

class StandardMultiPassTest < Test::Unit::TestCase
  include MultiPassTests

  def setup
    @date   = Time.now + 1234
    @input  = {:expires => @date, :email => 'ricky@bobby.com'}
    @output = @input.merge(:expires => @input[:expires].to_s)
    @key    = EzCrypto::Key.with_password('example', 'abc')
    @mp     = MultiPass.new('example', 'abc', :url_safe => false)
  end
end

class UrlSafeMultiPassTest < Test::Unit::TestCase
  include MultiPassTests

  def setup
    @date   = Time.now + 1234
    @input  = {:expires => @date, :email => 'ricky@bobby.com'}
    @output = @input.merge(:expires => @input[:expires].to_s)
    @key    = EzCrypto::Key.with_password('example', 'abc')
    @mp     = MultiPass.new('example', 'abc', :url_safe => true)
  end
end

class ErrorTest < Test::Unit::TestCase
  def setup
    @key = EzCrypto::Key.with_password('example', 'abc')
    @mp  = MultiPass.new('example', 'abc')
  end

  def test_decrypt_error_stores_data
    begin
      @mp.decode 'abc'
    rescue MultiPass::DecryptError => e
      assert_equal 'abc', e.data
    end
  end

  def test_json_error_stores_data
    begin
      data = @key.encrypt64("abc")
      @mp.decode data
    rescue MultiPass::JSONError => e
      assert_equal data, e.data
    end
  end

  def test_json_error_stores_json
    begin
      data = @key.encrypt64("{a")
      @mp.decode data
    rescue MultiPass::JSONError => e
      assert_equal "{a", e.json
    end
  end

  def test_expiration_error_stores_data
    begin
      json = {:expires => Time.now - 5, :email => 'ricky@bobby.com'}.to_json
      data = @key.encrypt64(json)
      @mp.decode data
    rescue MultiPass::ExpiredError => e
      assert_equal data, e.data
    end
  end

  def test_expiration_error_stores_json
    begin
      json = {:expires => Time.now - 5, :email => 'ricky@bobby.com'}.to_json
      data = @key.encrypt64(json)
      @mp.decode data
    rescue MultiPass::ExpiredError => e
      assert_equal json, e.json
    end
  end

  def test_expiration_error_stores_options
    begin
      opt  = {:expires => (Time.now - 5).to_s, :email => 'ricky@bobby.com'}
      json = opt.to_json
      data = @key.encrypt64(json)
      @mp.decode data
    rescue MultiPass::ExpiredError => e
      assert_equal opt, e.options
    end
  end
end