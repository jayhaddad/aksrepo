### agic aks
rg=rg-aks0314v2
aksname=jhaks0314v2
az group create --name $rg --location centralus
az aks create -n $aksname -g $rg --network-plugin azure --enable-managed-identity


az network public-ip create -n myPublicIp -g $rg --allocation-method Static --sku Standard
az network vnet create -n myVnet -g $rg --address-prefix 11.0.0.0/8 --subnet-name mySubnet --subnet-prefix 11.1.0.0/16 
az network application-gateway create -n myApplicationGateway -l centralus -g $rg --sku Standard_v2 --public-ip-address myPublicIp --vnet-name myVnet --subnet mySubnet


appgwId=$(az network application-gateway show -n myApplicationGateway -g $rg -o tsv --query "id") 
az aks enable-addons -n $aksname -g $rg -a ingress-appgw --appgw-id $appgwId


nodeResourceGroup=$(az aks show -n $aksname -g $rg -o tsv --query "nodeResourceGroup")
aksVnetName=$(az network vnet list -g $nodeResourceGroup -o tsv --query "[0].name")

aksVnetId=$(az network vnet show -n $aksVnetName -g $nodeResourceGroup -o tsv --query "id")
az network vnet peering create -n AppGWtoAKSVnetPeering -g $rg --vnet-name myVnet --remote-vnet $aksVnetId --allow-vnet-access

appGWVnetId=$(az network vnet show -n myVnet -g $rg -o tsv --query "id")
az network vnet peering create -n AKStoAppGWVnetPeering -g $nodeResourceGroup --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

az aks get-credentials -n $aksname -g $rg
