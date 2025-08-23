/**
 * @author        Oumaima ARBANI
 * @date          16/8/2025
 * @description   Helper class for querying and analyzing user/org permissions. Provides methods to fetch metadata, build hierarchies, and detect specific permissions.
 * @group         PSLab
 **/
public without sharing class PSLab_PermissionAnalysisHelper {
    /**
     * @description   Retrieves a list of metadata options (e.g., objects, fields) based on the selected permission type for UI dropdowns.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         selectedPermission The API name of the permission type being analyzed (e.g., 'ObjectPermissions').
     * @param         objectName The API name of an object, used specifically for retrieving field permissions.
     * @return        List<Object> A list of maps, each containing 'label' and 'value' keys for UI components.
     **/
    public static List<Object> getOptionsBySelectedPermissionHelper(String selectedPermission, String objectName) {
        switch on selectedPermission {
            when 'TabSet' {
                return getApplications();
            }
            when 'ObjectPermissions' {
                return getOrgAvailableObjectsByObjectAPIName();
            }
            when 'FieldPermissions' {
                return getFieldDefinitionByObjectAPIName(objectName);
            }
            when 'PermissionSetTabSetting' {
                return getTabsDefinition();
            }
            when 'ApexClass' {
                return getApexClasses();
            }
            when 'ApexPage' {
                return getVisualforcePages();
            }
            when 'FlowDefinition' {
                return getFlows();
            }
            when 'CustomPermission' {
                return getCustomPermissions();
            }
            when 'CustomMetadataType' {
                return getOrgCustomMetadata();
            }
            when 'CustomSetting' {
                return getOrgCustomSettings();
            }
            when 'PermissionSet' {
                return getSystemPermissions();
            }
            when else {
                return new List<Object>();
            }
        }
    }

    /**
     * @description   Builds and returns the permission set and group hierarchy for a specific user.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         userId The ID of the user to analyze.
     * @return        PSLab_HierarchyNode The root node of the user's permission hierarchy.
     **/
    public static PSLab_HierarchyNode getPermissionSetHierarchyByUserId(String userId) {
        List<PermissionSetAssignment> assignments = [
                SELECT
                        PermissionSetId,
                        PermissionSet.Name,
                        PermissionSet.Label,
                        PermissionSet.Description,
                        PermissionSet.CreatedBy.Name,
                        PermissionSet.LastModifiedBy.Name,
                        PermissionSet.LastModifiedDate,
                        PermissionSetGroupId,
                        PermissionSetGroup.DeveloperName,
                        PermissionSetGroup.MasterLabel,
                        PermissionSetGroup.Description,
                        PermissionSetGroup.CreatedBy.Name,
                        PermissionSetGroup.Status,
                        PermissionSetGroup.LastModifiedBy.Name,
                        PermissionSetGroup.LastModifiedDate,
                        Assignee.Name,
                        Assignee.Username
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
        ];
        PSLab_PermissionHierarchyBuilder builder = new PSLab_PermissionHierarchyBuilder(assignments);
        return builder.build();
    }

    /**
     * @description  : Builds and returns the complete hierarchy of all permission sets and groups in the org.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        PSLab_HierarchyNode The root node of the org's entire permission structure.
     **/
    public static PSLab_HierarchyNode getPermissionSetHierarchy() {
        PSLab_AllPermissionsHierarchyBuilder builder = new PSLab_AllPermissionsHierarchyBuilder();
        return builder.build();
    }

    /**
     * @description   Retrieves a formatted list of Permission Sets, Permission Set Groups, or Users.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         searchType The type of records to retrieve ('PS', 'PSG', or 'User').
     * @return        List<Object> A list of maps formatted for UI component options.
     **/
    public static List<Object> getPermissionsOrUsersList(String searchType) {
        switch on searchType {
            when 'PS' {
                return getPermissionSets();
            }
            when 'PSG' {
                return getPermissionSetGroups();
            }
            when 'User' {
                return getOrgUsers();
            }
            when else {
                return new List<Object>();
            }
        }
    }

    /**
     * @description   Main analysis engine that finds which permission sets or profiles grant a specific permission based on search criteria.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         payload A map of search criteria, including permission type, metadata names, etc.
     * @return        List<PSLab_DetectedPermission> A list of wrappers detailing where the specified permission is granted.
     **/
    public static List<PSLab_DetectedPermission> getDetectedPermissions(Map<String, Object> payload) {
        String permission = (String) payload.get('permission');
        String query = getPermissionDetectionQuery(payload);
        if (String.isBlank(query)) {
            return new List<PSLab_DetectedPermission>();
        }
        List<Object> rawRecords = executeQuery(query, permission);
        List<Object> preparedRecords = preparePermissionsWrapper(rawRecords, (String) payload.get('permission'));
        List<PermissionRecord> wrappedRecords = wrapRecords(preparedRecords, (String) payload.get('permission'));
        Set<Id> permissionSetIds = getPermissionSetIdsFromWrappers(wrappedRecords);
        Map<Id, PermissionSet> permissionSetById = fetchPermissionSets(permissionSetIds);
        Map<Id, List<String>> permissionSetToGroups = fetchPermissionSetGroups(permissionSetIds);
        return buildDetectedPermissionsList(wrappedRecords, payload, permissionSetById, permissionSetToGroups);
    }

    /**
     * @description   Executes a SOQL query, routing to the Tooling API if necessary for certain permission types.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         query The SOQL query string to execute.
     * @param         permissionType The type of permission, used to determine if a Tooling API callout is needed.
     * @return        List<Object> The list of raw records returned from the query.
     **/
    private static List<Object> executeQuery(String query, String permissionType) {
        if (permissionType == 'PermissionSetTabSetting') {
            String jsonResponse = executeToolingApiQuery(query);
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            return (List<Object>) results.get('records');
        } else {
            return Database.query(query);
        }
    }

    /**
     * @description   Executes a GET request callout to the Salesforce Tooling API.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         soqlQuery The SOQL query to be URL-encoded and sent to the Tooling API.
     * @return        String The JSON response body from the API call.
     **/
    private static String executeToolingApiQuery(String soqlQuery) {
        HttpRequest req = new HttpRequest();
        String endpoint = 'callout:Tooling_API_Credential/services/data/v64.0/tooling/query/?q=';
        endpoint += EncodingUtil.urlEncode(soqlQuery, 'UTF-8');
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            System.debug('Tooling API Error: ' + res.getStatusCode() + ' ' + res.getBody());
            throw new CalloutException(res.getStatus() + ' ' + res.getBody());
        }
    }

    /**
     * @description   Retrieves all non-group Permission Sets and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Permission Set.
     **/
    private static List<Object> getPermissionSets() {
        List<PermissionSet> permissionSetsList = [
                SELECT Id, Name, Label
                FROM PermissionSet
                WHERE Type != 'Group'
                WITH SYSTEM_MODE
                ORDER BY Label ASC
        ];

        List<Object> permissionSets = new List<Object>();
        for (PermissionSet permissionSet : permissionSetsList) {
            permissionSets.add(
                    new Map<String, Object>{
                            'Id' => permissionSet.Id,
                            'label' => permissionSet.Label +
                                    ' (' +
                                    permissionSet.Name +
                                    ')',
                            'value' => permissionSet.Name
                    }
            );
        }
        return permissionSets;
    }

    /**
     * @description   Retrieves all Permission Set Groups and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Permission Set Group.
     **/
    private static List<Object> getPermissionSetGroups() {
        List<PermissionSetGroup> permissionSetsList = [
                SELECT Id, MasterLabel, DeveloperName
                FROM PermissionSetGroup
                WITH SYSTEM_MODE
                ORDER BY MasterLabel ASC
        ];

        List<Object> permissionSetGroups = new List<Object>();
        for (PermissionSetGroup permissionSetGroup : permissionSetsList) {
            permissionSetGroups.add(
                    new Map<String, Object>{
                            'Id' => permissionSetGroup.Id,
                            'label' => permissionSetGroup.MasterLabel +
                                    ' (' +
                                    permissionSetGroup.DeveloperName +
                                    ')',
                            'value' => permissionSetGroup.DeveloperName
                    }
            );
        }
        return permissionSetGroups;
    }

    /**
     * @description   Retrieves all Users in the org and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a User.
     **/
    private static List<Object> getOrgUsers() {
        List<User> usersList = [SELECT Id, Name, Username FROM User WITH SYSTEM_MODE ORDER BY Name ASC];

        List<Object> users = new List<Object>();
        for (User user : usersList) {
            users.add(
                    new Map<String, Object>{
                            'Id' => user.Id,
                            'label' => user.Name +
                                    ' (' +
                                    user.Username +
                                    ')',
                            'value' => user.Id
                    }
            );
        }
        return users;
    }

    /**
     * @description   Retrieves all Applications (App Menus) and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing an Application.
     **/
    private static List<Object> getApplications() {
        List<Object> applicationsList = new List<Object>();
        List<AppMenuItem> appDefinitions = [
                SELECT Id, Label, Name, ApplicationId
                FROM AppMenuItem
                WHERE Type != 'ConnectedApplication'
                WITH SYSTEM_MODE
                ORDER BY Label ASC
        ];
        for (AppMenuItem appDefinition : appDefinitions) {
            applicationsList.add(
                    new Map<String, Object>{
                            'Id' => appDefinition.ApplicationId,
                            'label' => appDefinition.Label +
                                    ' (' +
                                    appDefinition.Name +
                                    ')',
                            'value' => appDefinition.Name
                    }
            );
        }
        return applicationsList;
    }

    /**
     * @description   Retrieves all SObjects in the org and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing an SObject.
     **/
    private static List<Object> getOrgAvailableObjectsByObjectAPIName() {
        List<Object> objectList = new List<Object>();
        String lastEntityQueried;

        do {
            EntityDefinition[] definitions = [
                    SELECT MasterLabel, QualifiedApiName
                    FROM EntityDefinition
                    WHERE QualifiedApiName > :lastEntityQueried
                    ORDER BY QualifiedApiName ASC
                    LIMIT 2000
            ];

            if (definitions.isEmpty()) {
                break;
            }

            for (EntityDefinition definition : definitions) {
                objectList.add(
                        new Map<String, Object>{
                                'label' => definition.MasterLabel +
                                        ' (' +
                                        definition.QualifiedApiName +
                                        ')',
                                'value' => definition.QualifiedApiName
                        }
                );
            }

            if (!definitions.isEmpty()) {
                lastEntityQueried = definitions[definitions.size() - 1].QualifiedApiName;
            }

            if (definitions.size() < 2000) {
                break;
            }
        } while (true);

        return objectList;
    }

    /**
     * @description   Retrieves all permissionable fields for a given SObject and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         objectAPIName The API name of the SObject to get fields from.
     * @return        List<Object> A list of maps, each representing a field.
     **/
    private static List<Object> getFieldDefinitionByObjectAPIName(String objectAPIName) {
        List<Object> fieldsList = new List<Object>();

        try {
            SObjectType r = ((SObject) Type.forName('Schema.' + objectAPIName).newInstance()).getSObjectType();
            DescribeSObjectResult describeResult = r.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();

                if (fieldDescribe.isPermissionable()) {
                    fieldsList.add(
                            new Map<String, Object>{
                                    'label' => fieldDescribe.getLabel() +
                                            ' (' +
                                            fieldDescribe.getName() +
                                            ')',
                                    'value' => fieldDescribe.getName()
                            }
                    );
                }
            }
        } catch (Exception e) {
            System.debug('Error in getFieldDefinitionByObjectAPIName: ' + e.getMessage());
        }

        return fieldsList;
    }

    /**
     * @description   Retrieves all Tab Definitions and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Tab.
     **/
    private static List<Object> getTabsDefinition() {
        List<Object> tabsList = new List<Object>();
        List<TabDefinition> tabDefinitions = [
                SELECT Name, Label
                FROM TabDefinition
                WITH SYSTEM_MODE
                ORDER BY Label ASC
        ];
        for (TabDefinition tabDefinition : tabDefinitions) {
            tabsList.add(
                    new Map<String, Object>{
                            'label' => tabDefinition.Label +
                                    ' (' +
                                    tabDefinition.Name +
                                    ')',
                            'value' => tabDefinition.Name
                    }
            );
        }
        return tabsList;
    }

    /**
     * @description   Retrieves all Apex Classes and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing an Apex Class.
     **/
    private static List<Object> getApexClasses() {
        List<Object> apexClassesList = new List<Object>();
        List<ApexClass> apexClasses = [SELECT Name FROM ApexClass WITH SYSTEM_MODE ORDER BY Name ASC];
        for (ApexClass apexClass : apexClasses) {
            apexClassesList.add(new Map<String, Object>{ 'label' => apexClass.Name, 'value' => apexClass.Name });
        }
        return apexClassesList;
    }

    /**
     * @description   Retrieves all Visualforce Pages and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Visualforce Page.
     **/
    private static List<Object> getVisualforcePages() {
        List<Object> visualforcePagesList = new List<Object>();
        List<ApexPage> visualforcePages = [SELECT Name FROM ApexPage WITH SYSTEM_MODE ORDER BY Name ASC];
        for (ApexPage visualforcePage : visualforcePages) {
            visualforcePagesList.add(
                    new Map<String, Object>{ 'label' => visualforcePage.Name, 'value' => visualforcePage.Name }
            );
        }
        return visualforcePagesList;
    }

    /**
     * @description   Retrieves all active, unmanaged Flows and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Flow.
     **/
    private static List<Object> getFlows() {
        List<Object> flowsList = new List<Object>();
        List<FlowDefinitionView> flows = [
                SELECT Id, DurableId, ApiName, Label
                FROM FlowDefinitionView
                WHERE ActiveVersionId != NULL AND ManageableState = 'unmanaged'
                WITH SYSTEM_MODE
                ORDER BY Label ASC
        ];
        for (FlowDefinitionView flow : flows) {
            flowsList.add(
                    new Map<String, Object>{
                            'Id' => flow.Id,
                            'label' => flow.Label +
                                    ' (' +
                                    flow.ApiName +
                                    ')',
                            'value' => flow.DurableId
                    }
            );
        }
        return flowsList;
    }

    /**
     * @description   Retrieves all Custom Permissions and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Custom Permission.
     **/
    private static List<Object> getCustomPermissions() {
        List<Object> customPermissionsList = new List<Object>();
        List<CustomPermission> customPermissions = [
                SELECT DeveloperName, MasterLabel
                FROM CustomPermission
                WITH SYSTEM_MODE
                ORDER BY MasterLabel ASC
        ];
        for (CustomPermission customPermission : customPermissions) {
            customPermissionsList.add(
                    new Map<String, Object>{
                            'label' => customPermission.MasterLabel +
                                    ' (' +
                                    customPermission.DeveloperName +
                                    ')',
                            'value' => customPermission.DeveloperName
                    }
            );
        }
        return customPermissionsList;
    }

    /**
     * @description   Retrieves all Custom Metadata Types and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Custom Metadata Type.
     **/
    private static List<Object> getOrgCustomMetadata() {
        List<Object> customMetadataTypesList = new List<Object>();

        List<EntityDefinition> customMetadataTypes = [
                SELECT Id, DeveloperName, Label, DurableId
                FROM EntityDefinition
                WHERE IsCustomizable = TRUE AND EntityDefinition.QualifiedApiName LIKE '%__mdt'
        ];

        for (EntityDefinition customMetadataType : customMetadataTypes) {
            customMetadataTypesList.add(
                    new Map<String, Object>{
                            'Id' => customMetadataType.DurableId,
                            'label' => customMetadataType.Label +
                                    ' (' +
                                    customMetadataType.DeveloperName +
                                    ')',
                            'value' => customMetadataType.DeveloperName
                    }
            );
        }

        return customMetadataTypesList;
    }

    /**
     * @description   Retrieves all Custom Settings and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a Custom Setting.
     **/
    private static List<Object> getOrgCustomSettings() {
        List<Object> customSettingsList = new List<Object>();
        List<EntityDefinition> customSettings = [
                SELECT Id, DurableId, DeveloperName, Label
                FROM EntityDefinition
                WHERE IsCustomSetting = TRUE
        ];
        for (EntityDefinition customSetting : customSettings) {
            customSettingsList.add(
                    new Map<String, Object>{
                            'Id' => customSetting.DurableId,
                            'label' => customSetting.Label +
                                    ' (' +
                                    customSetting.DeveloperName +
                                    ')',
                            'value' => customSetting.DeveloperName
                    }
            );
        }
        return customSettingsList;
    }

    /**
     * @description   Retrieves all System Permissions from custom metadata and formats them for a UI dropdown.
     * @author        Oumaima Arbani | 2025-08-22
     * @return        List<Object> A list of maps, each representing a System Permission.
     **/
    public static List<Object> getSystemPermissions() {
        List<Object> systemPermissionsList = new List<Object>();
        List<PSLab_SP__mdt> systemPermissionsMetaData = [
                SELECT SystemPermissionAPIName__c, SystemPermissionLabel__c
                FROM PSLab_SP__mdt
                WITH SYSTEM_MODE
                ORDER BY SystemPermissionLabel__c ASC
        ];
        for (PSLab_SP__mdt systemPermission : systemPermissionsMetaData) {
            systemPermissionsList.add(
                    new Map<String, Object>{
                            'label' => systemPermission.SystemPermissionLabel__c,
                            'value' => systemPermission.SystemPermissionAPIName__c
                    }
            );
        }
        return systemPermissionsList;
    }

    /**
     * @description   Pre-processes raw query results, transforming SetupEntityAccess records into a standard format.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         records The raw list of records from a query.
     * @param         permissionToCheck The type of permission being checked.
     * @return        List<Object> A list of prepared records for further processing.
     **/
    private static List<Object> preparePermissionsWrapper(List<Object> records, String permissionToCheck) {
        List<Object> permissionsData = new List<Object>();

        switch on permissionToCheck {
            when 'ApexClass', 'ApexPage', 'CustomPermission' {
                String referenceField = (permissionToCheck == 'CustomPermission') ? 'DeveloperName' : 'Name';
                permissionsData.addAll(
                        PSLab_SetupEntityAccessTransformer.transform((List<SObject>) records, referenceField)
                );
            }
            when else {
                permissionsData.addAll(records);
            }
        }

        return permissionsData;
    }

    /**
     * @description   Converts a list of raw SObject or Map records into a standardized list of PermissionRecord wrappers.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         records The list of records to wrap.
     * @param         permissionToCheck The type of permission, used to determine how to extract the Parent ID.
     * @return        List<PermissionRecord> A list of standardized PermissionRecord objects.
     **/
    private static List<PermissionRecord> wrapRecords(List<Object> records, String permissionToCheck) {
        List<PermissionRecord> wrappers = new List<PermissionRecord>();
        for (Object record : records) {
            wrappers.add(new PermissionRecord(record, permissionToCheck));
        }
        return wrappers;
    }

    /**
     * @description   Extracts a unique set of Permission Set IDs from a list of wrapped records.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         wrappedRecords The list of PermissionRecord wrappers.
     * @return        Set<Id> A unique set of Permission Set IDs.
     **/
    private static Set<Id> getPermissionSetIdsFromWrappers(List<PermissionRecord> wrappedRecords) {
        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionRecord wrapper : wrappedRecords) {
            permissionSetIds.add(wrapper.permissionSetId);
        }
        return permissionSetIds;
    }

    /**
     * @description   Fetches Permission Set records based on a set of IDs.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         permissionSetIds A set of Permission Set IDs to query.
     * @return        Map<Id, PermissionSet> A map of Permission Set ID to the corresponding PermissionSet record.
     **/
    private static Map<Id, PermissionSet> fetchPermissionSets(Set<Id> permissionSetIds) {
        return new Map<Id, PermissionSet>(
        [
                SELECT Id, Label, Name
                FROM PermissionSet
                WHERE Id IN :permissionSetIds
                WITH SYSTEM_MODE
        ]
        );
    }

    /**
     * @description   Maps Permission Set IDs to the list of Permission Set Groups they belong to.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         permissionSetIds A set of Permission Set IDs to find group memberships for.
     * @return        Map<Id, List<String>> A map of Permission Set ID to a list of its parent PSG developer names.
     **/
    private static Map<Id, List<String>> fetchPermissionSetGroups(Set<Id> permissionSetIds) {
        Map<Id, List<String>> permissionSetToGroupsMap = new Map<Id, List<String>>();
        List<PermissionSetGroupComponent> permissionSetGroupComponents = [
                SELECT PermissionSetId, PermissionSetGroup.DeveloperName
                FROM PermissionSetGroupComponent
                WHERE PermissionSetId IN :permissionSetIds
                WITH SYSTEM_MODE
        ];

        if (permissionSetGroupComponents.isEmpty()) {
            return permissionSetToGroupsMap;
        }
        for (PermissionSetGroupComponent component : permissionSetGroupComponents) {
            Id permissionSetId = component.PermissionSetId;
            String groupDeveloperName = component.PermissionSetGroup.DeveloperName;

            if (!permissionSetToGroupsMap.containsKey(permissionSetId)) {
                permissionSetToGroupsMap.put(permissionSetId, new List<String>());
            }
            permissionSetToGroupsMap.get(permissionSetId).add(groupDeveloperName);
        }
        return permissionSetToGroupsMap;
    }

    /**
     * @description   Assembles the final, detailed list of detected permissions from all processed data.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         wrappedRecords The list of standardized permission records.
     * @param         payload The original search criteria.
     * @param         permissionSetById A map of Permission Set records.
     * @param         permissionSetToGroups A map of Permission Set to PSG memberships.
     * @return        List<PSLab_DetectedPermission> The final list of analysis results.
     **/
    private static List<PSLab_DetectedPermission> buildDetectedPermissionsList(
            List<PermissionRecord> wrappedRecords,
            Map<String, Object> payload,
            Map<Id, PermissionSet> permissionSetById,
            Map<Id, List<String>> permissionSetToGroups
    ) {
        List<PSLab_DetectedPermission> detectedPermissions = new List<PSLab_DetectedPermission>();
        String permissionType = (String) payload.get('permissionType');
        for (PermissionRecord wrapper : wrappedRecords) {
            PermissionSet permissionSet = permissionSetById.get(wrapper.permissionSetId);
            if (permissionSet == null)
                continue;

            PSLab_DetectedPermission detected = new PSLab_DetectedPermission();
            detected.permissionType = permissionType;
            detected.permissionSetId = wrapper.permissionSetId;
            detected.permissionSetLabel = permissionSet.Label;
            detected.permissionSetDeveloperName = permissionSet.Name;
            detected.includedIn = permissionSetToGroups.get(wrapper.permissionSetId) != null
                    ? permissionSetToGroups.get(wrapper.permissionSetId)
                    : new List<String>();

            populatePermissionDetails(detected, wrapper, payload);

            detectedPermissions.add(detected);
        }
        return detectedPermissions;
    }

    /**
     * @description   Populates the specific detail properties of a PSLab_DetectedPermission object based on the permission type.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         detected The PSLab_DetectedPermission object to populate.
     * @param         wrapper The PermissionRecord wrapper containing the source data.
     * @param         payload The original search criteria payload.
     **/
    private static void populatePermissionDetails(
            PSLab_DetectedPermission detected,
            PermissionRecord wrapper,
            Map<String, Object> payload
    ) {
        String permissionToCheck = (String) payload.get('permission');
        switch on permissionToCheck {
            when 'ObjectPermissions' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.ObjectPermissionDetails details = new PSLab_DetectedPermission.ObjectPermissionDetails();
                details.sObjectType = (String) sobj.get('SobjectType');
                details.permissionsCreate = (Boolean) sobj.get('PermissionsCreate');
                details.permissionsRead = (Boolean) sobj.get('PermissionsRead');
                details.permissionsEdit = (Boolean) sobj.get('PermissionsEdit');
                details.permissionsDelete = (Boolean) sobj.get('PermissionsDelete');
                details.permissionsViewAllRecords = (Boolean) sobj.get('PermissionsViewAllRecords');
                details.permissionsModifyAllRecords = (Boolean) sobj.get('PermissionsModifyAllRecords');
                details.permissionsViewAllFields = (Boolean) sobj.get('PermissionsViewAllFields');
                detected.objectPermissionDetails = details;
            }
            when 'FieldPermissions' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.FieldPermissionDetails details = new PSLab_DetectedPermission.FieldPermissionDetails();
                details.sObjectType = (String) sobj.get('SObjectType');
                details.field = (String) sobj.get('Field');
                details.permissionsRead = (Boolean) sobj.get('PermissionsRead');
                details.permissionsEdit = (Boolean) sobj.get('PermissionsEdit');
                detected.fieldPermissionDetails = details;
            }
            when 'ApexClass' {
                PSLab_DetectedPermission.ApexClassPermissionDetails details = new PSLab_DetectedPermission.ApexClassPermissionDetails();
                details.name = wrapper.referenceValue;
                detected.apexClassPermissionDetails = details;
            }
            when 'ApexPage' {
                PSLab_DetectedPermission.ApexPagePermissionDetails details = new PSLab_DetectedPermission.ApexPagePermissionDetails();
                details.name = wrapper.referenceValue;
                detected.apexPagePermissionDetails = details;
            }
            when 'CustomPermission' {
                PSLab_DetectedPermission.CustomPermissionDetails details = new PSLab_DetectedPermission.CustomPermissionDetails();
                details.developerName = wrapper.referenceValue;
                detected.customPermissionDetails = details;
            }
            when 'PermissionSetTabSetting' {
                Map<String, Object> recordMap = (Map<String, Object>) wrapper.sourceRecord;
                PSLab_DetectedPermission.TabSettingDetails details = new PSLab_DetectedPermission.TabSettingDetails();
                details.name = (String) recordMap.get('Name');
                details.visibility = (String) recordMap.get('Visibility');
                detected.tabSettingDetails = details;
            }
            when 'TabSet', 'FlowDefinition', 'CustomMetadataType', 'CustomSetting' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.SetupEntityAccessDetails details = new PSLab_DetectedPermission.SetupEntityAccessDetails();
                details.setupEntityId = (String) sobj.get('SetupEntityId');
                detected.setupEntityAccessDetails = details;
            }
            when 'PermissionSet' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.GenericPermissionSetDetails details = new PSLab_DetectedPermission.GenericPermissionSetDetails();
                Map<String, Boolean> permissionsMap = new Map<String, Boolean>();
                for (String permission : ((String) payload.get('metadataNames')).split(',')) {
                    String trimmedPermission = permission.trim();
                    if (String.isNotBlank(trimmedPermission)) {
                        permissionsMap.put(trimmedPermission, (Boolean) sobj.get(trimmedPermission));
                    }
                }
                details.permissions = permissionsMap;
                detected.genericPermissionSetDetails = details;
                detected.includedIn = new List<String>();
            }
            when else {
                System.debug('Unexpected permission type: ' + permissionToCheck);
            }
        }
    }

    /**
     * @description   A wrapper method that initiates the dynamic query building process.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         payload The map of search criteria.
     * @return        String The dynamically generated SOQL query string.
     **/
    private static String getPermissionDetectionQuery(Map<String, Object> payload) {
        String query;

        query = queryBuilderHelper(payload);

        System.debug(LoggingLevel.INFO, 'Generated Query String: ' + query);
        return query;
    }

    /**
     * @description   Constructs a dynamic SOQL query string based on the search criteria in the payload.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         payload The map of search criteria.
     * @return        String The fully constructed SOQL query string.
     **/
    private static String queryBuilderHelper(Map<String, Object> payload) {
        String query;

        String permissionType = (String) payload.get('permissionType');
        Object permissionsAPINamesObject = payload.get('permissionsAPINames');
        String selectedPermission = (String) payload.get('permission');
        String permissions = (String) payload.get('securityPermissions');
        String metadataAPIName = (String) payload.get('metadataNames');
        String subMetadataAPIName = (String) payload.get('subMetadataAPIName');
        String condition = (String) payload.get('condition');
        switch on selectedPermission {
            when 'ObjectPermissions' {
                query =
                        'SELECT Id, ParentId, Parent.Label, Parent.Name, Parent.Type, SobjectType, PermissionsCreate, PermissionsRead, PermissionsEdit, ' +
                        'PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords, PermissionsViewAllFields ' +
                        'FROM ObjectPermissions WHERE Parent.Type != \'Profile\' AND SObjectType = \'' +
                        String.escapeSingleQuotes(metadataAPIName) +
                        '\'';

                query += buildPermissionConditions(permissions, condition, true);
                query += buildPermissionQueryClause(permissionsAPINamesObject, permissionType);
            }
            when 'FieldPermissions' {
                query =
                        'SELECT ParentId,Parent.Label, Parent.Name, Parent.Type, SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions ' +
                        'WHERE Parent.Type != \'Profile\' AND SObjectType = \'' +
                        String.escapeSingleQuotes(metadataAPIName) +
                        '\'';

                if (String.isNotBlank(subMetadataAPIName)) {
                    List<String> fieldNames = new List<String>();
                    for (String f : subMetadataAPIName.split(',')) {
                        if (String.isNotBlank(f)) {
                            fieldNames.add('\'' + String.escapeSingleQuotes(f.trim()) + '\'');
                        }
                    }
                    if (!fieldNames.isEmpty()) {
                        query += ' AND Field IN (' + String.join(fieldNames, ',') + ')';
                    }
                }

                query += buildPermissionConditions(permissions, condition, true);
                query += buildPermissionQueryClause(permissionsAPINamesObject, permissionType);
            }
            when 'ApexClass', 'ApexPage', 'CustomPermission' {
                String nameFieldToFilterOn = (selectedPermission == 'CustomPermission') ? 'DeveloperName' : 'Name';

                if(condition.equalsIgnoreCase('OR')){
                    query =
                            'SELECT Id, ' +
                            nameFieldToFilterOn +
                            ', (SELECT Id, ParentId, Parent.Name, Parent.Label FROM SetupEntityAccessItems ' +
                            'WHERE Parent.Type != \'Profile\' ' +
                            buildPermissionQueryClause(permissionsAPINamesObject, permissionType) +
                            ') FROM ' +
                            selectedPermission;

                    if (String.isNotBlank(metadataAPIName)) {
                        query += ' WHERE ' + nameFieldToFilterOn + ' IN (' + toInClause(metadataAPIName) + ')';
                    }
                }else if(condition.equalsIgnoreCase('AND')){
                    Integer metadataCount = 0;
                    if (String.isNotBlank(metadataAPIName)) {
                        metadataCount = metadataAPIName.split(',').size();
                    }
                    query =
                            'SELECT ParentId, Parent.Name, Parent.Label ' +
                            'FROM SetupEntityAccess ' +
                            'WHERE SetupEntityType = \'' + String.escapeSingleQuotes(selectedPermission) + '\' ' +
                            'AND Parent.IsOwnedByProfile = false ' +
                            buildPermissionQueryClause(permissionsAPINamesObject, permissionType) +
                            'AND SetupEntityId IN (' +
                            '  SELECT Id FROM ' + selectedPermission + ' ' +
                            '  WHERE ' + nameFieldToFilterOn + ' IN (' + toInClause(metadataAPIName) + ')' +
                            ') ' +
                            'GROUP BY ParentId, Parent.Name, Parent.Label ' +
                            'HAVING COUNT(Id) = ' + metadataCount;
                }
            }
            when 'PermissionSetTabSetting' {
                if (String.isBlank(metadataAPIName)) {
                    query = null;
                    return '';
                }

                String visibility = permissions.equals('DefaultOn') ? 'DefaultOn' : 'DefaultOff';
                List<String> whereClauses = new List<String>{
                        'Parent.IsOwnedByProfile = false',
                        'Name IN (' + toInClause(metadataAPIName) + ')',
                        'Visibility = \'' + String.escapeSingleQuotes(visibility) + '\''
                };

                String permSetClause = buildPermissionQueryClause(permissionsAPINamesObject, permissionType);
                if (String.isNotBlank(permSetClause)) {
                    String trimmedClause = permSetClause.trim();
                    if (trimmedClause.toUpperCase().startsWith('AND ')) {
                        whereClauses.add(trimmedClause.substring(4));
                    } else {
                        whereClauses.add(trimmedClause);
                    }
                }

                String finalWhereClause = ' WHERE ' + String.join(whereClauses, ' AND ');

                if (condition.equalsIgnoreCase('AND')) {
                    Integer metadataCount = metadataAPIName.split(',').size();
                    query = 'SELECT ParentId, Parent.Name, Parent.Label ' +
                            'FROM PermissionSetTabSetting ' +
                            finalWhereClause +
                            ' GROUP BY ParentId, Parent.Name, Parent.Label ' +
                            'HAVING COUNT(Id) = ' + metadataCount;
                } else {
                    query = 'SELECT Id, ParentId, Parent.Name, Parent.Label, Name, Visibility ' +
                            'FROM PermissionSetTabSetting ' +
                            finalWhereClause;
                }
            }
            when 'TabSet', 'FlowDefinition', 'CustomMetadataType', 'CustomSetting' {
                if (selectedPermission.equals('CustomMetadataType') || selectedPermission.equals('CustomSetting')) {
                    selectedPermission = 'CustomEntityDefinition';
                }
                if (condition.equalsIgnoreCase('OR')) {
                    query = 'SELECT Id, ParentId, Parent.Label, Parent.Name, Parent.Type, SetupEntityId, SetupEntityType FROM SetupEntityAccess';
                    if (String.isNotBlank(metadataAPIName)) {
                        query +=
                                ' WHERE SetupEntityType = \'' +
                                selectedPermission +
                                '\'' +
                                ' AND  Parent.Type != \'Profile\' AND SetupEntityId IN (' +
                                toInClause(metadataAPIName) +
                                ')';
                    }

                    query += buildPermissionQueryClause(permissionsAPINamesObject, permissionType);
                } else if (condition.equalsIgnoreCase('AND')) {
                    if (String.isNotBlank(metadataAPIName)) {
                        List<String> metadataNames = metadataAPIName.split(',');
                        Integer requiredCount = metadataNames.size();

                        String aggregateQuery =
                                'SELECT ParentId FROM SetupEntityAccess' +
                                ' WHERE SetupEntityType = \'' +
                                selectedPermission +
                                '\'' +
                                ' AND Parent.Type != \'Profile\'' +
                                ' AND SetupEntityId IN (' +
                                toInClause(metadataAPIName) +
                                ')';
                        aggregateQuery += buildPermissionQueryClause(permissionsAPINamesObject, permissionType);
                        aggregateQuery += ' GROUP BY ParentId' + ' HAVING COUNT(Id) = ' + requiredCount;

                        List<AggregateResult> results = Database.query(aggregateQuery);
                        Set<Id> matchingParentIds = new Set<Id>();
                        for (AggregateResult aggregateResult : results) {
                            matchingParentIds.add((Id) aggregateResult.get('ParentId'));
                        }

                        if (!matchingParentIds.isEmpty()) {
                            query =
                                    'SELECT Id, ParentId, Parent.Label, Parent.Name, Parent.Type, SetupEntityId, SetupEntityType' +
                                    ' FROM SetupEntityAccess' +
                                    ' WHERE ParentId IN (' +
                                    toInClauseFromSet(matchingParentIds) +
                                    ') ' +
                                    ' AND SetupEntityId IN (' +
                                    toInClause(metadataAPIName) +
                                    ')';
                        }
                    }
                }
            }
            when 'PermissionSet' {
                query =
                        'SELECT Id, Name, Type, ' +
                        metadataAPIName +
                        ' FROM PermissionSet WHERE Type != \'Profile\' AND ';
                if (String.isNotBlank(metadataAPIName)) {
                    List<String> permissionConditions = new List<String>();
                    for (String permission : metadataAPIName.split(',')) {
                        if (String.isNotBlank(permission)) {
                            permissionConditions.add(String.escapeSingleQuotes(permission.trim()) + ' = true');
                        }
                    }
                    if (!permissionConditions.isEmpty()) {
                        query += ' (' + String.join(permissionConditions, condition == 'OR' ? ' OR ' : ' AND ') + ')';
                    }
                }
            }
            when else {
                query = '';
            }
        }

        return query;
    }

    /**
     * @description   Builds the specific permission-checking part of a WHERE clause (e.g., 'AND (PermissionsRead = true)').
     * @author        Oumaima Arbani | 2025-08-22
     * @param         permissions A comma-separated string of permission API names.
     * @param         condition The logical operator to join conditions ('OR' or 'AND').
     * @param         withAnd A boolean to indicate whether to prefix the clause with 'AND'.
     * @return        String A portion of a SOQL WHERE clause.
     **/
    private static String buildPermissionConditions(String permissions, String condition, Boolean withAnd) {
        if (String.isBlank(permissions)) {
            return '';
        }
        List<String> conditions = new List<String>();
        for (String p : permissions.split(',')) {
            if (String.isNotBlank(p)) {
                conditions.add(String.escapeSingleQuotes(p.trim()) + ' = true');
            }
        }
        if (!conditions.isEmpty()) {
            return (withAnd ? ' AND ' : '') + '(' + String.join(conditions, condition == 'OR' ? ' OR ' : ' AND ') + ')';
        }
        return '';
    }

    /**
     * @description   Builds the part of a WHERE clause that filters by parent Permission Set or Permission Set Group names.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         permissionsAPINamesObject A comma-separated string of PS or PSG developer names.
     * @param         permissionType The type of entity being filtered ('PS' or 'PSG').
     * @return        String A portion of a SOQL WHERE clause.
     **/
    private static String buildPermissionQueryClause(Object permissionsAPINamesObject, String permissionType) {
        String queryClause = '';
        String permissionSetsToCheck;

        if (permissionsAPINamesObject instanceof String) {
            permissionSetsToCheck = toInClause(String.valueOf(permissionsAPINamesObject));
        }

        if ('PSG'.equalsIgnoreCase(permissionType) && String.isNotBlank(permissionSetsToCheck)) {
            List<String> permissionSetIds = new List<String>();

            List<PermissionSetGroupComponent> components = [
                    SELECT PermissionSetId
                    FROM PermissionSetGroupComponent
                    WHERE
                            PermissionSetGroup.DeveloperName IN :((List<String>) permissionsAPINamesObject.toString()
                                    .split(','))
            ];

            for (PermissionSetGroupComponent component : components) {
                permissionSetIds.add('\'' + String.escapeSingleQuotes(component.PermissionSetId) + '\'');
            }

            if (!permissionSetIds.isEmpty()) {
                queryClause += ' AND ParentId IN (' + String.join(permissionSetIds, ', ') + ')';
            }
        } else if ('PS'.equalsIgnoreCase(permissionType) && String.isNotBlank(permissionSetsToCheck)) {
            queryClause += ' AND Parent.Name IN (' + permissionSetsToCheck + ')';
        }

        return queryClause;
    }

    /**
     * @description   Converts a comma-separated string into a SOQL-compatible IN clause string.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         csv A comma-separated string of values.
     * @return        String A formatted string for use in a SOQL IN clause (e.g., "'Value1','Value2'").
     **/
    private static String toInClause(String csv) {
        List<String> values = new List<String>();
        for (String item : csv.split(',')) {
            if (String.isNotBlank(item)) {
                values.add('\'' + String.escapeSingleQuotes(item.trim()) + '\'');
            }
        }
        return String.join(values, ', ');
    }

    /**
     * @description   Converts a Set of Ids into a SOQL-compatible IN clause string.
     * @author        Oumaima Arbani | 2025-08-22
     * @param         ids A set of record Ids.
     * @return        String A formatted string for use in a SOQL IN clause.
     **/
    private static String toInClauseFromSet(Set<Id> ids) {
        List<String> quotedIds = new List<String>();
        for (Id recordId : ids) {
            quotedIds.add('\'' + String.escapeSingleQuotes(String.valueOf(recordId)) + '\'');
        }
        return String.join(quotedIds, ', ');
    }

    /**
     * @description   Inner class to act as a standardized wrapper for various permission-related records.
     **/
    private class PermissionRecord {
        Id permissionSetId;
        String referenceValue; // Used for Apex Class, VF Page, Custom Permission names
        Object sourceRecord;

        /**
         * @description   Constructor to initialize the wrapper from a raw record.
         * @author        Oumaima Arbani | 2025-08-22
         * @param         record The source record, which can be an SObject, Map, or PermissionLink.
         * @param         permissionToCheck The type of permission, used to determine how properties are extracted.
         **/
        PermissionRecord(Object record, String permissionToCheck) {
            this.sourceRecord = record;
            if (record instanceof SObject) {
                SObject mySObject = (SObject) record;
                this.permissionSetId = (permissionToCheck == 'PermissionSet')
                        ? (Id) mySObject.get('Id')
                        : (Id) mySObject.get('ParentId');
            } else if (record instanceof Map<String, Object>) {
                Map<String, Object> recordMap = (Map<String, Object>) record;
                this.permissionSetId = (Id) recordMap.get('ParentId');
            } else if (record instanceof PSLab_SetupEntityAccessTransformer.PermissionLink) {
                PSLab_SetupEntityAccessTransformer.PermissionLink link = (PSLab_SetupEntityAccessTransformer.PermissionLink) record;
                this.permissionSetId = link.parentId;
                this.referenceValue = link.referenceFieldValue;
            }
        }
    }
}