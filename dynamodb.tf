resource aws_dynamodb_table servers {
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"
  name = "Servers"

  attribute {
    name = "id"
    type = "S"
  }
}
