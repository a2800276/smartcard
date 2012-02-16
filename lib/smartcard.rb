unless ENV["TEST_NO_CARD"]
  require 'smartcard/pcsc'
else
  require 'smartcard/pcsc_mock'
end

require 'smartcard/pcsc_card'
require 'smartcard/pcsc_context'
