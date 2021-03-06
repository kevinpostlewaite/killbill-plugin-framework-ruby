#############################################################################################
#                                                                                           #
#                   Copyright 2010-2013 Ning, Inc.                                          #
#                   Copyright 2014 Groupon, Inc.                                            #
#                   Copyright 2014 The Billing Project, LLC                                 #
#                                                                                           #
#      The Billing Project licenses this file to you under the Apache License, version 2.0  #
#      (the "License"); you may not use this file except in compliance with the             #
#      License.  You may obtain a copy of the License at:                                   #
#                                                                                           #
#          http://www.apache.org/licenses/LICENSE-2.0                                       #
#                                                                                           #
#      Unless required by applicable law or agreed to in writing, software                  #
#      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT            #
#      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the            #
#      License for the specific language governing permissions and limitations              #
#      under the License.                                                                   #
#                                                                                           #
#############################################################################################


#
#                       DO NOT EDIT!!!
#    File automatically generated by killbill-java-parser (git@github.com:killbill/killbill-java-parser.git)
#


module Killbill
  module Plugin
    module Api

      java_package 'org.killbill.billing.util.api'
      class AuditUserApi

        include org.killbill.billing.util.api.AuditUserApi

        def initialize(real_java_api)
          @real_java_api = real_java_api
        end


        java_signature 'Java::org.killbill.billing.util.audit.AccountAuditLogs getAccountAuditLogs(Java::java.util.UUID, Java::org.killbill.billing.util.api.AuditLevel, Java::org.killbill.billing.util.callcontext.TenantContext)'
        def get_account_audit_logs(accountId, auditLevel, context)

          # conversion for accountId [type = java.util.UUID]
          accountId = java.util.UUID.fromString(accountId.to_s) unless accountId.nil?

          # conversion for auditLevel [type = org.killbill.billing.util.api.AuditLevel]
          auditLevel = Java::org.killbill.billing.util.api.AuditLevel.value_of("#{auditLevel.to_s}") unless auditLevel.nil?

          # conversion for context [type = org.killbill.billing.util.callcontext.TenantContext]
          context = context.to_java unless context.nil?
          res = @real_java_api.get_account_audit_logs(accountId, auditLevel, context)
          # conversion for res [type = org.killbill.billing.util.audit.AccountAuditLogs]
          res = Killbill::Plugin::Model::AccountAuditLogs.new.to_ruby(res) unless res.nil?
          return res
        end

        java_signature 'Java::java.util.List getAuditLogs(Java::java.util.UUID, Java::org.killbill.billing.ObjectType, Java::org.killbill.billing.util.api.AuditLevel, Java::org.killbill.billing.util.callcontext.TenantContext)'
        def get_audit_logs(objectId, objectType, auditLevel, context)

          # conversion for objectId [type = java.util.UUID]
          objectId = java.util.UUID.fromString(objectId.to_s) unless objectId.nil?

          # conversion for objectType [type = org.killbill.billing.ObjectType]
          objectType = Java::org.killbill.billing.ObjectType.value_of("#{objectType.to_s}") unless objectType.nil?

          # conversion for auditLevel [type = org.killbill.billing.util.api.AuditLevel]
          auditLevel = Java::org.killbill.billing.util.api.AuditLevel.value_of("#{auditLevel.to_s}") unless auditLevel.nil?

          # conversion for context [type = org.killbill.billing.util.callcontext.TenantContext]
          context = context.to_java unless context.nil?
          res = @real_java_api.get_audit_logs(objectId, objectType, auditLevel, context)
          # conversion for res [type = java.util.List]
          tmp = []
          (res || []).each do |m|
            # conversion for m [type = org.killbill.billing.util.audit.AuditLog]
            m = Killbill::Plugin::Model::AuditLog.new.to_ruby(m) unless m.nil?
            tmp << m
          end
          res = tmp
          return res
        end
      end
    end
  end
end
