class JsonWebToken
  SECRET_KEY = ENV.fetch("JWT_SECRET_KEY", Rails.application.secret_key_base)

  def self.encode(payload, exp = 24.hours.from_now)
    to_encode = payload.dup
    to_encode[:exp] = exp.to_i
    JWT.encode(to_encode, SECRET_KEY)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(body)
  end
end