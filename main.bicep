@description('Region to create resources')
param location string

@description('Prefix for all resources')
param prefix string

@description('Virtual Machine admin password')
param adminPassword string

// Virtual network
resource mainVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${prefix}-network'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

// Subnet
resource internalSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: 'internal'
  parent: mainVirtualNetwork
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}

// Public IP address
resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${prefix}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Main network interface
resource mainNetworkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${prefix}-nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'primary'
        properties: {
          subnet: {
            id: internalSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
}

// Internal network interface
resource internalNetworkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${prefix}-nic2'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          subnet: {
            id: internalSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

//security group
resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${prefix}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          priority: 100
        }
      }
    ]
  }
}

// Main network interface security group associatio
resource mainNetworkInterfaceAssociation 'Microsoft.Network/networkInterfaces/networkSecurityGroups@2021-02-01' = {
  name: '${prefix}-nic1-nsg'
  properties: {
    networkSecurityGroup: {
      id: securityGroup.id
    }
  }
}

// Virtual Machine
resource mainVirtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${prefix}-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: '${prefix}-vm'
      adminUsername: 'azureuser'
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: mainNetworkInterface.id
        }
      ]
    }
  }
}

// Output virtual network name
output virtualNetworkName string = mainVirtualNetwork.name
