TaxRate.class_eval do 
  def is_default?
    self.tax_category.is_default
  end
end
Admin::ProductsController.class_eval do 
  after_filter :fix_vat, :only => :update
  
  def fix_vat
    return unless Spree::Config[:show_price_inc_vat]
    return unless params[:product]
    return unless price = params[:product][:price]
    product = Product.find_by_permalink params[:id]
    #puts "Product price = #{product.price}"
    rate = Calculator::Vat.default_rates.first
    return unless rate
    new_price = price.to_d / ( 1 + rate.amount )
    #puts "Adjusting price #{price} to #{new_price}"
    product.price = new_price.to_s
  end
  
end


Calculator::Vat.class_eval do


  # list the vat rates for the default country
  def self.default_rates
    origin = Country.find(Spree::Config[:default_country_id])
    calcs = Calculator::Vat.find(:all, :include => {:calculable => :zone}).select {
      |vat| vat.calculable.zone.country_list.include?(origin)
    }
    puts "DEFAULT RATES #{calcs.collect { |calc| calc.calculable.amount }.join(' ')}"
    calcs.collect { |calc| calc.calculable }
  end

  # list the vat rates for the default country
  def self.default_rates
    origin = Country.find(Spree::Config[:default_country_id])
    calcs = Calculator::Vat.find(:all, :include => {:calculable => :zone}).select {
      |vat| vat.calculable.zone.country_list.include?(origin)
    }
    puts "DEFAULT RATES #{calcs.collect { |calc| calc.calculable.amount }.join(' ')}"
    calcs.collect { |calc| calc.calculable }
  end

  # Called by BaseHelper.order_price to determine the tax, before address is known. While off course possibly incorrct,
  # default assumtion leads to correct value in 90 ish % of cases or more.  
  def self.calculate_tax(order)
    rates = default_rates
    tax = 0
    order.line_items.each do |line_item|
      variant = line_item.variant
      tax += calculate_tax_on(variant , rates)
    end
    tax
  end

  # called when showing a product on the consumer side (check ProductsHelper)
  def self.calculate_tax_on(product_or_variant , vat_rates = default_rates )
    return 0 if vat_rates.nil?  # uups, configuration error
    product = product_or_variant.is_a?(Product) ? product_or_variant : product_or_variant.product
    return 0 unless tax_category = product.tax_category #TODOD Should check default category first
    # TODO finds first (or any?) rate. 
    return 0 unless rate = vat_rates.find { | vat_rate | vat_rate.tax_category_id == tax_category.id }
    puts "CALCULATE TAX ON #{product_or_variant.price}  RATE#{ rate.amount}"
    (product_or_variant.price * rate.amount).round(2, BigDecimal::ROUND_HALF_UP)
  end

  # computes vat for line_items associated with order, and tax rate and now coupon discounts are taken into account in tax calcs
  def compute(order)
    debug = true
    rate = self.calculable
    puts "#{rate.id} RATE IS #{rate.amount}" if debug
    tax = 0
    if rate.tax_category.is_default and !Spree::Config[ :show_price_inc_vat]
      order.adjustments.each do | adjust |
        next if adjust.originator_type == "TaxRate"
        add = adjust.amount * rate.amount
        puts "Applying default rate to adjustment #{adjust.label} (#{adjust.originator_type} ), sum = #{add}"
        tax += add
      end
    end
    order.line_items.each do  | line_item|
      if line_item.product.tax_category  #only apply this calculator to products assigned this rates category
        next unless line_item.product.tax_category == rate.tax_category
      else
        next unless is_default? # and apply to products with no category, if this is the default rate
        #TODO: though it would be a user error, there may be several rates for the default category
        #      and these would be added up by this. 
      end
      next unless line_item.product.tax_category.tax_rates.include? rate
      puts "COMPUTE for #{line_item.price} is #{ line_item.price * rate.amount} RATE IS #{rate.amount}" if debug
      tax += (line_item.price * rate.amount) * line_item.quantity
    end
    tax
  end

end
