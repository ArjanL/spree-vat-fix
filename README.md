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
- giving you product price incl vat on the product screen (no more adjusing it automatically)

Contribute!
=======

This is a work in progress and if you have any contributions, please mail or send diffs.
At the moment used with 0.6 and in the process of upgrading with 0.7

Extras
=====

This extension also adds an option to use running order numbers (as required in some countries).
Set :running_order_numbers in Spree::Config

As an aside, I have added the description of the tax category as the Adjustments label. So these show up in the summary and printouts (spree-html-invoice ext.) So where it used to say Tax (or whatever, you must now set your descriptions and will possibly get several)

The unattainable Price
=======================

Due to the way spree works some prices (incl vat) are not achievable. This is because Product.price is stored with only 2 digits in the database.

So with any tax rate there are prices where the tax-in price jumps 2 cent for a one cent increase in price. Sometimes that means you just can't have 9.99 (or 9.95) or where-ever it hits you. Don't despair and just choose another price.

This _could_ be fixed off course, but it's too big for me (ie it doesn't matter that much). Spree chooses to store pre-tax prices with 2 digits. So That's how it is: go to the list if you really feel you have to. 

Status
======

- several vat categories in an order WORKS
- vat applied to shipping by default tax WORKS (if  :show_price_inc_vat == false)
- in fact (default) tax is applied to all non-tax adjustments
- using default category WORKS 
- running Order numbers WORK
- fixed some rounding issues 
 
All tested with  :show_price_inc_vat => false so 

- Preview box / Cart link / cart summary PARTLY done for show_price_inc_vat => true

NO TESTS  - This is strictly "works for me" software, use at own risk and/or contribute tests

Copyright (c) 2011 [Torsten Rüger], released under the New BSD License
