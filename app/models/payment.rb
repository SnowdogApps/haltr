class Payment < ActiveRecord::Base

  unloadable

  belongs_to :invoice
  belongs_to :project
  validates_numericality_of :amount_in_cents, :greater_than => 0

  after_save :save_invoice, :if => Proc.new {|payment| payment.invoice.is_a? InvoiceDocument }
  after_destroy :save_invoice, :if => Proc.new {|payment| payment.invoice.is_a? InvoiceDocument }

  before_save :guess_invoice, :unless => :invoice

  def initialize(attributes=nil)
    super
    self.date ||= Date.today
  end

  def description
    desc = ""
    desc += "#{self.payment_method} - " unless self.payment_method.nil? or self.payment_method.blank?
    desc += self.reference
  end

  def save_invoice
    invoice.save
  end

  def guess_invoice
    candidates = InvoiceDocument.candidates_for_payment self
    self.invoice = candidates.first if candidates
  end

end