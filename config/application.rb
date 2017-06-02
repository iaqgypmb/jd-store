require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

ENV['ALIPAY_PID'] = '10469'
ENV['ALIPAY_MD5_SECRET'] = '34NrkS8OWTNGiQize4Ng9Ag5nqQoqKxJ'
ENV['ALIPAY_URL'] = 'https://codepay.fateqq.com:51888/creat_order/'
ENV['ALIPAY_RETURN_URL'] = 'https://shrouded-reef-16391.herokuapp.com/payments/pay_return'
ENV['ALIPAY_NOTIFY_URL'] = 'https://shrouded-reef-16391.herokuapp.com/payments/pay_notify'


module Jdstore
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.assets.precompile += [ Proc.new { |path| File.basename(path) =~ /^[^_].*\.\w+$/ } ]
  end
end

OURAK_CONFIG = Rails.application.config_for(:our)
