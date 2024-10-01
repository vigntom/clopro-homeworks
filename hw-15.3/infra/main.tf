# resource "yandex_vpc_network" "clopro" {
#   name = var.vpc_name
# }

# resource "yandex_vpc_gateway" "private" {
#   name = "private"
#   shared_egress_gateway {}
# }

# resource "yandex_vpc_route_table" "private-nat" {
#   network_id = yandex_vpc_network.clopro.id
#   static_route {
#     destination_prefix = "0.0.0.0/0"
#     gateway_id = yandex_vpc_gateway.private.id
#   }
# }

# resource "yandex_vpc_subnet" "public" {
#   name           = var.public_subnet.name
#   zone           = var.default_zone
#   network_id     = yandex_vpc_network.clopro.id
#   v4_cidr_blocks = var.public_subnet.cidr
# }

# resource "yandex_vpc_subnet" "private" {
#   name           = var.private_subnet.name
#   zone           = var.default_zone
#   network_id     = yandex_vpc_network.clopro.id
#   v4_cidr_blocks = var.private_subnet.cidr
#   route_table_id = yandex_vpc_route_table.private-nat.id
# }

# resource "yandex_compute_instance" "public" {
#   name        = var.public_vm
#   platform_id = var.vm_config.platform
#   allow_stopping_for_update = true

#   resources {
#     cores         = var.vm_config.cpu
#     memory        = var.vm_config.memory
#     core_fraction = var.vm_config.fraction
#   }

#   boot_disk {
#     initialize_params {
#       image_id = var.image_id
#     }
#   }

#   scheduling_policy {
#     preemptible = true
#   }

#   network_interface {
#     subnet_id = yandex_vpc_subnet.public.id
#     nat       = true
#     ip_address = var.public_vm_ip
#   }

#   metadata = {
#     ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
#   }
# }

# resource "yandex_compute_instance" "private" {
#   name        = var.protected_vm
#   platform_id = var.vm_config.platform
#   allow_stopping_for_update = true

#   resources {
#     cores         = var.vm_config.cpu
#     memory        = var.vm_config.memory
#     core_fraction = var.vm_config.fraction
#   }

#   boot_disk {
#     initialize_params {
#       image_id = var.image_id
#     }
#   }

#   scheduling_policy {
#     preemptible = true
#   }

#   network_interface {
#     subnet_id = yandex_vpc_subnet.private.id
#     nat       = false
#   }

#   metadata = {
#     ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
#   }
# }

resource "yandex_iam_service_account" "storage_sa" {
  name = var.sa_name
}

resource "yandex_resourcemanager_folder_iam_member" "storage_sa_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "kms_sa_encrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypter"
  member    = "serviceAccount:${yandex_iam_service_account.storage_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.storage_sa.id
  description = "static access key"
}

resource "yandex_kms_symmetric_key" "clopro-kms-key" {
  name = "clopro-kms-key"
  description = "Clopro KMS key"
  default_algorithm = "AES_128"
  rotation_period = "8760h"
}

resource "yandex_storage_bucket" "public-clopro-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = var.bucket_name
  acl = "public-read"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.clopro-kms-key.id
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "my-pic" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = yandex_storage_bucket.public-clopro-bucket.bucket
  acl = "public-read"
  source = "static/me.jpg"
  key = "my-pic.jpg"

  tags = {
    source = "me.jpg"
  }
}

# Не нужно по ТЗ и очень долго удаляется

# resource "yandex_iam_service_account" "ig-sa" {
#   name = var.ig-sa_name
#   description = "Instance Group Service Account"
# }

# resource "yandex_resourcemanager_folder_iam_member" "ig-sa-admin" {
#   folder_id = var.folder_id
#   role      = "admin"
#   member    = "serviceAccount:${yandex_iam_service_account.ig-sa.id}"
# }

# resource "yandex_compute_instance_group" "ig-lemp" {
#   name = "lemp-ig"
#   folder_id = var.folder_id
#   service_account_id = yandex_iam_service_account.ig-sa.id
#   deletion_protection = false

#   instance_template {
#     platform_id = var.vm_config.platform

#     resources {
#       cores         = var.vm_config.cpu
#       memory        = var.vm_config.memory
#       core_fraction = var.vm_config.fraction
#     }

#     boot_disk {
#       initialize_params {
#         image_id = var.lemp_image_id
#       }
#     }

#     scheduling_policy {
#       preemptible = true
#     }

#     network_interface {
#       network_id = yandex_vpc_network.clopro.id
#       subnet_ids = [yandex_vpc_subnet.public.id]
#       nat       = true
#     }

#     metadata = {
#       user-data = templatefile("templates/cloud-init.yaml", {
#         bucket = yandex_storage_bucket.public-clopro-bucket.bucket
#         object-key = yandex_storage_object.cat-pic.key
#         deploy-user = var.deploy-user
#         deploy-user-key = var.deploy-user-key
#         hostname = "instance-{instance.short_id}-{instance.index}"
#       })
#     }
#   }

#   scale_policy {
#     fixed_scale {
#       size = 3
#     }
#   }

#   allocation_policy {
#     zones = [var.default_zone]
#   }

#   deploy_policy {
#     max_expansion = 2
#     max_unavailable = 2 
#     max_deleting = 2
#     max_creating = 2
#   }

#   load_balancer {
#     target_group_name = "lemp-target-group"
#     target_group_description = "LEMP target group"
#   }
  
#   health_check {
#     interval = 10
#     timeout = 5
#     unhealthy_threshold = 2
#     healthy_threshold = 2

#     http_options {
#       port = 80
#       path = "/index.html"
#     }
#   }
# }

# resource "yandex_lb_network_load_balancer" "lb" {
#   name = "clopro-lb"

#   listener {
#     name = "clopro-lb-listener"
#     port = 80
#     external_address_spec {
#       ip_version = "ipv4"
#     }
#   }

#   attached_target_group {
#     target_group_id = yandex_compute_instance_group.ig-lemp.load_balancer["0"].target_group_id

#     healthcheck {
#       name = "http"
#       interval = 10
#       timeout = 5
#       unhealthy_threshold = 2
#       healthy_threshold = 2
#       http_options {
#         port = 80
#         path = "/index.html"
#       }
#     }
#   }
# }
