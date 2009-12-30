require 'time'

class MultiPass
  class Invalid < StandardError
    @@message = "The MultiPass token is invalid."

    def message
      @@message
    end

    alias to_s message
  end

  class ExpiredError < Invalid
    @@message = "The MultiPass token has expired."
  end
  class JSONError < Invalid
    @@message = "The decrypted MultiPass token is not valid JSON."
  end
  class DecryptError < Invalid
    @@message = "The MultiPass token was not able to be decrypted."
  end

  def self.encode(site_key, api_key, options = {})
    new(site_key, api_key).encode(options)
  end

  def self.decode(site_key, api_key, data)
    new(site_key, api_key).decode(data)
  end

  def initialize(site_key, api_key)
    @site_key   = site_key
    @api_key    = api_key
    if !Object.const_defined?(:EzCrypto)
      require 'ezcrypto'
    end
    @crypto_key = EzCrypto::Key.with_password(@site_key, @api_key)
  end

  # Encrypts the given hash into a multipass string.
  def encode(options = {})
    options[:expires] = case options[:expires]
      when Fixnum               then Time.at(options[:expires]).to_s
      when Time, DateTime, Date then options[:expires].to_s
      else options[:expires].to_s
    end
    encode_64 @crypto_key.encrypt(options.to_json)
  end

  # Decrypts the given multipass string and parses it as JSON.  Then, it checks
  # for a valid expiration date.
  def decode(data)
    json = @crypto_key.decrypt(decode_64(data))
    
    if json.nil?
      raise MultiPass::DecryptError
    end

    options = decode_json(json)
    
    if !options.is_a?(Hash)
      raise MultiPass::JSONError
    end

    options.keys.each do |key|
      options[key.to_sym] = options.delete(key)
    end

    if options[:expires].nil? || Time.now.utc > Time.parse(options[:expires])
      raise MultiPass::ExpiredError
    end

    options
  rescue OpenSSL::CipherError
    raise MultiPass::DecryptError
  end

  if Object.const_defined?(:ActiveSupport)
    include ActiveSupport::Base64
  else
    require 'base64'
  end

  def encode_64(s)
    b = Base64.encode64(s)
    b.gsub! /\n/, ''
    b
  end

  def decode_64(s)
    Base64.decode64(s)
  end

  if Object.const_defined?(:ActiveSupport)
    def decode_json(s)
      ActiveSupport::JSON.decode(s)
    rescue ActiveSupport::JSON::ParseError
      raise MultiPass::JSONError
    end
  else
    require 'json'
    def decode_json(s)
      JSON.parse(s)
    rescue JSON::ParserError
      raise MultiPass::JSONError
    end
  end
end