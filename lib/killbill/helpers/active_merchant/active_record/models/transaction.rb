module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'

        class Transaction < ::ActiveRecord::Base

          self.abstract_class = true

          class << self
            def transactions_from_kb_payment_id(kb_payment_id, kb_tenant_id)
              where(:kb_payment_id => kb_payment_id, :kb_tenant_id => kb_tenant_id).order(:created_at)
            end

            [:authorize, :capture, :purchase, :credit, :refund].each do |transaction_type|
              define_method("#{transaction_type.to_s}s_from_kb_payment_id") do |kb_payment_id, kb_tenant_id|
                transaction_from_kb_payment_id(transaction_type.to_s.upcase, kb_payment_id, kb_tenant_id, :multiple)
              end
            end

            # For convenience
            alias_method :authorizations_from_kb_payment_id, :authorizes_from_kb_payment_id

            # void is special: unique void per payment_id
            def void_from_kb_payment_id(kb_payment_id, kb_tenant_id)
              transaction_from_kb_payment_id(:VOID, kb_payment_id, kb_tenant_id, :single)
            end

            def from_kb_payment_transaction_id(kb_payment_transaction_id, kb_tenant_id)
              transaction_from_kb_payment_transaction_id(nil, kb_payment_transaction_id, kb_tenant_id, :single)
            end

            def find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id, amount_in_cents)
              begin
                do_find_candidate_transaction_for_refund(:authorize, kb_payment_id, kb_tenant_id, amount_in_cents)
              rescue
                do_find_candidate_transaction_for_refund(:purchase, kb_payment_id, kb_tenant_id, amount_in_cents)
              end
            end

            private

            def do_find_candidate_transaction_for_refund(api_call, kb_payment_id, kb_tenant_id, amount_in_cents)
              # Find one successful charge which amount is at least the amount we are trying to refund
              if kb_tenant_id.nil?
                transactions = where('amount_in_cents >= ? AND api_call = ? AND kb_tenant_id is NULL AND kb_payment_id = ?', amount_in_cents, api_call, kb_payment_id).order(:created_at)
              else
                transactions = where('amount_in_cents >= ? AND api_call = ? AND kb_tenant_id = ? AND kb_payment_id = ?', amount_in_cents, api_call, kb_tenant_id, kb_payment_id).order(:created_at)
              end
              raise "Unable to find transaction for payment #{kb_payment_id} and api_call #{api_call}" if transactions.size == 0

              # We have candidates, but we now need to make sure we didn't refund more than for the specified amount
              amount_refunded_in_cents = where('api_call = ? and kb_payment_id = ?', :refund, kb_payment_id)
                                         .sum('amount_in_cents')

              amount_left_to_refund_in_cents = -amount_refunded_in_cents
              transactions.map { |transaction| amount_left_to_refund_in_cents += transaction.amount_in_cents }
              raise "Amount #{amount_in_cents} too large to refund for payment #{kb_payment_id}" if amount_left_to_refund_in_cents < amount_in_cents

              transactions.first
            end

            [:kb_payment_id, :kb_payment_transaction_id].each do |attribute|
              define_method("transaction_from_#{attribute.to_s}") do |transaction_type, attribute_value, kb_tenant_id, how_many|
                if kb_tenant_id.nil?
                  if transaction_type.nil?
                    transactions = where("kb_tenant_id is NULL AND #{attribute.to_s} = ?", attribute_value).order(:created_at)
                  else
                    transactions = where("transaction_type = ? AND kb_tenant_id is NULL AND #{attribute.to_s} = ?", transaction_type, attribute_value).order(:created_at)
                  end
                else
                  if transaction_type.nil?
                    transactions = where("kb_tenant_id = ? AND #{attribute.to_s} = ?", kb_tenant_id, attribute_value).order(:created_at)
                  else
                    transactions = where("transaction_type = ? AND kb_tenant_id = ? AND #{attribute.to_s} = ?", transaction_type, kb_tenant_id, attribute_value).order(:created_at)
                  end
                end
                if how_many == :single
                  raise "Kill Bill #{attribute} = #{attribute_value} mapping to multiple plugin transactions" if transactions.size > 1
                  transactions[0]
                else
                  transactions
                end
              end
            end
          end
        end
      end
    end
  end
end
