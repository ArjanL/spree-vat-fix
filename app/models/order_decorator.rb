Order.class_eval do

  after_create :create_tax_charge!
  
  alias original_generate_order_number generate_order_number 

  def generate_order_number
    return original_generate_order_number unless Spree::Config[:running_order_numbers]
    year = Time.now.year
    if last = Order.last
      num = last.number[5..9].to_i + 1
    else
      num = 30000
    end
    self.number = "R#{year}#{num}"
  end

  #small fix, as the scope by label doesn't always work
  def tax_total
    adjustments.where(:originator_type => "TaxRate").map(&:amount).sum
  end


  # create tax rate adjustments (note plural) that apply to the shipping address (not like billing in original).
  # removes any previous Tax - Adjustments (in case the address changed). Could probably be optimised (later)
  def create_tax_charge!
    #puts "Adjustments #{adjustments} TAX #{tax_total}"
    #puts "CREATE TAX for #{ship_address}  "
    all_rates = TaxRate.all
    matching_rates = all_rates.select { |rate| rate.zone.include?(ship_address) }
    if matching_rates.empty?
      matching_rates = all_rates.select{|rate| # get all rates that apply to default country 
          rate.zone.country_list.collect{|c| c.id}.include?(Spree::Config[:default_country_id])
        }
    end
    adjustments.where(:originator_type => "TaxRate").each do |old_charge|
      old_charge.destroy
    end
    matching_rates.each do |rate|
      #puts "Creating rate #{rate.amount}" 
      rate.create_adjustment( rate.tax_category.description , self, self, true)
    end
  end
end

Admin::ProductsHelper.module_eval do
  # returns the price of the product to show for display purposes
  def product_price(product_or_variant, options={})
    options.assert_valid_keys(:format_as_currency, :show_vat_text)
    options.reverse_merge! :format_as_currency => true, :show_vat_text => Spree::Config[:show_price_inc_vat]

    amount = product_or_variant.price
    amount += Calculator::Vat.calculate_tax_on(product_or_variant) if Spree::Config[:show_price_inc_vat]
    options.delete(:format_as_currency) ? format_price(amount, options) : amount
  end
end
