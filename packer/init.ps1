az ad sp create-for-rbac --name packer-app --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"



packer build -var-file="packer.parameters.json" packer.json