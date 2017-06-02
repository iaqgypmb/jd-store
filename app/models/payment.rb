class Payment < ApplicationRecord
  before_create :gen_payment_no

  module PaymentStatus
    Initial = 'initial'
    Success = 'success'
    Failed = 'failed'
  end

  belongs_to :user
  has_many :orders

  def is_success?
    self.status == "success"
  end

  def do_success_payment! params
    self.transaction do
      self.transaction_no = params[:pay_no]
      self.status = Payment::PaymentStatus::Success
      self.raw_response = params.to_json
      self.payment_at = Time.now
      self.save!

      # 更新订单状态
      self.orders.each do |order|
        if order.is_paid?
          raise "order #{order.order_no} has alreay been paid"
        end

        order.status = Order::OrderStatus::Paid

        if !order.of_lesson?
          order.payment_at = Time.now
          order.make_payment!
          order.is_paid = true
          order.payment_method = "alipay"
          order.save!

          order.product_lists.each do |product_list|
            product = Product.find(product_list.product_id)
            product.sales_count += 1
            product.save!
          end
        end


        if order.of_lesson?
          buyer = Buyer.new
          buyer.user_id = current_user.id
          buyer.lesson_id = order.lesson_id
          buyer.save!
        end

      end
    end
  end

  def do_failed_payment! params
    self.transaction_no = params[:pay_no]
    self.status = Payment::PaymentStatus::Failed
    self.raw_response = params.to_json
    self.payment_at = Time.now
    self.save!
  end

  def self.create_from_orders! user, order

    payment = nil
    transaction do
      payment = user.payments.create!(
      total_money: order.total,
    )

      if order.is_paid?
          raise "order #{order.order_no} has alreay been paid"
      end
      order.payment_id = payment
      binding.pry
      order.save!

    end
    payment
  end

  private

  def gen_payment_no
    self.payment_no = generate_utoken(32)
  end

  def generate_utoken len = 8
    a = lambda { rand(36).to_s(36) }
    token = ""
    len.times { |t| token << a.call.to_s }
    token
  end
end
