class PaymentsController < ApplicationController

  protect_from_forgery except: [:alipay_notify]

  before_action :authenticate_user!, except: [:pay_notify]
  # before_action :auth_request, only: [:pay_return, :pay_notify]
  # before_action :find_and_validate_payment_no, only: [:pay_return, :pay_notify]


  def index
    @payment = current_user.payments.find_by(payment_no: params[:payment_no])
    @payment_url = build_payment_url
    @pay_options = build_request_options(@payment)
  end

  def pay_return
    do_payment_test
  end

  def pay_notify
    do_payment-test
  end

  def test

  end

  def success

  end

  def failed

  end

  def generate_pay
    @order = Order.find_by_token(params[:id])
    payment = Payment.create_from_orders!(current_user, @order)

    redirect_to payments_path(payment_no: payment.payment_no)
  end

  private
  def is_payment_success?
    !params[:pay_no].nil?
  end

  def do_payment_test
    redirect_to test_payments_path
  end

  def do_payment
    unless @payment.is_success? # 避免同步通知和异步通知多次调用
      if is_payment_success?
        @payment.do_success_payment! params
        redirect_to success_payments_path
      else
        @payment.do_failed_payment! params
        redirect_to failed_payments_path
      end
    else
     redirect_to success_payments_path
    end
  end

  def auth_request
  unless build_is_request_from_alipay?(params)
    Rails.logger.info "PAYMENT DEBUG NON ALIPAY REQUEST: #{params.to_hash}"
    redirect_to failed_payments_path
    return
  end

  unless build_is_request_sign_valid?(params)
    Rails.logger.info "PAYMENT DEBUG ALIPAY SIGN INVALID: #{params.to_hash}"
    redirect_to failed_payments_path
  end
end

def find_and_validate_payment_no
  @payment = Payment.find_by_payment_no params[:out_trade_no]
  unless @payment
    if is_payment_success?
      # TODO
      render text: "未找到支付单号，但是支付已经成功"
      return
    else
      render text: "未找到您的订单号，同时您的支付没有成功，请返回重新支付"
      return
    end
  end
end

def build_request_options payment
  # opts:
  #   service: create_direct_pay_by_user | mobile.securitypay.pay
  #   sign_type: MD5 | RSA
  pay_options = {
    "service" => 'create_direct_pay_by_user',
    "partner" => ENV['ALIPAY_PID'],
    "seller_id" => ENV['ALIPAY_PID'],
    "pay_type" => "1",
    "notify_url" => ENV['ALIPAY_NOTIFY_URL'],
    "return_url" => ENV['ALIPAY_RETURN_URL'],

    "anti_phishing_key" => "",
    "exter_invoke_ip" => "",
    "out_trade_no" => payment.payment_no,
    "subject" => "商店大赛加油站",
    "total_fee" => payment.total_money,
    "body" => "商店大赛加油站",
    "_input_charset" => "utf-8",
    "sign_type" => 'MD5',
    "sign" => ""
  }

  pay_options.merge!("sign" => build_generate_sign(pay_options))
  pay_options
end

def build_payment_url
  "#{ENV['ALIPAY_URL']}?_input_charset=utf-8"
end

def build_is_request_from_alipay? result_options
  return false if result_options[:notify_id].blank?

  body = RestClient.get ENV['ALIPAY_URL'] + "?" + {
    service: "notify_verify",
    partner: ENV['ALIPAY_PID'],
    notify_id: result_options[:notify_id]
  }.to_query

  body == "true"
end

def build_is_request_sign_valid? result_options
  options = result_options.to_hash
  options.extract!("controller", "action", "format")

  if options["sign_type"] == "MD5"
    options["sign"] == build_generate_sign(options)
  elsif options["sign_type"] == "RSA"
    build_rsa_verify?(build_sign_data(options.dup), options['sign'])
  end
end

def build_generate_sign options
  sign_data = build_sign_data(options.dup)

  if options["sign_type"] == "MD5"
    Digest::MD5.hexdigest(sign_data + ENV['ALIPAY_MD5_SECRET'])
  elsif options["sign_type"] == "RSA"
    build_rsa_sign(sign_data)
  end
end


  def build_sign_data data_hash
    data_hash.delete_if { |k, v| k == "sign_type" || k == "sign" || v.blank? }
    data_hash.to_a.map { |x| x.join('=') }.sort.join('&')
  end









end
