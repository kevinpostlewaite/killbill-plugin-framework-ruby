module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'
        require 'active_merchant'
        require 'money'
        require 'killbill/helpers/active_merchant/active_record/models/helpers'

        class Response < ::ActiveRecord::Base

          extend ::Killbill::Plugin::ActiveMerchant::Helpers

          self.abstract_class = true

          def self.from_response(api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, kb_tenant_id, response, extra_params = {}, model = Response)
            model.new({
                          :api_call                  => api_call,
                          :kb_account_id             => kb_account_id,
                          :kb_payment_id             => kb_payment_id,
                          :kb_payment_transaction_id => kb_payment_transaction_id,
                          :transaction_type          => transaction_type,
                          :kb_tenant_id              => kb_tenant_id,
                          :message                   => response.message,
                          :authorization             => response.authorization,
                          :fraud_review              => response.fraud_review?,
                          :test                      => response.test?,
                          :avs_result_code           => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.code : response.avs_result['code'],
                          :avs_result_message        => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.message : response.avs_result['message'],
                          :avs_result_street_match   => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.street_match : response.avs_result['street_match'],
                          :avs_result_postal_match   => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.postal_match : response.avs_result['postal_match'],
                          :cvv_result_code           => response.cvv_result.kind_of?(::ActiveMerchant::Billing::CVVResult) ? response.cvv_result.code : response.cvv_result['code'],
                          :cvv_result_message        => response.cvv_result.kind_of?(::ActiveMerchant::Billing::CVVResult) ? response.cvv_result.message : response.cvv_result['message'],
                          :success                   => response.success?
                      }.merge!(extra_params))
          end

          def to_transaction_info_plugin(transaction=nil)
            if transaction.nil?
              amount_in_cents = nil
              currency        = nil
              created_date    = created_at
            else
              amount_in_cents = transaction.amount_in_cents
              currency        = transaction.currency
              created_date    = transaction.created_at
            end

            t_info_plugin                             = Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
            t_info_plugin.kb_payment_id               = kb_payment_id
            t_info_plugin.kb_transaction_payment_id   = kb_payment_transaction_id
            t_info_plugin.transaction_type            = transaction_type.nil? ? nil : transaction_type.to_sym
            t_info_plugin.amount                      = Money.new(amount_in_cents, currency).to_d if currency
            t_info_plugin.currency                    = currency
            t_info_plugin.created_date                = created_date
            t_info_plugin.effective_date              = effective_date
            t_info_plugin.status                      = (success ? :PROCESSED : :ERROR)
            t_info_plugin.gateway_error               = gateway_error
            t_info_plugin.gateway_error_code          = gateway_error_code
            t_info_plugin.first_payment_reference_id  = first_reference_id
            t_info_plugin.second_payment_reference_id = second_reference_id

            properties = []
            properties << create_plugin_property('message', message)
            properties << create_plugin_property('authorization', authorization)
            properties << create_plugin_property('fraudReview', fraud_review)
            properties << create_plugin_property('test', self.read_attribute(:test))
            properties << create_plugin_property('avsResultCode', avs_result_code)
            properties << create_plugin_property('avsResultMessage', avs_result_message)
            properties << create_plugin_property('avsResultStreetMatch', avs_result_street_match)
            properties << create_plugin_property('avsResultPostalMatch', avs_result_postal_match)
            properties << create_plugin_property('cvvResultCode', cvv_result_code)
            properties << create_plugin_property('cvvResultMessage', cvv_result_message)
            properties << create_plugin_property('success', success)
            t_info_plugin.properties = properties

            t_info_plugin
          end

          # Override in your plugin if needed
          def self.search_where_clause(t, search_key)
            # Exact matches only
            where_clause = t[:kb_payment_id].eq(search_key)
                       .or(t[:kb_payment_transaction_id].eq(search_key))
                       .or(t[:message].eq(search_key))
                       .or(t[:authorization].eq(search_key))
                       .or(t[:fraud_review].eq(search_key))

            # Only search successful payments and refunds
            where_clause = where_clause.and(t[:success].eq(true))

            where_clause
          end

          # VisibleForTesting
          def self.search_query(search_key, kb_tenant_id, offset = nil, limit = nil)
            t = self.arel_table

            if kb_tenant_id.nil?
              query = t.where(search_where_clause(t, search_key))
              .order(t[:id])
            else
              query = t.where(search_where_clause(t, search_key).and(t[:kb_tenant_id].eq(kb_tenant_id)))
              .order(t[:id])
            end

            if offset.blank? and limit.blank?
              # true is for count distinct
              query.project(t[:id].count(true))
            else
              query.skip(offset) unless offset.blank?
              query.take(limit) unless limit.blank?
              query.project(t[Arel.star])
              # Not chainable
              query.distinct
            end
            query
          end

          def self.search(search_key, kb_tenant_id, offset = 0, limit = 100)
            pagination                  = ::Killbill::Plugin::Model::Pagination.new
            pagination.current_offset   = offset
            pagination.total_nb_records = self.count_by_sql(self.search_query(search_key, kb_tenant_id))
            pagination.max_nb_records   = self.where(:success => true).count
            pagination.next_offset      = (!pagination.total_nb_records.nil? && offset + limit >= pagination.total_nb_records) ? nil : offset + limit
            # Reduce the limit if the specified value is larger than the number of records
            actual_limit                = [pagination.max_nb_records, limit].min
            pagination.iterator         = ::Killbill::Plugin::ActiveMerchant::ActiveRecord::StreamyResultSet.new(actual_limit) do |offset, limit|
              self.find_by_sql(self.search_query(search_key, kb_tenant_id, offset, limit)).map { |x| x.to_transaction_info_plugin }
            end
            pagination
          end

          # Override in your plugin if needed
          def txn_id
            authorization
          end

          # Override in your plugin if needed
          def first_reference_id
            nil
          end

          # Override in your plugin if needed
          def second_reference_id
            nil
          end

          # Override in your plugin if needed
          def effective_date
            created_at
          end

          # Override in your plugin if needed
          def gateway_error
            message
          end

          # Override in your plugin if needed
          def gateway_error_code
            nil
          end

          private

          def create_plugin_property(key, value)
            prop       = Killbill::Plugin::Model::PluginProperty.new
            prop.key   = key
            prop.value = value
            prop
          end
        end
      end
    end
  end
end
