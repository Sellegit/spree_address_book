object @address
#cache [I18n.locale, root_object]
attributes *address_attributes

node(:default_for_shipping) { |address| address.id == @current_api_user.ship_address_id }
node(:default_for_billing) { |address| address.id == @current_api_user.bill_address_id }

child(:country) do |address|
  attributes *country_attributes
end
child(:state) do |address|
  attributes *state_attributes
end