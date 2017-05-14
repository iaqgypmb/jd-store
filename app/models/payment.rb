class Payment < ApplicationRecord
  before_create :gen_payment_no

  module PaymentStatus
    Initial = 'initial'
    Success = 'success'
    Failed = 'failed'
  end

  belongs_to :user
  has_many :orders

  private

  def gen_payment_no
    self.payment_no = RandomCode.generate_utoken(32)
  end

  def generate_utoken len = 8
    a = lambda { rand(36).to_s(36) }
    token = ""
    len.times { |t| token << a.call.to_s }
    token
  end
end
