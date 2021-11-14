  provisioner "file" {
    source      = "./prometheus.yml"
    destination = "/tmp/prometheus.yml"
  }

provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo mkdir /prometheus-data",
      "sudo cp /tmp/prometheus.yml /prometheus-data/.",
      "sudo docker run -d -p 9090:9090 --name=prometheus -v /prometheus-data/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus",
    ]
  }
