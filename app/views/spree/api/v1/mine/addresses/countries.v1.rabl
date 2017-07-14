object false

child @countries => :countries do
  attributes *country_attributes
  child :states => :states do
    attributes *state_attributes
  end
end