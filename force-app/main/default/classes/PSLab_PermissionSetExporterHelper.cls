/**
 * @author       : Oumaima Arbani
 * @date         : 27-04-2025
 * @description  :
 * @group        : PSLab
 **/

public without sharing class PSLab_PermissionSetExporterHelper{


    public static List<PermissionSetInfo> getPermissionSets(){
        String setupDomain = URL.getOrgDomainUrl().toExternalForm()
                .replace('.my.salesforce.com', '.my.salesforce-setup.com');

        List<PermissionSetInfo> results = new List<PermissionSetInfo>();

        List<PermissionSet> rawPermissionSets = [
                SELECT Id, Name, Label, Description, Type, IsCustom,
                        CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate,
                (SELECT PermissionSetGroup.DeveloperName FROM PermissionSetGroupComponents)
                FROM PermissionSet
                WHERE Type IN ('Regular', 'Standard', 'Session')
                WITH SYSTEM_MODE
                ORDER BY Label ASC
        ];

        for(PermissionSet permissionSet : rawPermissionSets){
            PermissionSetInfo info = new PermissionSetInfo();
            info.Id = permissionSet.Id;
            info.label = permissionSet.Label + ' (' + permissionSet.Name + ')';
            info.value = permissionSet.Id;
            info.description = permissionSet.Description;
            info.createdBy = permissionSet.CreatedBy.Name;
            info.createdDate = permissionSet.CreatedDate;
            info.lastModifiedBy = permissionSet.LastModifiedBy.Name;
            info.lastModifiedDate = permissionSet.LastModifiedDate;
            info.isCustom = permissionSet.IsCustom;
            info.type = permissionSet.Type;
            info.assignedUsersURL = setupDomain + '/lightning/setup/PermSets/' + permissionSet.Id + '/PermissionSetAssignment/home';

            List<String> groupNames = new List<String>();
            if (permissionSet.PermissionSetGroupComponents != null) {
                for (PermissionSetGroupComponent permissionSetGroupComponent : permissionSet.PermissionSetGroupComponents) {
                    groupNames.add(permissionSetGroupComponent.PermissionSetGroup.DeveloperName);
                }
            }
            info.includedIn = String.join(groupNames, ', ');

            results.add(info);
        }

        return results;
    }


    public static String generateCSVHelper(Id permissionSetId, List<String> permissions) {
        Map<String, IPermissionCsvProvider> providers = new Map<String, IPermissionCsvProvider>{
                'ObjectPermissions'       => new ObjectPermissionProvider(),
                'FieldPermissions'        => new FieldPermissionProvider(),
                'TabSet'                  => new AppPermissionProvider(),
                'FlowDefinition'          => new FlowPermissionProvider(),
                'CustomMetadataType'      => new CustomMetadataProvider(),
                'CustomSetting'           => new CustomSettingProvider(),
                'ApexClass'               => new ApexClassProvider(),
                'ApexPage'                => new ApexPageProvider(),
                'CustomPermission'        => new CustomPermissionProvider(),
                'PermissionSetTabSetting' => new TabSettingProvider(),
                'PermissionSet'           => new SystemPermissionProvider()
        };

        List<String> rows = new List<String>();
        rows.add('PermissionType,Metadata,Details');

        for (String permType : permissions) {
            if (providers.containsKey(permType)) {
                rows.addAll(providers.get(permType).getCsvRows(permissionSetId));
            }
        }

        return String.join(rows, '\n');
    }

    /**
     * @description Interface for any class that provides CSV rows for a permission type.
     */
    private interface IPermissionCsvProvider {
        List<String> getCsvRows(Id permissionSetId);
    }


    private class ObjectPermissionProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            for(ObjectPermissions objectPermission : [
                    SELECT SobjectType, PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete,
                            PermissionsViewAllRecords, PermissionsModifyAllRecords, PermissionsViewAllFields
                    FROM ObjectPermissions WHERE ParentId = :permissionSetId WITH SYSTEM_MODE ORDER BY SobjectType ASC
            ]) {
                List<String> granted = new List<String>();
                if(objectPermission.PermissionsCreate) granted.add('Create');
                if(objectPermission.PermissionsRead) granted.add('Read');
                if(objectPermission.PermissionsEdit) granted.add('Edit');
                if(objectPermission.PermissionsDelete) granted.add('Delete');
                if(objectPermission.PermissionsViewAllRecords) granted.add('ViewAllRecords');
                if(objectPermission.PermissionsModifyAllRecords) granted.add('ModifyAllRecords');
                rows.add('Object,' + objectPermission.SobjectType + ',' + String.join(granted, '|'));
            }
            return rows;
        }
    }


    private class FieldPermissionProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            for(FieldPermissions fieldPermission : [
                    SELECT SobjectType, Field, PermissionsRead, PermissionsEdit
                    FROM FieldPermissions WHERE ParentId = :permissionSetId WITH SYSTEM_MODE ORDER BY SobjectType ASC, Field ASC
            ]) {
                List<String> granted = new List<String>();
                if(fieldPermission.PermissionsRead) granted.add('Read');
                if(fieldPermission.PermissionsEdit) granted.add('Edit');
                rows.add('Field,' + fieldPermission.Field + ',' + String.join(granted, '|'));
            }
            return rows;
        }
    }

    private class AppPermissionProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            Set<Id> appIds = getEntityIdsByPermissionSetId(permissionSetId, 'TabSet');
            if (appIds.isEmpty()) return rows;
            for(AppMenuItem app : [SELECT Name FROM AppMenuItem WHERE ApplicationId IN :appIds WITH SYSTEM_MODE]) {
                rows.add('Assigned Application,' + app.Name + ',');
            }
            return rows;
        }
    }


    private class ApexClassProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            for (ApexClass apexClass : [
                    SELECT Name FROM ApexClass WHERE Id IN (
                            SELECT SetupEntityId FROM SetupEntityAccess
                            WHERE ParentId = :permissionSetId AND SetupEntityType = 'ApexClass'
                    ) WITH SYSTEM_MODE ORDER BY Name
            ]) {
                rows.add('Apex Class,' + apexClass.Name + ',');
            }
            return rows;
        }
    }

    private class FlowPermissionProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            Set<Id> flowIds = getEntityIdsByPermissionSetId(permissionSetId, 'FlowDefinition');

            if (flowIds.isEmpty()) return rows;

            for (FlowDefinitionView flow : [
                    SELECT ApiName
                    FROM FlowDefinitionView
                    WHERE DurableId IN :flowIds AND ManageableState = 'unmanaged'
                    WITH SYSTEM_MODE
                    ORDER BY Label ASC
            ]) {
                rows.add('Flow,' + flow.ApiName + ',');
            }
            return rows;
        }
    }

    private class CustomMetadataProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            Set<Id> entityIds = getEntityIdsByPermissionSetId(permissionSetId, 'CustomEntityDefinition');
            if (entityIds.isEmpty()) return rows;

            for (EntityDefinition customMetadataType : [
                    SELECT DeveloperName
                    FROM EntityDefinition
                    WHERE DurableId IN :entityIds AND QualifiedApiName LIKE '%__mdt' WITH SYSTEM_MODE
            ]) {
                rows.add('Custom Metadata Type,' + customMetadataType.DeveloperName + ',');
            }
            return rows;
        }
    }

    private class CustomSettingProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            Set<Id> entityIds = getEntityIdsByPermissionSetId(permissionSetId, 'CustomEntityDefinition');

            if (entityIds.isEmpty()) return rows;

            for (EntityDefinition customSetting : [
                    SELECT DeveloperName
                    FROM EntityDefinition
                    WHERE DurableId IN :entityIds AND IsCustomSetting = TRUE WITH SYSTEM_MODE
            ]) {
                rows.add('Custom Setting,' + customSetting.DeveloperName + ',');
            }
            return rows;
        }
    }

    private class ApexPageProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            for (ApexPage page : [
                    SELECT Name FROM ApexPage WHERE Id IN (
                            SELECT SetupEntityId FROM SetupEntityAccess
                            WHERE ParentId = :permissionSetId AND SetupEntityType = 'ApexPage'
                    ) WITH SYSTEM_MODE ORDER BY Name
            ]) {
                rows.add('Visualforce Page,' + page.Name + ',');
            }
            return rows;
        }
    }

    private class CustomPermissionProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            for (CustomPermission cp : [
                    SELECT DeveloperName FROM CustomPermission WHERE Id IN (
                            SELECT SetupEntityId FROM SetupEntityAccess
                            WHERE ParentId = :permissionSetId AND SetupEntityType = 'CustomPermission'
                    ) WITH SYSTEM_MODE ORDER BY DeveloperName
            ]) {
                rows.add('Custom Permission,' + cp.DeveloperName + ',');
            }
            return rows;
        }
    }

    private class TabSettingProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            for (PermissionSetTabSetting tab : [
                    SELECT Name, Visibility
                    FROM PermissionSetTabSetting
                    WHERE ParentId = :permissionSetId WITH SYSTEM_MODE
                    ORDER BY Name
            ]) {
                rows.add('Tab,' + tab.Name + ',' + 'Visibility:' + tab.Visibility);
            }
            return rows;
        }
    }

    private class SystemPermissionProvider implements IPermissionCsvProvider {
        public List<String> getCsvRows(Id permissionSetId) {
            List<String> rows = new List<String>();
            List<Object> allSystemPermissions = PSLab_PermissionAnalysisHelper.getSystemPermissions();
            if (allSystemPermissions.isEmpty()) {
                return rows;
            }

            List<String> permissionApiNames = new List<String>();
            for (Object permObject : allSystemPermissions) {
                Map<String, Object> permMap = (Map<String, Object>) permObject;
                permissionApiNames.add((String) permMap.get('value'));
            }
            String query = 'SELECT ' + String.join(permissionApiNames, ',') + ' FROM PermissionSet WHERE Id = :permissionSetId WITH SYSTEM_MODE';
            PermissionSet permissionSet = Database.query(query);

            for (Object permObject : allSystemPermissions) {
                Map<String, Object> permMap = (Map<String, Object>) permObject;
                String apiName = (String) permMap.get('value');
                String label = (String) permMap.get('label');

                if (permissionSet.get(apiName) == true) {
                    String permissionName = label + ' (' + apiName + ')';
                    rows.add('System Permission,' + permissionName + ',Enabled');
                }
            }
            rows.sort();
            return rows;
        }
    }

    private static Set<Id> getEntityIdsByPermissionSetId(Id permissionSetId, String entityType){
        List<SetupEntityAccess> setupEntityAccesses = [SELECT Id, SetupEntityId, SetupEntityType FROM SetupEntityAccess WHERE ParentId = :permissionSetId AND SetupEntityType = :entityType WITH SYSTEM_MODE];
        Set<Id> entityIds = new Set<Id>();
        for(SetupEntityAccess setupEntityAccess : setupEntityAccesses) {
            entityIds.add(setupEntityAccess.SetupEntityId);
        }

        return entityIds;
    }


    public class PermissionSetInfo {
        @AuraEnabled public Id Id;
        @AuraEnabled public String label;
        @AuraEnabled public Id value;
        @AuraEnabled public String description;
        @AuraEnabled public String includedIn;
        @AuraEnabled public String createdBy;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String lastModifiedBy;
        @AuraEnabled public Datetime lastModifiedDate;
        @AuraEnabled public Boolean isCustom;
        @AuraEnabled public String type;
        @AuraEnabled public String assignedUsersURL;
    }

}