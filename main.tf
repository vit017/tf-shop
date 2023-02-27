terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.82.0"
    }
  }
}
provider "yandex" {
  token                    = "y0_AgAAAABoU1ULAATuwQAAAADdTZABYPr3UDVNSW-vVT0ekfIcYMTUA3o"
  cloud_id                 = "b1gtnh7joibadt3ak23b"
  folder_id                = "b1g2dbf4td7db1lu2hmr"
  zone                     = "ru-central1-a"
}

resource "yandex_vpc_network" "network" {
  name = "swarm-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

module "swarm_cluster" {
  source        = "./modules/instance"
  vpc_subnet_id = yandex_vpc_subnet.subnet.id
  managers      = 1
  workers       = 2
}