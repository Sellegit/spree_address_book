Spree::AppConfiguration.class_eval do
  preference :alternative_billing_phone, :boolean, default: false # Request extra phone for billing addr
  preference :address_zone_name, :string, default: nil
  preference :default_address_country, :string, default: 'United States'
end