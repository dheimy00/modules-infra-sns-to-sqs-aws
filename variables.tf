variable "topic_name" {
  description = "The name of the SNS topic"
  type        = string
}

variable "queues" {
  description = "Map of SQS queues to create"
  type = map(object({
    name                       = string
    delay_seconds              = optional(number, 0)
    max_message_size           = optional(number, 262144)
    message_retention_seconds  = optional(number, 345600)
    receive_wait_time_seconds  = optional(number, 0)
    visibility_timeout_seconds = optional(number, 30)
    tags                       = optional(map(string), {})
    dlq = optional(object({
      max_receive_count = number
    }))
  }))
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 