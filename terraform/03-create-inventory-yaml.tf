# create an ansible inventory file
resource "null_resource" "ansible-provision-yaml" {

  depends_on = [aws_instance.k8s-master, aws_instance.k8s-node]

  ## Create Masters Inventory
  provisioner "local-exec" {
    command = "echo \"all:\n  children:\n    kube-cluster:\n      children:\" > ../ansible/inventories/hosts-k8s.yml"
  }

  ## Create Masters Inventory

  provisioner "local-exec" {
    command = "echo \"        kube-masters:\n          hosts:\" >> ../ansible/inventories/hosts-k8s.yml"
  }

  provisioner "local-exec" {
    command = "echo \"${join("\n", formatlist("            %s:\n              ansible_host: %s",
    aws_instance.k8s-master.*.tags.Name, aws_instance.k8s-master.*.public_ip))}\" >> ../ansible/inventories/hosts-k8s.yml"
  }

  ## Create ETCD Inventory
  provisioner "local-exec" {
    command = "echo \"\n        etcd:\n          hosts:\" >> ../ansible/inventories/hosts-k8s.yml"
  }
  provisioner "local-exec" {
    command = "echo \"${join("\n", formatlist("            %s:\n              ansible_host: %s",
    aws_instance.k8s-master.*.tags.Name, aws_instance.k8s-master.*.public_ip))}\" >> ../ansible/inventories/hosts-k8s.yml"
  }

  ## Create Nodes Inventory
  provisioner "local-exec" {
    command = "echo \"\n        kube-nodes:\n          hosts:\" >> ../ansible/inventories/hosts-k8s.yml"
  }
  provisioner "local-exec" {
    command = "echo \"${join("\n", formatlist("            %s:\n              ansible_host: %s",
    aws_instance.k8s-node.*.tags.Name, aws_instance.k8s-node.*.public_ip))}\" >> ../ansible/inventories/hosts-k8s.yml"
  }
}