# Copyright (c) 2009-2011 VMware, Inc.
module VCAP
  module Services
    module Api
      SDS_UPLOAD_TOKEN_HEADER = 'X-VCAP-SDS-Upload-Token'
      GATEWAY_TOKEN_HEADER = 'X-VCAP-Service-Token'
      SERVICE_LABEL_REGEX  = /^\S+-\S+$/
    end
  end
end
