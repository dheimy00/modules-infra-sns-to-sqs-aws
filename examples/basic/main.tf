provider "aws" {
  region = "us-west-2"
}

module "sns_to_sqs" {
  source = "../../"

  topic_name = "order-processing-topic"

  queues = {
    # Main processing queue with DLQ for handling order processing
    order_processor = {
      name                       = "order-processor-queue"
      visibility_timeout_seconds = 60 # Longer timeout for processing
      dlq = {
        max_receive_count = 3 # Move to DLQ after 3 failed attempts
      }
      tags = {
        Purpose = "order-processing"
        Service = "order-service"
      }
    }

    # Backup queue with longer retention for audit purposes
    order_backup = {
      name                      = "order-backup-queue"
      message_retention_seconds = 604800 # 7 days retention
      dlq = {
        max_receive_count = 5 # More retries for backup processing
      }
      tags = {
        Purpose = "order-backup"
        Service = "audit-service"
      }
    }

    # Delayed processing queue for handling retries
    order_retry = {
      name                       = "order-retry-queue"
      delay_seconds              = 300 # 5 minutes delay
      visibility_timeout_seconds = 30
      tags = {
        Purpose = "order-retry"
        Service = "retry-service"
      }
    }

    # High-priority queue for VIP orders
    vip_orders = {
      name                      = "vip-order-queue"
      receive_wait_time_seconds = 20 # Long polling
      dlq = {
        max_receive_count = 2 # Fewer retries for VIP orders
      }
      tags = {
        Purpose = "vip-processing"
        Service = "vip-service"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "order-processing"
    ManagedBy   = "terraform"
  }
}

# Example of how to use the outputs
output "sns_topic_arn" {
  description = "The ARN of the SNS topic for publishing messages"
  value       = module.sns_to_sqs.sns_topic_arn
}

output "order_processor_queue" {
  description = "Details of the order processor queue"
  value = {
    url = module.sns_to_sqs.sqs_queues["order_processor"].url
    dlq = module.sns_to_sqs.sqs_queues["order_processor"].dlq
  }
}

output "vip_queue" {
  description = "Details of the VIP orders queue"
  value = {
    url = module.sns_to_sqs.sqs_queues["vip_orders"].url
    dlq = module.sns_to_sqs.sqs_queues["vip_orders"].dlq
  }
}
