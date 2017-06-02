class PaymentsController < ApplicationController

  protect_from_forgery except: [:pay_return, :pay_notify]

  before_action :require_login, except: [:pay_return, :pay_notify]
  before_action :auth_request, only: [:pay_return, :pay_notify]
  before_action :find_and_validate_payment_no, only: [:pay_return, :pay_notify]


  def index
    @order = current_user.orders.find_by_token(params[:order_token])
    @payment = current_user.payments.find_by(payment_no: params[:payment_no])
    if @order.present? && @payment.present? && @order.payment = @payment
      a = 1
    elsif @order.is_paid?
      redirect_to root_path, warning: "该订单已支付！"
    else
      redirect_to root_path, alert: "该订单或支付号不存在，请重新下单~！"
    end

  end

  def create_payment
    binding.pry
    payment = current_user.payments.find_by(payment_no: params[:payment_no])

    if payment.present? && payment.status == "initial"

      pay_options = {
        "service" => 'create_direct_pay_by_user',
        "partner" => ENV['ALIPAY_PID'],
        "seller_id" => ENV['ALIPAY_PID'],
        "payment_type" => "1",
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
        "sign" => "",
        "page" => "3"
      }
      pay_options.merge!("sign" => build_generate_sign(pay_options))


      body = RestClient.get ENV['ALIPAY_URL'] + "?" + pay_options.to_query

      pay_qr = JSON.parse(body)["qr"]
      order_id = JSON.parse(body)["order_id"]
      @qr = RQRCode::QRCode.new(pay_qr, :size => 6, :level => :h )


        render :json => { :test7 => '<%= rucaptcha_image_tag %>', :qrcode => @qr.as_html, :order_id => order_id, :status => "ok", payment_no: payment.payment_no, price: payment.total_money }

    else
      render :json => { :status => "支付号已支付或不存在，请重新生成支付" }

    end
  end

  def get_payment_status
    body2 = RestClient.get "http://codepay.fateqq.com:52888/ispay?" + {
      id: ENV['ALIPAY_PID'],
      order_id: @raw_order,
      token: "xJgDafGbnCJRiCaDFt9YFcjhq4Qb6NEp"
    }.to_query
    order_status = JSON.parse(body2)["status"]
  end


  def pay_return
    do_payment_test
  end

  def pay_notify
    do_payment_test
    render :json => "ok"
  end

  def test
    body2 = RestClient.get "http://codepay.fateqq.com:52888/ispay?" + {
      id: ENV['ALIPAY_PID'],
      order_id: params[:order],
      token: "xJgDafGbnCJRiCaDFt9YFcjhq4Qb6NEp",
      call: ""
    }.to_query
    order_status = JSON.parse(body2)["status"]

    render :json => { :liang => order_status }
  end

  def success

  end

  def failed

  end

  def lesson_generat_pay
    order = current_user.orders.find_by_token(params[:id])

    payment = Payment.new
      payment.total_money = order.total
      payment.user = current_user
      payment.save!

      if payment.save
      if order.is_paid?
        redirect_to order_path(order.token), alert: "该订单已支付！"
      else
        order.payment = payment
        order.save!
      end
      end

    redirect_to create_payment_payment_path(payment_no: payment.payment_no, id: payment.id)
  end

  def generate_pay
    @order = current_user.orders.find_by_token(params[:id])

    payment = Payment.new
      payment.total_money = @order.total
      payment.user = current_user
      payment.save!

      if payment.save
      if @order.is_paid?
        redirect_to order_path(@order.token), alert: "该订单已支付！"
      else
        @order.payment = payment
        @order.save!
      end
      end

    redirect_to payments_path(payment_no: payment.payment_no, order_token: @order.token)
  end

  private
  def is_payment_success?
    !params[:pay_no].nil?
  end

  def update_status
    @payment = Payment.find_by_payment_no(params[:pay_id])
    redirect_to root_path
  end

  def do_payment_test
    @payment = Payment.find_by_payment_no(params[:pay_id])
    unless @payment.is_success? # 避免同步通知和异步通知多次调用
      if is_payment_success?
        @payment.do_success_payment! params
      else
        @payment.do_failed_payment! params
      end
    end
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
    "payment_type" => "1",
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
    "sign" => "",
    "page" => "3"
  }

  pay_options.merge!("sign" => build_generate_sign(pay_options))
  pay_options
end

def build_payment_url
  "#{ENV['ALIPAY_URL']}?_input_charset=utf-8"
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
