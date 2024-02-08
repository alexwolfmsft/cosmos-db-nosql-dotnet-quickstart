metadata description = 'Create role assignment and definition resources.'

param databaseAccountName string

@description('Id of the service principals to assign database and application roles.')
param appPrincipalId string = ''

@description('Id of the user principals to assign database and application roles.')
param userPrincipalId string = ''

resource database 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' existing = {
  name: databaseAccountName
}

param roleDefId string = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

// module tableDefinition '../core/database/cosmos-db/table/role/definition.bicep' = {
//   name: 'table-role-definition'
//   params: {
//     targetAccountName: database.name // Existing account
//     definitionName: 'Write to Azure Cosmos DB for table data plane' // Custom role name
//     permissionsNonDataActions:[
//     ]
//     permissionsDataActions: [
//       'Microsoft.Storage/storageAccounts/tableServices/tables/entities/read'
//       'Microsoft.Storage/storageAccounts/tableServices/tables/entities/write'
//       'Microsoft.Storage/storageAccounts/tableServices/tables/entities/delete'
//       'Microsoft.Storage/storageAccounts/tableServices/tables/entities/add/action'
//       'Microsoft.Storage/storageAccounts/tableServices/tables/entities/update/action'
//     ]
//   }
// }

module tableAppAssignment '../core/database/cosmos-db/table/role/assignment.bicep' = if (!empty(appPrincipalId)) {
  name: 'table-role-assignment-app'
  params: {
    targetAccountName: database.name // Existing account
    roleDefinitionId: roleDefId // New role definition
    principalId: appPrincipalId // Principal to assign role
  }
}

module tableUserAssignment '../core/database/cosmos-db/table/role/assignment.bicep' = if (!empty(userPrincipalId)) {
  name: 'table-role-assignment-user'
  params: {
    targetAccountName: database.name // Existing account
    roleDefinitionId: roleDefId // New role definition
    principalId: userPrincipalId ?? '' // Principal to assign role
  }
}

module registryUserAssignment '../core/security/role/assignment.bicep' = if (!empty(userPrincipalId)) {
  name: 'container-registry-role-assignment-push-user'
  params: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec') // AcrPush built-in role
    principalId: userPrincipalId // Principal to assign role
    principalType: 'User' // Current deployment user
  }
}

// output roleDefinitions object = {
//   table: tableDefinition.outputs.id
// }

output roleAssignments array = union(
  !empty(appPrincipalId) ? [ tableAppAssignment.outputs.id ] : [],
  !empty(userPrincipalId) ? [ tableUserAssignment.outputs.id, registryUserAssignment.outputs.id ] : []
)
