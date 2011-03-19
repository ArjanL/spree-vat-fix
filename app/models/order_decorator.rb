Order.class_eval do


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
    matching_rates = TaxRate.all.select { |rate| rate.zone.include?(ship_address) }

    adjustments.where(:originator_type => "TaxRate").each do |old_charge|
      old_charge.destroy
    end
    matching_rates.each do |rate|
      #puts "Creating rate #{rate.amount}" 
      rate.create_adjustment( rate.tax_category.description , self, self, true)
    end
  end
end
