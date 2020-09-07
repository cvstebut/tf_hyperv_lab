variable "lab_counts" {
    type = map(number)
    default = {
        "node" = 2
        "datadisk" = 3
    }
}

variable "lab_name" {
    type = string
    description = "Lab name will be used to create base vm path"
    default = "ciboot.00"
}

variable "lab_prefix" {
    type = string
    description = "short prefix for vm names"
    default = "00."
}

variable "lab_vm_notes" {
    type = string
    description = "Description added to VM's notes"
    default = "CI-BOOT - Bootstrapping CI infrastructure k8s cluster"
}

variable "vm_memory_static" {
    type = bool
    default = true
}

variable "vm_memory_settings" {
    type = map(number)
    default = {
        startup_bytes = 8589934592 //2147483648
    }
}

variable "lab_base_path" {
    type = string
    description = "Base path for all labs"
    default = "m:\\namolabs"
}

variable "box_source" {
    type = string
    default = "m:/vagrant.d/boxes/bento-VAGRANTSLASH-ubuntu-20.04/202005.21.0/hyperv/Virtual Hard Disks/ubuntu-20.04-amd64.vhdx"
}

variable "data_disk_size" {
    type = number
    description = "size of data disks in byte"
    default = 21474836480 // 20 GB 10737418240 #10GB
}

variable "net_switch_name" {
    type = string
    description = "name of hyper-v switch to connect to"
    default = "labs"
}