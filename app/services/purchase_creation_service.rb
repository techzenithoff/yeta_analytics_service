class PurchaseCreationService
  def initialize(purchase_params)
    @purchase_params = purchase_params
  end

  def call
    ActiveRecord::Base.transaction do
      create_purchase_with_items
      create_invoice_and_items
      @purchase
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Erreur lors de la création du purchase et invoice : #{e.message}")
    raise e
  end

  private

  def create_purchase_with_items
    @purchase = Purchase.create!(@purchase_params)
    # Les purchase_items sont déjà créés grâce à accepts_nested_attributes_for
  end

  def create_invoice_and_items
    @invoice = Invoice.create!(
      payment_method_id: @purchase.payment_method_id,
      total_excl_tax: @purchase.total_excl_tax,
      tax_rate: @purchase.tax_rate,
      tax_amount: @purchase.tax_amount,
      total_incl_tax: @purchase.total_incl_tax,
      account_id: @purchase.account_id
    )

    @purchase.purchase_items.each do |item|
      InvoiceItem.create!(
        invoice_id: @invoice.id,
        purchasable_type: item.purchasable_type,
        purchasable_id: item.purchasable_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        amount: item.amount
      )
    end
  end
end
