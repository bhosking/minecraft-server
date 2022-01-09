#
# API Gateway
#
resource aws_api_gateway_rest_api TriggerServerAPI {
  name = "TriggerServerApi"
  description = "API that starts or checks the status of the server."
}

resource aws_api_gateway_resource ServerId {
  rest_api_id = aws_api_gateway_rest_api.TriggerServerAPI.id
  parent_id = aws_api_gateway_rest_api.TriggerServerAPI.root_resource_id
  path_part = "{ServerId}"
}

resource aws_api_gateway_method server-options {
  rest_api_id = aws_api_gateway_rest_api.TriggerServerAPI.id
  resource_id = aws_api_gateway_resource.ServerId.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource aws_api_gateway_method_response server-options {
  rest_api_id = aws_api_gateway_method.server-options.rest_api_id
  resource_id = aws_api_gateway_method.server-options.resource_id
  http_method = aws_api_gateway_method.server-options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource aws_api_gateway_integration server-options {
  rest_api_id = aws_api_gateway_method.server-options.rest_api_id
  resource_id = aws_api_gateway_method.server-options.resource_id
  http_method = aws_api_gateway_method.server-options.http_method
  type = "MOCK"

  request_templates = {
    "application/json" = <<TEMPLATE
      {
        "statusCode": 200
      }
    TEMPLATE
  }
}

resource aws_api_gateway_integration_response server-options {
  rest_api_id = aws_api_gateway_method.server-options.rest_api_id
  resource_id = aws_api_gateway_method.server-options.resource_id
  http_method = aws_api_gateway_method.server-options.http_method
  status_code = aws_api_gateway_method_response.server-options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.server-options]
}

resource aws_api_gateway_method server-get {
  rest_api_id = aws_api_gateway_rest_api.TriggerServerAPI.id
  resource_id = aws_api_gateway_resource.ServerId.id
  http_method = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.ServerId" = true
  }
}

resource aws_api_gateway_method_response server-get {
  rest_api_id = aws_api_gateway_method.server-get.rest_api_id
  resource_id = aws_api_gateway_method.server-get.resource_id
  http_method = aws_api_gateway_method.server-get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource aws_api_gateway_integration server-get {
  rest_api_id = aws_api_gateway_method.server-get.rest_api_id
  resource_id = aws_api_gateway_method.server-get.resource_id
  http_method = aws_api_gateway_method.server-get.http_method
  type = "AWS_PROXY"
  uri = module.lambda-triggerServer.function_invoke_arn
  integration_http_method = "POST"

//   request_parameters = {
//    "integration.request.path.ServerId" = "method.request.path.ServerId"
//  }
}

resource aws_api_gateway_integration_response server-get {
  rest_api_id = aws_api_gateway_method.server-get.rest_api_id
  resource_id = aws_api_gateway_method.server-get.resource_id
  http_method = aws_api_gateway_method.server-get.http_method
  status_code = aws_api_gateway_method_response.server-get.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.server-get]
}


#
# Deployment
#
resource aws_api_gateway_deployment TriggerServerAPI {
  rest_api_id = aws_api_gateway_rest_api.TriggerServerAPI.id
  stage_name  = "server"
  # taint deployment if any api resources change
  stage_description = md5(join("", [
    md5(file("${path.module}/api.tf")),
    aws_api_gateway_method.server-options.id,
    aws_api_gateway_integration.server-options.id,
    aws_api_gateway_integration_response.server-options.id,
    aws_api_gateway_method_response.server-options.id,
    aws_api_gateway_method.server-get.id,
    aws_api_gateway_integration.server-get.id,
    aws_api_gateway_integration_response.server-get.id,
    aws_api_gateway_method_response.server-get.id,
  ]))
}
