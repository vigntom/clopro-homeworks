variable "token" {
  type        = string
  nullable = false
  sensitive = true
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  nullable = false
  sensitive = true
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  nullable = false
  // sensitive = true
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "image_id" {
  type = string
  # default = "fd80mrhj8fl2oe87o4e1"
  default = "fd8moeaar19homgk3vsm"
  description = "Yandex compute Image id"
}

variable "lemp_image_id" {
  type = string
  default = "fd8rgek7pvfhiu98fcia"
  description = "Yandex compute Image id"
}

variable "vpc_name" {
  type        = string
  default     = "clopro"
  description = "VPC network"
}

variable "public_subnet" {
  type = object({ name: string, cidr: list(string) })
  default = {
    name: "public",
    cidr: ["192.168.10.0/24"]
  }

  description = "Public subnet configuration"
}

variable "private_subnet" {
  type = object({ name: string, cidr: list(string) })
  default = {
    name: "private",
    cidr: ["192.168.20.0/24"]
  }

  description = "Private subnet configuration"
}

variable "vm_config" {
  type = object({ cpu:number, memory:number, fraction:number, platform:string })
  default = {
    cpu: 2,
    memory: 1,
    fraction: 5,
    platform: "standard-v2"
  }

  description = "Default VM configuration"
}

variable "public_vm" {
  type = string
  default = "nat-instance"
  description = "Public vpc vm name"
}

variable "public_vm_ip" {
  type = string
  default = "192.168.10.254"
  description = "Public vpc vm ip"
}

variable "protected_vm" {
  type = string
  default = "virtualka"
  description = "Private vpc vm name"
}

variable "sa_name" {
  type = string
  default = "backet-sa"
  description = "Service account name"
}

variable "bucket_name" {
  type = string
  default = "clopro-bucket"
  description = "Bucket name"
}

variable "ig-sa_name" {
  type = string
  default = "ig-sa"
  description = "Ig Service account name"
}

variable "deploy-user" {
  description = "Login для пользователя"
  type = string
  nullable = false
  sensitive = true
}

variable "deploy-user-key" {
  description = "Публичный ключ для пользователя"
  type = string
  nullable = false
  sensitive = true
}
