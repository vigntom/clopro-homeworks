resource "yandex_vpc_network" "clopro" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "public" {
  name           = var.public_subnet.name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = var.public_subnet.cidr
}

resource "yandex_vpc_subnet" "private" {
  name           = var.private_subnet.name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = var.private_subnet.cidr
}

resource "yandex_compute_instance" "public" {
  name        = var.public_vm
  platform_id = var.vm_config.platform
  allow_stopping_for_update = true

  resources {
    cores         = var.vm_config.cpu
    memory        = var.vm_config.memory
    core_fraction = var.vm_config.fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
    ip_address = var.public_vm_ip
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_compute_instance" "private" {
  name        = var.protected_vm
  platform_id = var.vm_config.platform
  allow_stopping_for_update = true

  resources {
    cores         = var.vm_config.cpu
    memory        = var.vm_config.memory
    core_fraction = var.vm_config.fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_vpc_route_table" "private-nat" {
  network_id = yandex_vpc_network.clopro.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.public_vm_ip
  }
}
