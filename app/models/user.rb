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

      def self.find_for_database_authentication(warden_conditions)
         conditions = warden_conditions.dup
         if login = conditions.delete(:login)
           where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
         elsif conditions.has_key?(:cellphone) || conditions.has_key?(:email)
           where(conditions.to_h).first
         end
       end

  def admin?
    is_admin
  end


end
