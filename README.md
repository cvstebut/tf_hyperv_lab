# tf_hyperv_lab
Creation and basic configuration of a set of lab vms using terraform hyperv provider

## No confidential data in repository

- .gitignore file includes an exclusion of .tfstate and .terraform directories
- Terraform state is kept remotely in an azure storage account. 
   </br>This allows running the configuration from different hosts, e.g. as part of a jenkins job.
- Remote state backend parameters are provided using a partial configuration file that is used during "terraform init"
- The Hyper-V provider (-> taliensins) is configured using environment variables
- All confidential data is kept in files in a directory ~/.ci/tf/..., allowing for easy backup

### Notes
- The blob used for storing state (-> tf_hyperv_lab.terraform.tfstate) does not have to exist before first "terraform apply" - it will be automatically created
- terraform init -backend-config=~/.ci... crashed. Workaround: Using absolute path (/home/ansible/.ci/...)

### azurerm Backend Configuration (Partial Configuration File)

/home/ansible/.ci/tf/tf_partialconfig_azurerm_dev
```
storage_account_name = "namolabstftfstorage01"
container_name       = "tfstate"
key                  = "tf_hyperv_lab.terraform.tfstate"
sas_token = "<SAS-TOKEN (full access on storage account)>"
```

### hyperv Provider Configuration (Environment Variables)

~/.ci/tf/tf_provider_hyperv_cvs004
```
export HYPERV_PASSWORD=<PASSWORD>
export HYPERV_USER=domain\\username
export HYPERV_HOST=<IP_OF_HOST>
export HYPERV_HTTPS=false
export HYPERV_INSECURE=true
export HYPERV_SCRIPT_PATH="c:/terraform/tmp"
export HYPERV_PORT=5985
export HYPERV_USE_NTLM=true
```

```console
source ~/.ci/tf/tf_provider_hyperv_cvs004
```

```console
ansible@cvs004:~/tf/tf_hyperv_lab$ terraform init -backend-config=/home/ansible/.ci/tf/tf_partialconfig_azurerm_dev 

Initializing the backend...

Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding github.com/taliesins/hyperv versions matching "1.0.0"...
- Installing github.com/taliesins/hyperv v1.0.0...
- Installed github.com/taliesins/hyperv v1.0.0 (unauthenticated)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ansible@cvs004:~/tf/tf_hyperv_lab$ terraform apply -auto-approve
hyperv_network_switch.lab_switch: Creating...
hyperv_network_switch.lab_switch: Still creating... [10s elapsed]
hyperv_network_switch.lab_switch: Still creating... [20s elapsed]
hyperv_network_switch.lab_switch: Creation complete after 25s [id=demo2]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## Create Ubuntu 2004 Server

Search for image on https://app.vagrantup.com/boxes/search

Candidate: generic/ubuntu2004

### On Hyper-V server

Set VAGRANT_HOME as desired (e.g. VAGRANT_HOME=m:\vagrant.d)

```console
vagrant box add generic/ubuntu2004 --provider hyperv
```

vhdx-file will be available at "M:\vagrant.d\boxes\generic-VAGRANTSLASH-ubuntu2004\3.0.24\hyperv\Virtual Hard Disks\generic-ubuntu2004-hyperv.vhdx"

## make deploy - deploy provider to local terraform provider path (ok for 0.13)

[terraform - Third-party Providers](https://www.hashicorp.com/blog/automatic-installation-of-third-party-providers-with-terraform-0-13/)

The provider needs to be copied to 
$PLUGIN_DIRECTORY/$SOURCEHOSTNAME/$SOURCENAMESPACE/$NAME/$VERSION/$OS_$ARCH/

new "deploy" target in GNUMakefile


```make
...

PROVIDERVERSION?="1.0.1"
PROVIDERTARGETDIRECTORY?="/home/ansible/.terraform.d/plugins/github.com/cvstebut/hyperv/$(PROVIDERVERSION)/linux_amd64"

...

deploy:
	@echo "target: $(PROVIDERTARGETDIRECTORY)/terraform-provider-hyperv_$(PROVIDERVERSION)"
	@mkdir -p $(PROVIDERTARGETDIRECTORY)
	go build -o $(PROVIDERTARGETDIRECTORY)/terraform-provider-hyperv_$(PROVIDERVERSION)

```

## init terraform directory 

```console
source  ~/.ci/tf/tf_provider_hyperv_cvs004


terraform init -backend-config=/home/ansible/.ci/tf/tf_partialconfig_azurerm_dev

Initializing the backend...

Initializing provider plugins...
- Finding github.com/cvstebut/hyperv versions matching "1.0.1"...
- Installing github.com/cvstebut/hyperv v1.0.1...
- Installed github.com/cvstebut/hyperv v1.0.1 (unauthenticated)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```



## notes

terraform show -json | jq -c 'paths | select(.[-1] == "name")'

terraform show -json | jq '.values.root_module.resources[] | .values.network_adaptors[] | .ip_addresses'