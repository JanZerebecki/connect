# Collect hardware information for s390x systems
class SUSE::Connect::HwInfo::S390 < SUSE::Connect::HwInfo::Base
  class << self
    def hwinfo
      {
        hostname: hostname,
        cpus: cpus,
        sockets: sockets,
        hypervisor: hypervisor,
        arch: arch,
        uuid: uuid,
        cloud_provider: cloud_provider
      }
    end

    def cpus
      cpus = output['VM00 CPUs Total'] || output['LPAR CPUs Total']
      cpus.to_s.strip.to_i
    end

    def sockets
      sockets = output['VM00 IFLs'] || output['LPAR CPUs IFL']
      sockets.to_s.strip.to_i
    end

    def hypervisor
      if output['VM00 Control Program']
        # Strip and remove recurring whitespaces e.g. " z/VM    6.1.0" => "z/VM 6.1.0"
        output['VM00 Control Program'].strip.gsub(/\s+/, ' ')
      else
        log.debug("Unable to find 'VM00 Control Program'. This system probably runs on an LPAR.")
        nil
      end
    end

    def uuid
      read_values = execute('read_values -u', false)
      uuid = read_values.empty? ? nil : read_values

      log.debug("Not implemented. Unable to determine UUID for #{arch}. Set to nil") unless uuid
      uuid
    end

    private

    def output
      @output ||= Hash[execute('read_values -s', false).split("\n").map { |line| line.split(':') }]
    end
  end
end
