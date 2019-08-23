locals {
  wordpress_app_ip = "209.166.132.253"
  wordpress_db_ip  = "209.166.132.254"
}



provider "vcd" {
  user                 = "abstractions-demo"
  password             = "UseTerraform!"
  org                  = "abstractions_demo"
  vdc                  = "abstractions_demo_vdc"
  url                  = "https://vcd-rc.expedient.com/api"
  allow_unverified_ssl = true
}

resource "vcd_vapp" "wordpress_app" {
  name = "wordpress_app"
}

resource "vcd_vapp" "wordpress_db" {
  name = "wordpress_db"
}

resource "vcd_vapp_vm" "wordpress_app" {
  vapp_name       = "wordpress_app"
  name            = "wordpress-app"
  catalog_name    = "abstractions-demo"
  template_name   = "ubuntu-16.04"
  memory          = 4096
  cpus            = 2
  cpu_cores       = 1

  initscript = "echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAG0yiSCgIJrT2jsDGjktq9P0a9s6LYCv3ATAib4JSJfRWt4Liov8ikmfvqn9+re8fI0hoOqaI9s69GYDe3zT+XijUngCn1s/4wxqwUt7uOFohk/yYnw4FD9kLJp8CAZUuUnREXjo0lbBxqtDckCaEXm4MnqNpdbOq0eyZRpFFySORSG0OLPRYNG3TqwVCfrA7dofC4zhel1Ewg2JK4fWp7SlquhSe2u3kcq8nDCndQGfo9fGNhAD/rw6ULxbzSinhwhzZuJ6i7l3zVhAd8zlQefq76FLle3lJ14lUcTUGodcxWW7w1BPhHzDH5oPycGAWx1km5X9o+kkzzNl38yi/ >> /home/ubuntu/.ssh/authorized_keys"


  metadata = {
    role = "app"
  }

  network {
    type               = "org"
    name               = "abstractions_demo_net"
    ip_allocation_mode = "POOL"
    is_primary         = true
  }


  depends_on = ["vcd_vapp.wordpress_app"]
}

resource "vcd_vapp_vm" "wordpress_db" {
  vapp_name         = "wordpress_db"
  name              = "wordpress-db"
  catalog_name      = "abstractions-demo"
  template_name     = "ubuntu-16.04"
  memory            = 4096
  cpus              = 2
  cpu_cores         = 1

  initscript = "echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAG0yiSCgIJrT2jsDGjktq9P0a9s6LYCv3ATAib4JSJfRWt4Liov8ikmfvqn9+re8fI0hoOqaI9s69GYDe3zT+XijUngCn1s/4wxqwUt7uOFohk/yYnw4FD9kLJp8CAZUuUnREXjo0lbBxqtDckCaEXm4MnqNpdbOq0eyZRpFFySORSG0OLPRYNG3TqwVCfrA7dofC4zhel1Ewg2JK4fWp7SlquhSe2u3kcq8nDCndQGfo9fGNhAD/rw6ULxbzSinhwhzZuJ6i7l3zVhAd8zlQefq76FLle3lJ14lUcTUGodcxWW7w1BPhHzDH5oPycGAWx1km5X9o+kkzzNl38yi/ >> /home/ubuntu/.ssh/authorized_keys"

  metadata = {
    role = "db"
  }

  network {
    type               = "org"
    name               = "abstractions_demo_net"
    ip_allocation_mode = "POOL"
    is_primary         = true
  }


  depends_on = ["vcd_vapp.wordpress_db"]
}

resource "vcd_dnat" "wordpress_app_nat" {
  edge_gateway    = "abstractions-demo-edge"
  port            = -1
  external_ip     = local.wordpress_app_ip
  internal_ip     = vcd_vapp_vm.wordpress_app.network[0].ip
  depends_on      = ["vcd_vapp_vm.wordpress_app"]
}

resource "vcd_dnat" "wordpress_db_nat" {
  edge_gateway    = "abstractions-demo-edge"
  port            = -1
  external_ip     = local.wordpress_db_ip
  internal_ip     = vcd_vapp_vm.wordpress_db.network[0].ip
  depends_on      = ["vcd_vapp_vm.wordpress_db"]
}

resource "vcd_firewall_rules" "fw" {
  edge_gateway      = "abstractions-demo-edge"
  default_action    = "drop"

  rule {
    description      = "allow-ssh-app"
    policy           = "allow"
    protocol         = "tcp"
    destination_port = "22"
    destination_ip   = local.wordpress_app_ip
    source_port      = "any"
    source_ip        = "any"
  }
  rule {
    description      = "allow-ssh-db"
    policy           = "allow"
    protocol         = "tcp"
    destination_port = "22"
    destination_ip   = local.wordpress_db_ip
    source_port      = "any"
    source_ip        = "any"
  }
  rule {
    description      = "allow-egress-all"
    policy           = "allow"
    protocol         = "any"
    destination_port = "any"
    destination_ip   = "any"
    source_port      = "any"
    source_ip        = "10.0.0.0/24"
  }
  rule {
    description      = "allow http for web server"
    policy           = "allow"
    protocol         = "tcp"
    destination_port = "80"
    destination_ip   = local.wordpress_app_ip
    source_port      = "any"
    source_ip        = "any"
  }
  rule {
    description      = "allow https for web server"
    policy           = "allow"
    protocol         = "tcp"
    destination_port = "443"
    destination_ip   = local.wordpress_app_ip
    source_port      = "any"
    source_ip        = "any"
  }
}

output "wordpress_db_address" {
  value = local.wordpress_db_ip
}

output "wordpress_db_private_address" {
  value = vcd_vapp_vm.wordpress_db.network[0].ip
}

output "wordpress_app_address" {
  value = local.wordpress_app_ip
}