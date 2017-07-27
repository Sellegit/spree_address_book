module Spree
  module Api
    module V1
      module Mine
        class AddressesController < Spree::Api::BaseController
          before_action :find_address, except: [:create, :index, :countries]

          def create
            @address = Spree::Address.new(address_params)
            same_addresses = current_api_user.addresses.select { |a| a.same_as? @address }
            if same_addresses.present?
              @address = same_addresses.first
            else
              @address.user = current_api_user
              @address.save!
            end
            ensure_default_address(@address, params[:address][:default_for_shipping])
            respond_with(@address, status: 201, default_template: :show)
          end

          def index 
            @addresses = current_api_user.addresses
            respond_with(@addresses)
          end

          def show
          end

          def update
            if @address.editable?
              @address.update_attributes(address_params)
            else
              new_address = @address.clone
              new_address.attributes = address_params
              @address.update_attribute(:deleted_at, Time.now)
              new_address.save
              @address = new_address
            end
            toggle_default
            respond_with(@address, default_template: :show)
          end

          def destroy
            @address.destroy
            ensure_default_address
            respond_with(@addresses, status: 204)
          end

          def set_default
            toggle_default
            respond_with(@address, default_template: :show) 
          end

          # TODO: move to zone or country controller?
          def countries
            @countries = Spree::Country.where(name: Spree::Config[:default_address_country])
            zone = Spree::Zone.find_by(name: Spree::Config[:address_zone_name]) if Spree::Config[:address_zone_name]
            @countries = zone.countries.order(:name) if zone.present?
          end

          private
          def toggle_default
            if params[:default_for_shipping] || params[:address][:default_for_shipping]
              current_api_user.shipping_address = @address
            elsif current_api_user.ship_address_id == @address.id
              current_api_user.shipping_address = nil
            end
            if params[:default_for_billing] || params[:address][:default_for_billing]
              current_api_user.billing_address = @address
            elsif current_api_user.bill_address_id == @address.id
              current_api_user.billing_address = nil
            end
            current_api_user.save!
          end

          def ensure_default_address(address = nil, force = false)
            current_api_user.reload
            address ||= current_api_user.addresses.order('created_at desc').first
            if force || current_api_user.shipping_address.blank?
              current_api_user.shipping_address = address
            end
            if force || current_api_user.billing_address.blank?
              current_api_user.billing_address = address
            end
            current_api_user.save!
          end

          def find_address
            @address ||= current_api_user ? current_api_user.addresses.find(params[:id]) : nil
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
                  firstname = fullname
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