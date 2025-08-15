output "lambda_function_name" {
  value = aws_lambda_function.lambda_function.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "lambda_invoke_command" {
  value = "aws lambda invoke --function-name ${aws_lambda_function.lambda_function.function_name} output.json"
}


output "rds_writer_endpoint" {
  value = aws_rds_cluster.lambda_aurora_mysql.endpoint
}

# Reader endpoint (load-balanced read-only)
output "rds_reader_endpoint" {
  value = aws_rds_cluster.lambda_aurora_mysql.reader_endpoint
}

#rds_reader_endpoint = "aurora-cluster-db.cluster-ro-cl8m2462crgo.ca-central-1.rds.amazonaws.com"
#rds_writer_endpoint = "aurora-cluster-db.cluster-cl8m2462crgo.ca-central-1.rds.amazonaws.com"
