variable "ionos_username" {
  description = "IONOS Username"
  type        = string
  default     = "username@example.com"
}

variable "ionos_password" {
  description = "IONOS Password"
  type        = string
  default     = "secret_password"
}

variable "boot_cdrom" {
  description = "Boot from CDROM"
  type        = bool
  default     = true
}

variable "ai_image" {
  description = "Assisted Installer Image"
  type        = string
  default     = "minimal.iso"
}

variable "cluster_ip" {
  description = "Cluster IP"
  type        = string
  default     = "85.215.203.83"
}
