variable "location" {
  type        = string
  default     = "westus2"
  description = "The Azure region to deploy resources in."
}

variable "frontend_rg" {
  type        = string
  default     = "yueheresume_web"
  description = "The frontend resource group."
}

variable "backend_rg" {
  type        = string
  default     = "yueheresume_api"
  description = "The backend resource group: function, cosmodb."
}

variable "cosmodb" {
  type        = string
  default     = "resumecosmodb"
  description = "cosmodb name."
}

variable "cosmodb_rg" {
  type        = string
  default     = "resume_backend"
  description = "cosmodb resource group."
}

variable "appserviceplan" {
  type        = string
  default     = "resumeserviceplan"
  description = "app service plan for function and logic app"
}
