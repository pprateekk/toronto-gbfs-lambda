variable "region" {
  description = "AWS region for every resource"
  type        = string
  default     = "us-east-1"
}

variable "schedule_end_date" {
  description = "When both schedules stop, as a UTC timestamp"
  type        = string
  default     = "2026-10-15T04:00:00Z"
}
