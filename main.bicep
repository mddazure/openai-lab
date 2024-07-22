param location string = 'swedencentral'
param rgname string = 'openai-rg'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-Datacenter'
var clientimagePublisher = 'microsoftwindowsdesktop'
var clientimageOffer = 'windows-11'
var clientimageSku = 'win11-22h2-pro'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgname
  location: location
}

module clientvnet 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'clientvnet'
  scope: rg
  dependsOn:[
    clientnsg
  ]
  params: {
    name: 'clientvnet'
    addressPrefixes: [
      '172.16.0.0/16' 
      'abcd:de12:7890::/48'
    ]
    subnets: [
      {
        addressPrefix: '172.16.0.0/24'
        name: 'vmsubnet0'
        networkSecurityGroupResourceId: clientnsg.outputs.resourceId
      }
      {
        addressPrefix: '172.16.254.0/24'
        name: 'AzureBastionSubnet'
      }
      {
        addressPrefix: '172.16.255.0/24'
        name: 'GatewaySubnet'
      }
    ]
  }
}

module clientnsg 'br/public:avm/res/network/network-security-group:0.3.0' = {
  scope: rg
  name: 'clientnsg'
  params: {
    name: 'clientnsg'
    securityRules: [
      {
      name: 'AllowRDPInbound'
      properties: {
        access: 'Allow'
        description: 'Allow RDP inbound traffic'
        destinationAddressPrefix: '*'
        destinationPortRange: '3389'
        direction: 'Inbound'
        priority: 100
        protocol: 'Tcp'
        sourceAddressPrefix: '172.16.254.0/24'
        sourcePortRange: '*'
        }
      }
    ]
    }
}

module clientvm 'br/public:avm/res/compute/virtual-machine:0.5.1' = {
  scope: rg
  name: 'clientvm'
  params: {
    encryptionAtHost: false
    adminUsername: 'marc'
    adminPassword: 'Nienke040598'
    imageReference: {
      publisher: clientimagePublisher
      offer: clientimageOffer
      sku: clientimageSku
      version: 'latest'
    }
    name: 'clientvm'
    nicConfigurations: [
      {
        ipconfigurations: [
          {
          name: 'ipconfig1'
          subnetresourceid: clientvnet.outputs.subnetResourceIds[0]
          publicIpAddressId: clientpipv4.outputs.resourceId
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
      
    
    osDisk: {
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS2_v2'
    zone: 1  
  }
}
module bastion 'br/public:avm/res/network/bastion-host:0.2.1' = {
  scope: rg
  name: 'bastion'
  params: {
    name: 'bastion'
    virtualNetworkResourceId: clientvnet.outputs.resourceId
    skuName: 'Standard'
    enableIpConnect: true
    enableShareableLink: true
  }
}

module prefixv4 'br/public:avm/res/network/public-ip-prefix:0.3.0' = {
  scope: rg
  name: 'prefixv4'
  params: {
    name: 'prefixv4'
    prefixLength: 30
  }
}

module clientpipv4 'br/public:avm/res/network/public-ip-address:0.4.1' = {
  scope: rg
  name: 'clientpipv4'
  params: {
    name: 'clientpipv4'
    publicIPAddressVersion: 'IPv4'
    publicIpPrefixResourceId: prefixv4.outputs.resourceId
    skuName: 'Standard'
    skuTier: 'Regional'
  }
}


