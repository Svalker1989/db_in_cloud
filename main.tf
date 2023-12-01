#Блок подключения к yandex cloud через terraform provider
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
#Указываем параметры подключения к облаку. Получил эти параметры через yc init
provider "yandex" {
  token     = "y0_AgAAAAATmoj0AATuwQAAAADkYIVtEZtVm3gCSq-eEjgVP7QZr_efYHk"
  cloud_id  = "b1gl328j72hoingknj27"
  folder_id = "b1gcqjd2qv0nc6pk0mhv"
  zone      = "ru-central1-a"
}

resource "yandex_mdb_postgresql_cluster" "str_psgdb_cluster" {
  name                = "str_psgdb_cluster"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.psg-net.id
  security_group_ids  = [ yandex_vpc_security_group.psg-sg.id ]
  deletion_protection = false

  config {
    version = "16"
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = "20"
    }
  }

  host {
    zone             = "ru-central1-a"
    name             = "psg-host-a"
    subnet_id        = yandex_vpc_subnet.psg-subnet-a.id
    assign_public_ip = true
  }
  host {
    zone             = "ru-central1-b"
    name             = "psg-host-b"
    subnet_id        = yandex_vpc_subnet.psg-subnet-b.id
    assign_public_ip = true
  }
}

resource "yandex_mdb_postgresql_database" "str_psg_db" {
  cluster_id = yandex_mdb_postgresql_cluster.str_psgdb_cluster.id
  name       = "str_psg_db"
  owner      = "str"
}

resource "yandex_mdb_postgresql_user" "str" {
  cluster_id = yandex_mdb_postgresql_cluster.str_psgdb_cluster.id
  name       = "str"
  password   = "qwertyui"
}

resource "yandex_vpc_network" "psg-net" { name = "psg-net" }

resource "yandex_vpc_subnet" "psg-subnet-a" {
  name           = "psg-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.psg-net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "psg-subnet-b" {
  name           = "psg-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.psg-net.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "yandex_vpc_security_group" "psg-sg" {
  name       = "psg-sg"
  network_id = yandex_vpc_network.psg-net.id

  ingress {
    description    = "PostgreSQL"
    port           = 6432
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}
