# create an ansible inventory file
resource "null_resource" "ansible-provision" {

  depends_on = [aws_instance.k8s-master, aws_instance.k8s-node]

  ##Create Masters Inventory
  provisioner "local-exec" {
    command = "echo \"[kube-masters]\" > ../ansible/inventories/hosts-k8s"
  }
  provisioner "local-exec" {
    command = "echo \"${join("\n", formatlist("%s ansible_ssh_host=%s", aws_instance.k8s-master.*.tags.Name, aws_instance.k8s-master.*.public_ip))}\" >> ../ansible/inventories/hosts-k8s"
  }

  ##Create ETCD Inventory
  provisioner "local-exec" {
    command = "echo \"\n[etcd]\" >> ../ansible/inventories/hosts-k8s"
  }
  provisioner "local-exec" {
    command = "echo \"${join("\n", formatlist("%s ansible_ssh_host=%s", aws_instance.k8s-master.*.tags.Name, aws_instance.k8s-master.*.public_ip))}\" >> ../ansible/inventories/hosts-k8s"
  }

  ##Create Nodes Inventory
  provisioner "local-exec" {
    command = "echo \"\n[kube-nodes]\" >> ../ansible/inventories/hosts-k8s"
  }
  provisioner "local-exec" {
    command = "echo \"${join("\n", formatlist("%s ansible_ssh_host=%s", aws_instance.k8s-node.*.tags.Name, aws_instance.k8s-node.*.public_ip))}\" >> ../ansible/inventories/hosts-k8s"
  }

  provisioner "local-exec" {
    command = "echo \"\n[k8s-cluster:children]\nkube-nodes\nkube-masters\" >> ../ansible/inventories/hosts-k8s"
  }
}