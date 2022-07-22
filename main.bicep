@description('The location to deploy the Cosmos DB account to. Default value is the location of the resource group.')
param location string = resourceGroup().location

@description('Name of our application')
param applicationName string = uniqueString((resourceGroup().id))

@description('Name of our Cosmos DB account that will be deployed')
@maxLength(44)
param cosmosDbAccountName string = '${applicationName}db'

@description('The default consistency level of the Cosmos DB account.')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param defaultConsistencyLevel string = 'Session'

@description('The name for the database')
param databaseName string = 'OrdersDB'

@description('The name for the container')
param containerName string = 'orders'

@description('The maximum amount of throughput to provision on this container')
@minValue(4000)
@maxValue(10000)
param maxThroughput int = 4000

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15-preview' = {
  name: cosmosDbAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard' 
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15-preview' = {
  name: databaseName
  parent: cosmosAccount
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15-preview' = {
  name:containerName
  parent: database
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
    options: {
      autoscaleSettings: {
        maxThroughput: maxThroughput
      }
    }
  }
}
