require 'time'
require 'erb'

module SUSE
  module Connect
    # The System Status object provides information about the state of currently installed products
    # and subscriptions as known by registration server.
    # At first it collects all installed products from the system, then it gets its `activations`
    # from the registration server. This information is merged and printed out.
    # rubocop:disable ClassLength
    class Status
      attr_reader :client

      def initialize(config)
        @client = Client.new(config)
      end

      def activated_products
        @activated_products ||= products_from_activations
      end

      def installed_products
        @installed_products ||= products_from_zypper
      end

      def activations
        @known_activations ||= activations_from_server
      end

      # Checks if system activations includes base product
      def activated_base_product?
        System.credentials? && activated_products.include?(Zypper.base_product)
      end

      def print_extensions_list
        file = File.read File.join(File.dirname(__FILE__), 'templates/extensions_list.text.erb')
        template = ERB.new(file, 0, '-<>')
        puts template.result(binding).gsub('\e', "\e")
      end

      # Gather all extensions that can be installed on this system
      def available_system_extensions
        base = @client.show_product(Zypper.base_product)
        extract_extensions(base)
      end

      def print_product_statuses(format = :text)
        case format
        when :text
          status_output = text_product_status
        when :json
          status_output = json_product_status
        else
          raise UnsupportedStatusFormat, "Unsupported output format '#{format}'"
        end
        puts status_output
      end

      def system_products
        products = installed_products + activated_products
        products.map {|product| Product.transform(product) }.uniq
      end

      def current_registration_status
        product_statuses.each do |product_status|
          return product_status.registration_status
        end
      end

      private

      def extract_extensions(product)
        extensions = []
        product.extensions.each do |extension|
          # Skip products which have `available: false` set by SMT.
          next if extension.available == false
          extensions << {
            activation_code: build_product_activation_code(extension),
            name: extension.friendly_name,
            free: extension.free,
            extensions: extract_extensions(extension)
          }
        end if product.extensions
        extensions
      end

      def grouped_extensions
        @grouped_extensions ||= available_system_extensions.group_by {|ext| ext[:free] }
      end

      def build_product_activation_code(product)
        "#{product.identifier}/#{product.version}/#{product.arch}"
      end

      def text_product_status
        file = File.read File.join(File.dirname(__FILE__), 'templates/product_statuses.text.erb')
        template = ERB.new(file, 0, '-<>')
        template.result(binding)
      end

      # rubocop:disable MethodLength
      def json_product_status
        statuses = product_statuses.map do |product_status|
          status = {}
          status[:identifier] = product_status.installed_product.identifier
          status[:version] = product_status.installed_product.version
          status[:arch] = product_status.installed_product.arch
          status[:status] = product_status.registration_status

          unless product_status.remote_product && product_status.remote_product.free
            if product_status.related_activation
              activation = product_status.related_activation
              status[:regcode] = activation.regcode
              status[:starts_at] = activation.starts_at ? Time.parse(activation.starts_at) : nil
              status[:expires_at] = activation.expires_at ? Time.parse(activation.expires_at) : nil
              status[:subscription_status] = activation.status
              status[:type] = activation.type
            end
          end
          status
        end

        statuses.to_json
      end

      def activations_from_server
        system_activations.map {|s| Remote::Activation.new(s) }
      end

      def products_from_activations
        system_activations.map {|p| Remote::Product.new(p['service']['product']) }
      end

      def products_from_zypper
        Zypper.installed_products
      end

      def product_statuses
        installed_products.map {|p| Zypper::ProductStatus.new(p, self) }
      end

      def system_activations
        return [] unless SUSE::Connect::System.credentials?
        @system_activations ||= @client.system_activations.body
      end
    end
  end
end
