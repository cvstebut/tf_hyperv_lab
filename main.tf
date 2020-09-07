terraform {
  backend "azurerm" {}
  required_providers {
    hyperv = {
      source  = "github.com/cvstebut/hyperv"
      version = "1.0.3"
    }
  }
}

locals {
    // generate names for vms and data disks
    // will be used in resource creation (e.g. paths)
    lab_names = {
        for name, count in var.lab_counts : name => [
            for i in range(count) : format("%s%02d", name, i + 1)
        ]
    }
    lab_names_product = setproduct(local.lab_names["node"], local.lab_names["datadisk"])
    lab_base_path = format("%s\\%s", var.lab_base_path, var.lab_name)
    box_source_path = var.box_source
    lab_prefix = var.lab_prefix
    data_disk_size = var.data_disk_size
    net_switch_name = var.net_switch_name
    vm_memory_static = var.vm_memory_static
    vm_memory_startup_bytes = var.vm_memory_settings["startup_bytes"]
    lab_notes = var.lab_vm_notes
    tf_project_name = "tf_hyperv_dev (github)"
}

resource "hyperv_vhd" "os_disk" {
  count  = length(local.lab_names["node"])
  path   = format("%s\\%s\\os.vhdx", local.lab_base_path, element(local.lab_names["node"], count.index))
  source = local.box_source_path
}

resource "hyperv_vhd" "data_vhd" {
  count  = length(local.lab_names["node"]) * length(local.lab_names["datadisk"])
  path = format("%s\\%s\\%s.vhdx",local.lab_base_path, element(local.lab_names_product, count.index)[0], element(local.lab_names_product, count.index)[1]) 
  size = local.data_disk_size
}

resource "hyperv_machine_instance" "machine_instance" {
  count                      = length(local.lab_names["node"])
  name                       = format("%snode%02d", local.lab_prefix, count.index + 1)
  generation                 = 2
  automatic_start_action     = "StartIfRunning"
  memory_startup_bytes       = local.vm_memory_startup_bytes
  notes                      = format("node%02d - %s - Created with terraform - %s", count.index + 1, local.lab_notes, local.tf_project_name)
  processor_count            = 2
  static_memory              = local.vm_memory_static
  state                      = "Running"
  wait_for_state_timeout     = 600 // default: 120
  wait_for_state_poll_period = 2   // default: 2
  wait_for_ips_timeout       = 600 //default: 300
  wait_for_ips_poll_period   = 5   // default: 5

  network_adaptors {
    name         = local.net_switch_name
    switch_name  = local.net_switch_name
    wait_for_ips = true
    dynamic_mac_address = false
    static_mac_address = format("00155D040A%02X", count.index + 10)
  }

  // os-disk
  hard_disk_drives {
        controller_type     = "Scsi"
        path                = format("%s\\%s\\os.vhdx",local.lab_base_path,element(local.lab_names["node"], count.index) )
        controller_number   = 0
        controller_location = 0
  }

  // data-disk (e.g. for use with rook)
  dynamic "hard_disk_drives" {
    for_each = local.lab_names["datadisk"]
    content {
        controller_type     = "Scsi"
        path                = format("%s\\%s\\%s.vhdx",local.lab_base_path,element(local.lab_names["node"], count.index), hard_disk_drives.value )
        controller_number   = 0
        controller_location = hard_disk_drives.key + 1 // location 0: os disk
      }
  }
  
  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"
  }
}