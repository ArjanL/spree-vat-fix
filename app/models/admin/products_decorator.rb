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

Admin::ProductsController.class_eval do
  before_filter :vat_fix , :only => :update
  
  def vat_fix
    return unless params[:price_includes_vat]
    taxid = params[:product][:tax_category_id]
    rate = TaxRate.find( taxid ) if taxid
    rate = Calculator::Vat.default_rates.first unless rate
    rate = TaxRate.first unless rate
    price = params[:product][:price].to_f
    price = price / (1 + rate.amount)
    puts "Adjusted price by #{rate.amount} to #{price} (was #{params[:product][:price]})"
    params[:product][:price] = price
  end
end