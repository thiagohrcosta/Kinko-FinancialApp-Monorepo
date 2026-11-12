# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  # Government ID (SSN / EIN) and phone, sent on sign-up
  :document_number, :phone
]

# Stripe webhook events carry the PaymentIntent under `data`, including the
# payer's billing details (name, address). Exact match, so `metadata` is not
# affected; no Kinko endpoint takes a `data` parameter.
Rails.application.config.filter_parameters += [ /\Adata\z/ ]
