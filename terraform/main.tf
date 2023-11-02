terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


provider "yandex" {
  token     = "0000"
  cloud_id  = "0000"
  folder_id = "0000"
  zone      = "ru-central1-a"
}

#Бастион хост

resource "yandex_compute_instance" "bastion" {
  name  = "bastion"
  zone  = yandex_vpc_subnet.mysubnet-c.zone
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size     = 10
    }
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.mysubnet-c.id}"
    nat = true
    ipv4 = true
    ip_address = "10.100.50.10"

    security_group_ids = [ 
      yandex_vpc_security_group.ssh-access.id, 
      ]
    }
}
#Elasticsearch хост
resource "yandex_compute_instance" "elasticsearch" {
  name  = "elastsicsearch"
  zone  = yandex_vpc_subnet.mysubnet-b.zone
  resources {
    cores         = 2
    memory        = 6
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size     = 10
    }
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.mysubnet-b.id}"
    ipv4 = true
    ip_address = "10.100.40.20"

    security_group_ids = [ 
      yandex_vpc_security_group.ssh-access-local.id,
      yandex_vpc_security_group.elasticsearch-service.id,
      yandex_vpc_security_group.kibana-service.id,
      yandex_vpc_security_group.filebeat-service.id
      ]
  }
}

# Zabbix - server
resource "yandex_compute_instance" "zabbix" {
  name  = "zabbix"
  zone  = yandex_vpc_subnet.mysubnet-c.zone
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size     = 10
    }
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
  network_interface {
    subnet_id = "${yandex_vpc_subnet.mysubnet-c.id}"
    nat = true
    ipv4 = true
    ip_address = "10.100.50.15"

    security_group_ids = [ 
      yandex_vpc_security_group.ssh-access-local.id,
      yandex_vpc_security_group.zabbix-service.id
      ]
  }
}

# Kibana
resource "yandex_compute_instance" "kibana" {
  name  = "kibana"
  zone  = yandex_vpc_subnet.mysubnet-c.zone
  resources {
    cores         = 2
    memory        = 6
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size     = 10
    }
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
  network_interface {
    subnet_id = "${yandex_vpc_subnet.mysubnet-c.id}"
    nat = true
    ipv4 = true
    ip_address = "10.100.50.21"

    security_group_ids = [ 
      yandex_vpc_security_group.ssh-access-local.id,
      yandex_vpc_security_group.kibana-service.id,
      yandex_vpc_security_group.elasticsearch-service.id,
      yandex_vpc_security_group.filebeat-service.id
      ]
  }
}

# nginx 1 - WEB1
resource "yandex_compute_instance" "nginx1" {
  name  = "web1"
  zone  = yandex_vpc_subnet.mysubnet-b.zone
  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size     = 10
    }
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.mysubnet-b.id}"
    nat = false
    ipv4 = true
    ip_address = "10.100.40.10"

    security_group_ids = [ 
      yandex_vpc_security_group.ssh-access-local.id,
      yandex_vpc_security_group.nginx-service.id,
      yandex_vpc_security_group.filebeat-service.id
      ]
  }
}

#nginx2 - WEB2
resource "yandex_compute_instance" "nginx2" {
  name  = "web2"
  zone  = yandex_vpc_subnet.mysubnet-a.zone
  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size     = 10
    }
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.mysubnet-a.id}"
    ipv4 = true
    ip_address = "10.100.30.10"

    security_group_ids = [ 
      yandex_vpc_security_group.ssh-access-local.id,
      yandex_vpc_security_group.nginx-service.id,
      yandex_vpc_security_group.filebeat-service.id
      ]
  }
}


# Network
resource "yandex_vpc_network" "network-main" {
  name = "diplom-network"
}

resource "yandex_vpc_subnet" "mysubnet-a" {
  v4_cidr_blocks = ["10.100.30.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-main.id
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "mysubnet-b" {
  v4_cidr_blocks = ["10.100.40.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-main.id
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "mysubnet-c" {
  v4_cidr_blocks = ["10.100.50.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network-main.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "gateway-diplom"
  shared_egress_gateway {}
}
resource "yandex_vpc_route_table" "rt" {
  network_id     = yandex_vpc_network.network-main.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}


# security groups

resource "yandex_vpc_security_group" "ssh-access" {
  name        = "ssh-access for bastion"
  description = "security groups for bastion"
  network_id  = yandex_vpc_network.network-main.id

  ingress {
    protocol       = "TCP"
    description    = "Incoming tcp traffic to port 22 from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
    egress {
    protocol       = "ANY"
    description    = "Outgoing tcp traffic to port 22 from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
  ingress {
    protocol       = "TCP"
    description    = "Incoming tcp traffic to port 22 for security groups"
    security_group_id = yandex_vpc_security_group.ssh-access-local.id
    port           = 22
  }
  egress {
    protocol       = "TCP"
    description    = "Outgoing tcp traffic to port 22 for security groups"
    port           = 22
    security_group_id = yandex_vpc_security_group.ssh-access-local.id
} 
}

resource "yandex_vpc_security_group" "ssh-access-local" {
  name        = "ssh-access for localhost"
  description = "Security group for local SSH connection"
  network_id  = yandex_vpc_network.network-main.id

  ingress {
    protocol       = "TCP"
    description    = "Incoming tcp traffic to port 22 for local ip"
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
    port           = 22
  }
  egress {
    protocol       = "TCP"
    description    = "Outgoing tcp traffic to port 22 for local ip"
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
    port           = 22
  } 
  egress {
    protocol       = "ANY"
    description    = "Outgoing for any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "nginx-service" {
  name        = "nginx-service"
  description = "Security group for web-server"
  network_id  = yandex_vpc_network.network-main.id

  ingress {
    protocol       = "ANY"
    description    = "Incoming on port 80"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    protocol       = "ANY"
    description    = "Incoming on port 10050 for zabbix"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    protocol       = "ANY"
    description    = "Outgoing from port 80"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    protocol       = "ANY"
    description    = "Outgoing from port 10050 for zabbix"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
}

}

resource "yandex_vpc_security_group" "elasticsearch-service" {
  name        = "elasticsearch-service"
  description = "Security group for elastic"
  network_id  = yandex_vpc_network.network-main.id

  ingress {
    protocol       = "TCP"
    description    = "Incoming for elastic"
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
    port           = 9200
  }

ingress {
    protocol       = "ANY"
    description    = "Incoming for zabbix"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    protocol       = "TCP"
    description    = "Outgoing for elastic"
    port           = 9200
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
}

  egress {
    protocol       = "ANY"
    description    = "Outgoing from port 10050 for zabbix"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
}

}


resource "yandex_vpc_security_group" "zabbix-service" {
  name        = "zabbix-service"
  description = "Security group for zabbix"
  network_id  = yandex_vpc_network.network-main.id

  ingress {
    protocol       = "TCP"
    description    = "Incoming traffic from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Incoming traffic from zabbix"
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    description    = "Incoming traffic from zabbix"
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
    port           = 10051
  }

    egress {
    protocol       = "TCP"
    description    = "Outcoming traffic from any ip"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
}

    egress {
    protocol       = "TCP"
    description    = "Outcoming traffic from zabbix"
    port           = 10050
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
}

  egress {
    protocol       = "TCP"
    description    = "Outcoming traffic from zabbix"
    port           = 10051
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
  }
}


resource "yandex_vpc_security_group" "kibana-service" {
  name        = "kibana-service"
  description = "Security group for kibana"
  network_id  = yandex_vpc_network.network-main.id

ingress {
    protocol       = "ANY"
    description    = "Incoming traffic for zabbix"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
    protocol       = "TCP"
    description    = "Incoming traffic for kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  egress {
    protocol       = "ANY"
    description    = "Outcoming traffic from zabbix"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
}
  egress {
    protocol       = "TCP"
    description    = "Outcoming traffic from kibana"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
}
}

resource "yandex_vpc_security_group" "filebeat-service" {
  name        = "filebeat service"
  description = "Security group for filebeat"
  network_id  = yandex_vpc_network.network-main.id

  ingress {
    protocol       = "TCP"
    description    = "Incoming traffic for filebeat"
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
    port           = 5044
  }
  egress {
    protocol       = "TCP"
    description    = "Outcoming traffic for filebeat"
    port           = 5044
    v4_cidr_blocks = ["10.100.30.0/24", "10.100.40.0/24", "10.100.50.0/24"]
}
}

# target group

resource "yandex_alb_target_group" "group-1"{
  name = "group1"

  target {
    subnet_id = "${yandex_vpc_subnet.mysubnet-b.id}"
    ip_address   = "${yandex_compute_instance.nginx1.network_interface.0.ip_address}"
  } 

  target {
    subnet_id = "${yandex_vpc_subnet.mysubnet-a.id}"
    ip_address   = "${yandex_compute_instance.nginx2.network_interface.0.ip_address}"
  }  

}

# backend group

resource "yandex_alb_backend_group" "backend-group" {
  name = "backend-group"
  session_affinity {
    connection {
      source_ip = false
    }
  }

  http_backend {
    name                   = "backend"
    weight                 = 1
    port                   = 80
    target_group_ids       = ["${yandex_alb_target_group.group-1.id}"]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

# rourer

resource "yandex_alb_http_router" "tf-router" {
  name   = "router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "my-virtual-host" {
  name = "myvirtualhost"
  http_router_id = yandex_alb_http_router.tf-router.id
  route {
    name = "my-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend-group.id
        timeout          = "3s"
      }
    }
  }
}    

# load balancer
 resource "yandex_alb_load_balancer" "test-balancer" {
  name = "balancer"
  network_id  = "${yandex_vpc_network.network-main.id}"
  allocation_policy {
    location {
      zone_id   = "${yandex_vpc_subnet.mysubnet-c.zone}"
      subnet_id = yandex_vpc_subnet.mysubnet-c.id
    }
  }

  listener {
    name = "lsnrport"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.tf-router.id
      }
    }
  }
}

# snaphots
resource "yandex_compute_snapshot" "snapshot-bastion" {
  name = "bastion-snapshot"
  source_disk_id = "${yandex_compute_instance.bastion.boot_disk.0.disk_id}"
}

resource "yandex_compute_snapshot" "snapshot-elastic" {
  name = "elasticsearch-snapshot"
  source_disk_id = "${yandex_compute_instance.elasticsearch.boot_disk.0.disk_id}"
}
resource "yandex_compute_snapshot" "snapshot-zabbix" {
  name = "zabbix-snapshot"
  source_disk_id = "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}"
}
resource "yandex_compute_snapshot" "snapshot-libana" {
  name = "kibana-snapshot"
  source_disk_id = "${yandex_compute_instance.kibana.boot_disk.0.disk_id}"
}
resource "yandex_compute_snapshot" "snapshot-web1" {
  name = "web1-snapshot"
  source_disk_id = "${yandex_compute_instance.nginx1.boot_disk.0.disk_id}"
}
resource "yandex_compute_snapshot" "snapshot-web2" {
  name = "web2-snapshot"
  source_disk_id = "${yandex_compute_instance.nginx2.boot_disk.0.disk_id}"
}

# sheduler
resource "yandex_compute_snapshot_schedule" "default" {
  name = "snapshots"
  schedule_policy {
    expression = "0 0 ? * *"
  }
  snapshot_count = 7
  snapshot_spec {
      description = "snapshot-description"
      labels = {
        snapshot-label = "snapshot-label-value"
      }
  }
  labels = {
    my-label = "label-value"
  }
  disk_ids = ["${yandex_compute_instance.bastion.boot_disk.0.disk_id}", "${yandex_compute_instance.elasticsearch.boot_disk.0.disk_id}", "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}", "${yandex_compute_instance.kibana.boot_disk.0.disk_id}", "${yandex_compute_instance.nginx1.boot_disk.0.disk_id}", "${yandex_compute_instance.nginx2.boot_disk.0.disk_id}"]
}

# resource "yandex_compute_snapshot_schedule" "project_snapshot_schedule" {
#   name           = "project-snapshot-schedule"
#   description    = "snapshots every day shelf life 7 days"

#   schedule_policy {
#     expression = "10 0 ? * *"
#   }

#   retention_period = "168h"

#   snapshot_spec {
#     description = "retention-snapshot"

#   }

#  disk_ids = ["${yandex_compute_instance.bastion.boot_disk.0.disk_id}", "${yandex_compute_instance.elasticsearch.boot_disk.0.disk_id}", "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}", "${yandex_compute_instance.kibana.boot_disk.0.disk_id}", "${yandex_compute_instance.web1.boot_disk.0.disk_id}", "${yandex_compute_instance.web2.boot_disk.0.disk_id}"]

  
#   depends_on = [
#      yandex_compute_instance.bastion,
#      yandex_compute_instance.elasticsearch,
#      yandex_compute_instance.zabbix,
#      yandex_compute_instance.kibana,
#      yandex_compute_instance.web1,
#      yandex_compute_instance.web2,
#   ]
# }
