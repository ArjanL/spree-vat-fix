class Calculator::Vat < Calculator

  def self.description
    I18n.t("vat")
  end

  def self.register
    super
    TaxRate.register_calculator(self)
  end

  # list the vat rates for the default country
  def self.default_rates
    origin = Country.find(Spree::Config[:default_country_id])
    calcs = Calculator::Vat.find(:all, :include => {:calculable => :zone}).select {
      |vat| vat.calculable.zone.country_list.include?(origin)
    }
    puts "DEFAULT RATES #{calcs.collect { |calc| calc.calculable }.join(' ')}"
    calcs.collect { |calc| calc.calculable }
  end

  def self.calculate_tax(order, rates=default_rates)
    puts "NO RATES, returning"
    return 0 if rates.empty?
    # note: there is a bug with associations in rails 2.1 model caching so we're using this hack
    # (see http://rails.lighthouseapp.com/projects/8994/tickets/785-caching-models-fails-in-development)
    cache_hack = rates.first.respond_to?(:tax_category_id)
    puts "RATES are #{rates} , HACK is #{cache_hack}"
    taxable_totals = {}
    order.line_items.each do |line_item|
      puts "For #{line_item.variant}" 
      puts "No category" unless line_item.variant.product.tax_category
      next unless tax_category = line_item.variant.product.tax_category
      puts "No rate with hack "
      next unless rate = rates.find { | vat_rate | vat_rate.tax_category_id == tax_category.id } if cache_hack
      puts "No rate without hack "
      next unless rate = rates.find { | vat_rate | vat_rate.tax_category == tax_category } unless cache_hack
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

    return 0 if vat_rates.nil?
    return 0 unless tax_category = product_or_variant.is_a?(Product) ? product_or_variant.tax_category : product_or_variant.product.tax_category
    return 0 unless rate = vat_rates.find { | vat_rate | vat_rate.tax_category_id == tax_category.id }
    puts "CALCULATE TAX ON#{product_or_variant.price}  #{product_or_variant.price * rate.amount}"
    (product_or_variant.price * rate.amount).round(2, BigDecimal::ROUND_HALF_UP)
  end

  # computes vat for line_items associated with order, and tax rate and now coupon discounts are taken into account in tax calcs
  def compute(order)
    rate = self.calculable
    puts "SELF RATE IS #{rate.amount}"
    line_items = order.line_items.select { |i| i.product.tax_category == rate.tax_category }
    puts "Apllicable items #{line_items.count}"
    #coupon_total = order.coupon_credits.map(&:amount).sum * rate.amount
    shipping_charge_total = order.shipments.map(&:cost).sum * rate.amount
    line_items.inject(shipping_charge_total) {|sum, line_item|
    #  rate = line_item.product.tax_category.tax_rates.first
      puts "USING RATE #{rate}"
      next unless rate
      puts "RATE IS #{rate.amount}"
      puts "COMPUTE for #{line_item.price} is #{ (line_item.price * rate.amount).round(2, BigDecimal::ROUND_HALF_UP)}"
      sum += (line_item.price * rate.amount) * line_item.quantity
    }
  end

end
