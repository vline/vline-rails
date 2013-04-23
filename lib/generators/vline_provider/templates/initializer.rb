require 'vline'

Vline.setup do |config|

  config.service_id = '<%= options.service_id %>'
  config.provider_id = '<%= options.service_id %>'
  config.client_id = '<%= options.client_id %>'

  # WARNING: Do not check these values into VCS!
  config.client_secret = '<%= options.client_secret %>'
  config.provider_secret = '<%= options.provider_secret %>'
end
