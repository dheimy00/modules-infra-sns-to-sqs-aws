output "sqs_queues" {
  description = "Map of created SQS queues with their ARNs and URLs"
  value = {
    for name, queue in aws_sqs_queue.queues : name => {
      arn = queue.arn
      url = queue.url
      dlq = queue.redrive_policy != null ? {
        arn = aws_sqs_queue.dlq[name].arn
        url = aws_sqs_queue.dlq[name].url
      } : null
    }
  }
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.this.arn
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue"
  value       = aws_sqs_queue.this.url
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.this.arn
}

output "sns_topic_name" {
  description = "The name of the SNS topic"
  value       = aws_sns_topic.this.name
} 