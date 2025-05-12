# AWS SNS to SQS Fanout Terraform Module

This Terraform module creates an AWS SNS topic and multiple SQS queues in a fanout pattern, where messages published to the SNS topic are delivered to all subscribed SQS queues. The module supports Dead Letter Queues (DLQ) for handling failed message processing.

## Features

- Creates an SNS topic
- Creates multiple SQS queues
- Optional Dead Letter Queues (DLQ) for each queue
- Configures SNS topic policy to allow sending messages to all SQS queues
- Creates SNS subscriptions to all SQS queues
- Configurable queue parameters for each queue
- Individual and global tagging support
- Fanout pattern support

## Usage

```hcl
module "sns_to_sqs" {
  source = "path/to/module"

  topic_name = "my-topic"
  
  queues = {
    processing = {
      name = "processing-queue"
      dlq = {
        max_receive_count = 3
      }
      tags = {
        Purpose = "processing"
      }
    }
    backup = {
      name = "backup-queue"
      message_retention_seconds = 604800  # 7 days
      dlq = {
        max_receive_count = 5
      }
      tags = {
        Purpose = "backup"
      }
    }
    delayed = {
      name = "delayed-queue"
      delay_seconds = 60
      tags = {
        Purpose = "delayed-processing"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| topic_name | The name of the SNS topic | `string` | n/a | yes |
| queues | Map of SQS queues to create | `map(object)` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

### Queue Object Structure

Each queue in the `queues` map supports the following attributes:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the SQS queue | `string` | n/a | yes |
| delay_seconds | The time in seconds that the delivery of all messages in the queue will be delayed | `number` | `0` | no |
| max_message_size | The limit of how many bytes a message can contain before Amazon SQS rejects it | `number` | `262144` | no |
| message_retention_seconds | The number of seconds Amazon SQS retains a message | `number` | `345600` | no |
| receive_wait_time_seconds | The time for which a ReceiveMessage call will wait for a message to arrive | `number` | `0` | no |
| visibility_timeout_seconds | The visibility timeout for the queue | `number` | `30` | no |
| tags | A map of tags to add to this specific queue | `map(string)` | `{}` | no |
| dlq | Dead Letter Queue configuration | `object` | `null` | no |

### DLQ Configuration

The `dlq` object supports the following attributes:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| max_receive_count | The number of times a message can be received before being sent to the DLQ | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| sqs_queues | Map of created SQS queues with their ARNs, URLs, and DLQ information |
| sns_topic_arn | The ARN of the SNS topic |
| sns_topic_name | The name of the SNS topic |

## License

MIT Licensed. See LICENSE for full details. 