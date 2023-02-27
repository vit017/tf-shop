resource "null_resource" "docker-swarm-manager" {
  count = var.managers
  depends_on = [yandex_compute_instance.vm-manager]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-manager[count.index].network_interface.0.nat_ip_address
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "~/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com | sh",
      "sudo usermod -aG docker $USER",
      "sudo apt install -y docker-compose",
      "sudo docker swarm init",
      "sleep 10",
      "echo COMPLETED"
    ]
  }
}

resource "null_resource" "docker-swarm-manager-join" {
  count = var.managers
  depends_on = [yandex_compute_instance.vm-manager, null_resource.docker-swarm-manager]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-manager[count.index].network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "TOKEN=$(docker swarm join-token -q worker)",
      "echo \"#!/usr/bin/env bash\nsudo docker swarm join --token $TOKEN ${yandex_compute_instance.vm-manager[count.index].network_interface.0.nat_ip_address}:2377\nexit 0\" >| join.sh"
    ]
  }
}

resource "null_resource" "docker-swarm-worker" {
  count = var.workers
  depends_on = [yandex_compute_instance.vm-worker, null_resource.docker-swarm-manager-join]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-worker[count.index].network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com | sh",
      "sudo usermod -aG docker $USER",
      "cat ~/join.sh",
      "chmod +x ~/join.sh",
      "~/join.sh"
    ]
  }
}

resource "null_resource" "docker-swarm-manager-start" {
  depends_on = [yandex_compute_instance.vm-manager, null_resource.docker-swarm-manager-join]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-manager[0].network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "docker stack deploy --compose-file ~/docker-compose.yml sockshop-swarm"
    ]
  }
}