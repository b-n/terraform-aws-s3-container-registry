data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_at_edge" {
  name               = "lambda_at_edge"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.js"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "at_edge" {
  filename      = "lambda.zip"
  function_name = "lambda"
  role          = aws_iam_role.lambda_at_edge.arn

  handler = "index.handler"
  publish = true

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs16.x"
}

resource "aws_lambda_permission" "allow_cloudfront" {
  statement_id  = "AllowFetchFromCloudFront"
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.at_edge.function_name
  principal     = "edgelambda.amazonaws.com"
}
