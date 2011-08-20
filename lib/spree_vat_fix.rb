module SpreeVatFix
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
class Hooks < Spree::ThemeSupport::HookListener
  insert_before :admin_product_form_right do 
    "Price incl vat <%=product_price(@product)%>"
  end
end
