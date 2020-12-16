output "aws_lambda_function" {
    value = aws_lambda_function.this
}

output "aws_iam_role" {
    value = aws_iam_role.lambda_role
}
