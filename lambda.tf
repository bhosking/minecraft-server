resource aws_lambda_permission APITriggerServer {
  statement_id = "AllowAPITriggerServerInvoke"
  action = "lambda:InvokeFunction"
  function_name = module.lambda-triggerServer.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.TriggerServerAPI.execution_arn}/*/*/${aws_api_gateway_resource.ServerId.path_part}"
}
