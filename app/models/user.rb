class User < ApplicationRecord
  has_many :orders
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  attr_accessor :login, :password, :password_confirmation, :token

  CELLPHONE_RE = /\A(\+86|86)?1\d{10}\z/
  EMAIL_RE = /\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/

  validate :validate_email_or_cellphone, on: :create

  def admin?
    is_admin
  end

  private

  # TODO
  # 需要添加邮箱和手机号不能重复的校验
  def validate_email_or_cellphone
    if [self.email, self.cellphone].all? { |attr| attr.nil? }
        self.errors.add :base, "邮箱和手机号其中之一不能为空"
        return false
    else
        if self.cellphone.nil?
            if self.email.blank?
              self.errors.add :email, "邮箱不能为空"
              return false
            else
              unless self.email =~ EMAIL_RE
                self.errors.add :email, "邮箱格式不正确"
                return false
              end
            end
        else
            unless self.cellphone =~ CELLPHONE_RE
              self.errors.add :cellphone, "手机号格式不正确"
              return false
            end

            unless VerifyToken.available.find_by(cellphone: self.cellphone, token: self.token)
              self.errors.add :cellphone, "手机验证码不正确或者已过期"
              return false
            end
         end
     end

      return true
    end

end
