TaxRate.class_eval do 
  def is_default?
    self.tax_category.is_default
  end
end

Calculator::Vat.class_eval do


  # list the vat rates for the default country
  def self.default_rates
    origin = Country.find(Spree::Config[:default_country_id])
    calcs = Calculator::Vat.find(:all, :include => {:calculable => :zone}).select {
      |vat| vat.calculable.zone.country_list.include?(origin)
    }
    puts "DEFAULT RATES #{calcs.collect { |calc| calc.calculable }.join(' ')}"
    calcs.collect { |calc| calc.calculable }
  end

  def self.calculate_tax(order)
    puts "RATES are #{rates} , HACK is #{cache_hack}"
    taxable_totals = {}
    order.line_items.each do |line_item|
      puts "For #{line_item.variant}" 
      puts "No category" unless line_item.variant.product.tax_category
      # TODO, should use default tax category if none set
      next unless tax_category = line_item.variant.product.tax_category
      taxable_totals[tax_category] ||= 0
      puts "CALCULATE TAX for #{line_item.price} is #{ (line_item.price * rate.amount).round(2, BigDecimal::ROUND_HALF_UP)}"
      taxable_totals[tax_category] += (line_item.price * rate.amount).round(2, BigDecimal::ROUND_HALF_UP) * line_item.quantity
    end

    return 0 if taxable_totals.empty?
    tax = 0
    taxable_totals.values.each do |total|
      tax += total
    end
    tax
  end

  def self.calculate_tax_on(product_or_variant)
    vat_rates = default_rates
    product = product_or_variant.is_a?(Product) ? product_or_variant : product_or_variant.product
    puts "TAX ON RATES #{vat_rates}"
    return 0 if vat_rates.nil?
    return 0 unless tax_category = product.tax_category
    # TODO finds first (or any?) rate. Should check default category first
    return 0 unless rate = vat_rates.find { | vat_rate | vat_rate.tax_category_id == tax_category.id }
    puts "CALCULATE TAX ON #{product_or_variant.price}  #{product_or_variant.price * rate.amount}"
    (product_or_variant.price * rate.amount).round(2, BigDecimal::ROUND_HALF_UP)
  end

  # computes vat for line_items associated with order, and tax rate and now coupon discounts are taken into account in tax calcs
  def compute(order)
    debug = false
    rate = self.calculable
    puts "SELF RATE IS #{rate.amount}" if debug
    #TODO coupons
    #coupon_total = order.coupon_credits.map(&:amount).sum * rate.amount
    if rate.tax_category.is_default and not order.shipments.empty? and !Spree::Config[ :show_price_inc_vat]
      tax = (order.shipments.map(&:cost).sum) * rate.amount 
    end
    tax = 0 unless tax
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
