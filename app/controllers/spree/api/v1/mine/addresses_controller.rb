
if defined?(Spree::Api)
  module Spree
    module Api
      module V1
        module Mine
          class AddressesController < Spree::Api::BaseController
            load_and_authorize_resource class: Spree::Address
            before_action :find_address, except: [:create, :index, :countries]

            def create
              @address = current_api_user.addresses.build(address_params)
              @address.save
              ensure_default_address
              respond_with(@address, status: 201, default_template: :show)
            end

            def index 
              @addresses = current_api_user.addresses
              respond_with(@addresses)
            end

            def show
            end

            def udpate
              if @address.editable?
                @address.update_attributes(address_params)
                respond_with(@address)
              else
                new_address = @address.clone
                new_address.attributes = address_params
                @address.update_attribute(:deleted_at, Time.now)
                new_address.save
                ensure_default_address
                respond_with(@new_address)
              end
            end

            def destroy
              @address.destroy
              ensure_default_address
              @addresses = current_api_user.addresses
              respond_with(@addresses, default_template: :index)
            end

            # TODO: separate from #update
            def set_default
              if params[:default_for_shipping]
                current_api_user.shipping_address = @address
              end
              if params[:default_for_billing]
                current_api_user.billing_address = @address
              end
              current_api_user.save
              respond_with(@address, status: 201, default_template: :show) 
            end

            # TODO: move to zone or country controller?
            def countries
              @countries = Spree::Country.where(name: Spree::Config[:default_address_country])
              zone = Spree::Zone.find_by(name: Spree::Config[:address_zone_name]) if Spree::Config[:address_zone_name]
              @countries = zone.countries.order(:name) if zone.present?
            end

            private
            def ensure_default_address
              current_api_user.reload
              newest_address = current_api_user.addresses.order('created_at DESC').first
              if current_api_user.shipping_address.blank?
                current_api_user.shipping_address = newest_address
              end
              if current_api_user.billing_address.blank?
                current_api_user.billing_address = newest_address
              end
              current_api_user.save
            end

            def find_address
              current_api_user ? current_api_user.addresses.find(params[:id]) : nil
            end

            def address_params
              fullname = params.require(:address).delete(:fullname)
              firstname = params.require(:address).delete(:firstname)
              lastname = params.require(:address).delete(:lastname)
              if ((firstname.blank? || lastname.blank?) && fullname.present?)
                splits = fullname.split
                case splits.size
                  when 0
                    firstname = nil
                    lastname = nil
                  when 1
                    # unfortunate, so we need to improvise
                    firstname = name
                    lastname = 'Customer'
                  else
                    firstname = splits.first
                    lastname = splits[1..splits.size].join(&:+)
                end
              end
              params[:address].merge!({firstname: firstname, lastname: lastname})
              params[:address].permit(:address,
                                      :firstname,
                                      :lastname,
                                      :address1,
                                      :address2,
                                      :city,
                                      :state_id,
                                      :zipcode,
                                      :country_id,
                                      :phone
                                    )
            end
          end
        end
      end
    end
  end
end
