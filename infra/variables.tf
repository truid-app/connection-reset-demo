variable "project" {
  type = string
}
variable "region" {
  default = "europe-north1"
}
variable "zone" {
  default = "europe-north1-a"
}

variable "domain" {
  type = string
}

variable "docker_repository" {
  type = string
}

variable "docker_image_version" {
  default = "latest"
}

# database instance settings
variable "db_version" {
  description = "The version of of the database. For example, POSTGRES_9_6 or POSTGRES_11"
  default     = "POSTGRES_13"
}
variable "db_tier" {
  description = "The machine tier (First Generation) or type (Second Generation). Reference: https://cloud.google.com/sql/pricing"
  default     = "db-f1-micro"
}
variable "db_activation_policy" {
  description = "Specifies when the instance should be active. Options are ALWAYS, NEVER or ON_DEMAND"
  default     = "ALWAYS"
}
variable "db_disk_autoresize" {
  description = "Second Generation only. Configuration to increase storage size automatically."
  default     = true
}
variable "db_disk_size" {
  description = "Second generation only. The size of data disk, in GB. Size of a running instance cannot be reduced but can be increased."
  default     = 10
}
variable "db_disk_type" {
  description = "Second generation only. The type of data disk: PD_SSD or PD_HDD"
  default     = "PD_HDD"
}
variable "db_pricing_plan" {
  description = "First generation only. Pricing plan for this instance, can be one of PER_USE or PACKAGE"
  default     = "PER_USE"
}
variable "db_instance_access_cidr" {
  description = "The IPv4 CIDR to provide access the database instance"
  default     = "0.0.0.0/0"
}
variable "db_charset" {
  description = "The charset for the default database"
  default     = ""
}
variable "db_collation" {
  description = "The collation for the default database. Example for MySQL databases: 'utf8_general_ci'"
  default     = ""
}
