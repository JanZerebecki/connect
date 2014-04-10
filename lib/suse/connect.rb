module SUSE
  # All modules and classes of Connected nested
  module Connect

    UUIDFILE                = '/sys/class/dmi/id/product_uuid'
    UUIDGEN_LOCATION        = '/usr/bin/uuidgen'

    require 'suse/connect/version'
    require 'suse/connect/logger'
    require 'suse/connect/errors'
    require 'suse/connect/client'
    require 'suse/connect/system'
    require 'suse/connect/product'
    require 'suse/connect/zypper'
    require 'suse/connect/service'
    require 'suse/connect/source'
    require 'suse/connect/connection'
    require 'suse/connect/credentials'
    require 'suse/connect/api'
    require 'suse/connect/yast'

  end
end
