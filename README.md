SpreeVatFix
===========

Spree's VAT handling (out of the box) is lacking in the following ways

- only one rate is taken, others are ignored
- default tax rate is not used
- there is no option to include shipment in the tax calculation
- coupons (and consecutive tax reductions) are not handled
- rate matching is done by billing, not shipping address

This extension tries to fix at least several if not all of these problems 

It does this by :

- providing a Calculator::VAT implementation and  
- overriding tax adjustment creation in Order
- adding taxes to shipment if vat is not included in prices (ie :show_price_inc_vat == false)

Contribute!
=======

This is a work in progress (for spree 0.3/4 ) and if you have any contributions, please mail or send diffs.

If you are willing to help more/longer I will add you to the project list. 

Extras
=====

This extension also adds an option to use running order numbers (as required in some countries).
Set :running_order_numbers in Spree::Config

As an aside, I have added the description of the tax category as the Adjustments label. So these show up in the summary and printouts (spree-print-invoice ext.) So where it used to say Tax (or whatever, you must now set your descriptions and will possibly get several)

State
======

- several vat categories in an order WORKS
- vat applied to shipping by default tax WORKS (if  :show_price_inc_vat == false)
- using default category WORKS 
- running Order numbers WORK

All tested with  :show_price_inc_vat => false so 

- Preview box / Cart link / cart summary NOT done for show_price_inc_vat => true
- Coupons NOT done

NO TESTS  - This is strictly "works for me" software, use at own risk and/or contribute tests

Copyright (c) 2011 [Torsten Rüger], released under the New BSD License
