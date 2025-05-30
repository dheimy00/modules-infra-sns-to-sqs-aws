resource "aws_sqs_queue" "dlq" {
  for_each = { for idx, queue in var.queues : queue.name => queue if queue.dlq != null }

  name                       = "${each.value.name}-dlq"
  delay_seconds              = 0
  max_message_size           = each.value.max_message_size
  message_retention_seconds  = 1209600 # 14 dias
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = each.value.visibility_timeout_seconds

  tags = merge(var.tags, each.value.tags, {
    Purpose = "DeadLetterQueue"
  })
}

resource "aws_sqs_queue" "queues" {
  for_each = { for idx, queue in var.queues : queue.name => queue }

  name                       = each.value.name
  delay_seconds              = each.value.delay_seconds
  max_message_size           = each.value.max_message_size
  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds
  visibility_timeout_seconds = each.value.visibility_timeout_seconds

  redrive_policy = each.value.dlq != null ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.value.name].arn
    maxReceiveCount     = each.value.dlq.max_receive_count
  }) : null

  tags = merge(var.tags, each.value.tags)
}

resource "aws_sns_topic" "this" {
  name = var.topic_name
  tags = var.tags
}

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow-Self-Publish"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.this.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.this.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "sns_to_sqs" {
  for_each = aws_sqs_queue.queues

  queue_url = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = each.value.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.this.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "subscriptions" {
  for_each = aws_sqs_queue.queues

  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = each.value.arn

  depends_on = [
    aws_sqs_queue_policy.sns_to_sqs,
    aws_sns_topic.this
  ]
}
