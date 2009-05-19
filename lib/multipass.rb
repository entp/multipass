require 'active_support'
require 'ezcrypto'

class MultiPass
  class Invalid      < StandardError; end
  class ExpiredError < Invalid;       end
  class JSONError    < Invalid;       end
  class DecryptError < Invalid;       end

  def self.encode(site_key, api_key, options = {})
    new(site_key, api_key).encode(options)
  end

  def self.decode(site_key, api_key, data)
    new(site_key, api_key).decode(data)
  end

  def initialize(site_key, api_key)
    @site_key   = site_key
    @api_key    = api_key
    @crypto_key = EzCrypto::Key.with_password(@site_key, @api_key)
  end

  # Encrypts the given hash into a multipass string.
  def encode(options = {})
    options[:expires] = case options[:expires]
      when Fixnum               then Time.at(options[:expires]).to_s(:db)
      when Time, DateTime, Date then options[:expires].to_s(:db)
      else options[:expires].to_s
    end
    @crypto_key.encrypt64(options.to_json)
  end

  # Decrypts the given multipass string and parses it as JSON.  Then, it checks
  # for a valid expiration date.
  def decode(data)
    json = @crypto_key.decrypt64(data)
    
    if json.nil?
      raise MultiPass::DecryptError
    end

    options = ActiveSupport::JSON.decode(json)
    
    if !options.is_a?(Hash)
      raise MultiPass::JSONError
    end

    options.symbolize_keys!

    if options[:expires].blank? || Time.now.utc > Time.parse(options[:expires])
      raise MultiPass::ExpiredError
    end

    options
  rescue ActiveSupport::JSON::ParseError
    raise MultiPass::JSONError
  end
end