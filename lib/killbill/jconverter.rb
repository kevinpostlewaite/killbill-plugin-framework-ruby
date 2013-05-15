
require 'date'

module Killbill
  module Plugin

    class JConverter

      class << self

        #
        # Convert from ruby -> java
        #
        def to_account_data(data)
          Killbill::Plugin::Gen::AccountData.new(to_string(data.external_key),
                                                 to_string(data.name),
                                                 data.first_name_length,
                                                 to_string(data.email),
                                                 data.bill_cycle_day_local,
                                                 to_currency(data.currency),
                                                 to_uuid(data.payment_method_id),
                                                 to_date_time_zone(data.time_zone),
                                                 to_string(data.locale),
                                                 to_string(data.address1),
                                                 to_string(data.address2),
                                                 to_string(data.company_name),
                                                 to_string(data.city),
                                                 to_string(data.state_or_province),
                                                 to_string(data.postal_code),
                                                 to_string(data.country),
                                                 to_string(data.phone),
                                                 to_boolean(data.is_migrated),
                                                 to_boolean(data.is_notified_for_invoices))
        end

        def to_payment_info_plugin(payment_response)
          Killbill::Plugin::Gen::PaymentInfoPlugin.new(to_big_decimal(payment_response.amount),
                                                       to_joda_date_time(payment_response.created_date),
                                                       to_joda_date_time(payment_response.effective_date),
                                                       to_payment_plugin_status(payment_response.status),
                                                       to_string(payment_response.gateway_error),
                                                       to_string(payment_response.gateway_error_code),
                                                       to_string(payment_response.first_payment_reference_id),
                                                       to_string(payment_response.second_payment_reference_id))
        end

        def to_refund_info_plugin(refund_response)
          Killbill::Plugin::Gen::RefundInfoPlugin.new(to_big_decimal(refund_response.amount),
                                                      to_joda_date_time(refund_response.created_date),
                                                      to_joda_date_time(refund_response.effective_date),
                                                      to_refund_plugin_status(refund_response.status),
                                                      to_string(refund_response.gateway_error),
                                                      to_string(refund_response.gateway_error_code),
                                                      to_string(refund_response.reference_id))
        end

        def to_payment_method_response(pm)
          props = java.util.ArrayList.new
          pm.properties.each do |p|
            jp = Killbill::Plugin::Gen::PaymentMethodKVInfo.new(p.is_updatable, p.key, p.value)
            @props.add(jp)
          end
          Killbill::Plugin::Gen::PaymentMethodPlugin.new(to_string(pm.external_payment_method_id),
                                                         to_boolean(pm.is_default_payment_method),
                                                         props,
                                                         nil,
                                                         to_string(pm.type),
                                                         to_string(pm.cc_name),
                                                         to_string(pm.cc_type),
                                                         to_string(pm.cc_expiration_month),
                                                         to_string(pm.cc_expiration_year),
                                                         to_string(pm.cc_last4),
                                                         to_string(pm.address1),
                                                         to_string(pm.address2),
                                                         to_string(pm.city),
                                                         to_string(pm.state),
                                                         to_string(pm.zip),
                                                         to_string(pm.country))
        end

        def to_payment_method_info_plugin(pm)
          Killbill::Plugin::Gen::PaymentMethodInfoPlugin.new(to_uuid(pm.account_id),
                                                             to_uuid(pm.payment_method_id),
                                                             to_boolean(pm.is_default),
                                                             to_string(pm.external_payment_method_id))
        end


        def to_currency(currency)
          if currency.nil?
            return nil
          end
          if currency == Killbill::Plugin::Gen::Currency::GBP
             return Java::com.ning.billing.catalog.api.Currency::GBP
          elsif currency == Killbill::Plugin::Gen::Currency::MXN
            return Java::com.ning.billing.catalog.api.Currency::MXN
          elsif currency == Killbill::Plugin::Gen::Currency::BRL
              return Java::com.ning.billing.catalog.api.Currency::BRL
          elsif currency == Killbill::Plugin::Gen::Currency::EUR
              return Java::com.ning.billing.catalog.api.Currency::EUR
          elsif currency == Killbill::Plugin::Gen::Currency::AUD
              return Java::com.ning.billing.catalog.api.Currency::AUD
          elsif currency == Killbill::Plugin::Gen::Currency::USD
              return Java::com.ning.billing.catalog.api.Currency::USD
          end
          nil
        end

        def to_date_time_zone(date_time_zone)
          if date_time_zone.nil?
            return nil
          end
          if date_time_zone == Killbill::Plugin::Gen::DateTimeZone::UTC
            return org.joda.time.DateTimeZone::UTC
          end
          nil
        end

        def to_uuid(uuid)
          uuid.nil? ? nil : java.util.UUID.fromString(uuid.to_s)
        end

        def to_joda_date_time(time)
          date_time = (time.kind_of? Time) ? DateTime.parse(time.to_s) : time
          date_time.nil? ? nil : org.joda.time.DateTime.new(date_time.to_s, org.joda.time.DateTimeZone::UTC)
        end

        def to_string(str)
          str.nil? ? nil : java.lang.String.new(str.to_s)
        end

        def to_payment_plugin_status(status)
          if status == Killbill::Plugin::Gen::PaymentPluginStatus::PROCESSED
            Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::PROCESSED
          elsif status == Killbill::Plugin::Gen::PaymentPluginStatus::ERROR
            Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::ERROR
          else
            Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::UNDEFINED
          end
        end

        def to_refund_plugin_status(status)
          if status == Killbill::Plugin::Gen::RefundPluginStatus::PROCESSED
            Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::PROCESSED
          elsif status == Killbill::Plugin::Gen::RefundPluginStatus::ERROR
            Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::ERROR
          else
            Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::UNDEFINED
          end
        end

        def to_big_decimal(amount_in_cents)
          amount_in_cents.nil? ? java.math.BigDecimal::ZERO : java.math.BigDecimal.new('%.2f' % (amount_in_cents.to_i/100.0))
        end

        def to_boolean(b)
          b.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(b)
        end


        #
        # Convert from java -> ruby
        #


        def from_account(data)
          Killbill::Plugin::Gen::Account.new(from_uuid(data.id),
                                            from_blocking_state(data.blocking_state),
                                            from_joda_date_time(data.created_date),
                                            from_joda_date_time(data.updated_date),
                                            from_string(data.external_key),
                                            from_string(data.name),
                                            data.first_name_length,
                                            from_string(data.email),
                                            data.bill_cycle_day_local,
                                            from_currency(data.currency),
                                            from_uuid(data.payment_method_id),
                                            from_date_time_zone(data.time_zone),
                                            from_string(data.locale),
                                            from_string(data.address1),
                                            from_string(data.address2),
                                            from_string(data.company_name),
                                            from_string(data.city),
                                            from_string(data.state_or_province),
                                            from_string(data.postal_code),
                                            from_string(data.country),
                                            from_string(data.phone),
                                            from_boolean(data.is_migrated),
                                            from_boolean(data.is_notified_for_invoices))
        end

        def from_blocking_state(data)
          if data.nil?
            return nil
          end

        end

        def from_currency(currency)
          if currency.nil?
            return nil
          end
          if currency == Java::com.ning.billing.catalog.api.Currency::GBP
             return Killbill::Plugin::Gen::Currency::GBP
          elsif currency == Java::com.ning.billing.catalog.api.Currency::MXN
            return Killbill::Plugin::Gen::Currency::MXN
          elsif currency == Java::com.ning.billing.catalog.api.Currency::BRL
              return Killbill::Plugin::Gen::Currency::BRL
          elsif currency == Java::com.ning.billing.catalog.api.Currency::EUR
              return Killbill::Plugin::Gen::Currency::EUR
          elsif currency == Java::com.ning.billing.catalog.api.Currency::AUD
              return Killbill::Plugin::Gen::Currency::AUD
          elsif currency == Java::com.ning.billing.catalog.api.Currency::USD
              return Killbill::Plugin::Gen::Currency::USD
          end
          nil
        end

        def from_date_time_zone(date_time_zone)
          if date_time_zone.nil?
            return nil
          end
          if date_time_zone == org.joda.time.DateTimeZone::UTC
            return Killbill::Plugin::Gen::DateTimeZone::UTC
          end
          nil
        end

        def from_uuid(uuid)
           uuid.nil? ? nil : Killbill::Plugin::Gen::UUID.new(uuid.to_s)
        end

        def from_joda_date_time(joda_time)
          if joda_time.nil?
            return nil
          end

          fmt = org.joda.time.format.ISODateTimeFormat.date_time
          str = fmt.print(joda_time);
          DateTime.iso8601(str)
        end

        def from_string(str)
          str.nil? ? nil : str.to_s
        end

        def from_payment_plugin_status(status)
          if status == Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::PROCESSED
            Killbill::Plugin::Gen::PaymentPluginStatus::PROCESSED
          elsif status == Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::ERROR
            Killbill::Plugin::Gen::PaymentPluginStatus::ERROR
          else
            Killbill::Plugin::Gen::PaymentPluginStatus::UNDEFINED
          end
        end

        def from_refund_plugin_status(status)
          if status == Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::PROCESSED
            Killbill::Plugin::Gen::RefundPluginStatus::PROCESSED
          elsif status == Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::ERROR
            Killbill::Plugin::Gen::RefundPluginStatus::ERROR
          else
            Killbill::Plugin::Gen::RefundPluginStatus::UNDEFINED
          end
        end

        def from_big_decimal(big_decimal)
          big_decimal.nil? ? 0 : big_decimal.multiply(java.math.BigDecimal.valueOf(100)).to_s.to_i
        end

        def from_boolean(b)
          if b.nil?
            return false
          end

          b_value = (b.java_kind_of? java.lang.Boolean) ? b.boolean_value : b
          return b_value ? true : false
        end

        def from_payment_method_plugin(pm)
          props = Array.new
          pm.properties.each do |p|
            key = from_string(p.key)
            value = from_string(p.value)
            is_updatable = from_boolean(p.is_updatable)
            props << Killbill::Plugin::Gen::PaymentMethodKVInfo.new(is_updatable, key, value)
          end

          pmid = from_string(pm.external_payment_method_id)
          default = from_boolean(pm.is_default_payment_method)
          Killbill::Plugin::Gen::PaymentMethodPlugin.new(from_string(pm.external_payment_method_id),
                                                         from_boolean(pm.is_default_payment_method),
                                                         props,
                                                         nil,
                                                         from_string(pm.type),
                                                         from_string(pm.cc_name),
                                                         from_string(pm.cc_type),
                                                         from_string(pm.cc_expiration_month),
                                                         from_string(pm.cc_expiration_year),
                                                         from_string(pm.cc_last4),
                                                         from_string(pm.address1),
                                                         from_string(pm.address2),
                                                         from_string(pm.city),
                                                         from_string(pm.state),
                                                         from_string(pm.zip),
                                                         from_string(pm.country))
        end

        def from_payment_method_info_plugin(pm)
          Killbill::Plugin::Gen::PaymentMethodInfoPlugin.new(from_uuid(pm.account_id),
                                                             from_uuid(pm.payment_method_id),
                                                             from_boolean(pm.is_default),
                                                             from_string(pm.external_payment_method_id))
        end


        def from_ext_bus_event(ext_bus)
          JEvent.to_event(ext_bus)
        end

      end
    end
  end
end
