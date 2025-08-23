/**
 * @author       : Oumaima ARBANI
 * @date         : 21/8/2025
 * @description  : Test class for PSLab_PermissionAnalysisHelper.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_PermissionAnalysisHelperTest {
    private class ToolingApiMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String body =
                    '{ "size": 1, "totalSize": 1, "done": true, "records": [ { "attributes": { "type": "PermissionSetTabSetting", "url": "/services/data/v61.0/tooling/sobjects/PermissionSetTabSetting/someId" }, "Visibility": "Visible", "ParentId": "' +
                    getTestPermissionSet().Id +
                    '", "Name": "Account" } ] }';
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void makeData() {
        User psLabUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User']
                        .Id,
                LastName = 'testlastname',
                Email = 'test@test.com',
                Username = 'psLabuser@testpslab.com',
                CompanyName = 'Test Inc.',
                Title = 'Tester',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive = true
        );
        insert psLabUser;

        Map<String, Id> permissionSetNameToId = new Map<String, Id>();
        for (PermissionSet ps : [
                SELECT Id, Name
                FROM PermissionSet
                WHERE Name IN ('PSLab_PermissionSetGroup', 'PSLabUser')
        ]) {
            permissionSetNameToId.put(ps.Name, ps.Id);
        }

        PermissionSet testPermissionSet = new PermissionSet(
                Name = 'Test_Permission_Set',
                Label = 'Test Permission Set'
        );
        insert testPermissionSet;

        PermissionSetGroup testPermissionSetGroup = new PermissionSetGroup(
                DeveloperName = 'Test_Permission_Set_Group',
                MasterLabel = 'Test Permission Set Group'
        );
        insert testPermissionSetGroup;

        Test.calculatePermissionSetGroup(testPermissionSetGroup.Id);

        List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
        List<PermissionSetGroupComponent> componentsToInsert = new List<PermissionSetGroupComponent>();
        List<ObjectPermissions> objectPermissionsToInsert = new List<ObjectPermissions>();
        List<FieldPermissions> fieldPermissionsToInsert = new List<FieldPermissions>();

        if (permissionSetNameToId.containsKey('PSLabUser')) {
            assignmentsToInsert.add(
                    new PermissionSetAssignment(
                            AssigneeId = psLabUser.Id,
                            PermissionSetId = permissionSetNameToId.get('PSLabUser')
                    )
            );
        }

        assignmentsToInsert.add(
                new PermissionSetAssignment(AssigneeId = psLabUser.Id, PermissionSetId = testPermissionSet.Id)
        );

        assignmentsToInsert.add(
                new PermissionSetAssignment(AssigneeId = psLabUser.Id, PermissionSetGroupId = testPermissionSetGroup.Id)
        );

        componentsToInsert.add(
                new PermissionSetGroupComponent(
                        PermissionSetGroupId = testPermissionSetGroup.Id,
                        PermissionSetId = testPermissionSet.Id
                )
        );

        objectPermissionsToInsert.add(
                new ObjectPermissions(ParentId = testPermissionSet.Id, SobjectType = 'Contact', PermissionsRead = true)
        );

        objectPermissionsToInsert.add(
                new ObjectPermissions(ParentId = testPermissionSet.Id, SobjectType = 'Account', PermissionsRead = true)
        );

        fieldPermissionsToInsert.add(
                new FieldPermissions(
                        ParentId = testPermissionSet.Id,
                        SobjectType = 'Account',
                        Field = 'Account.Type',
                        PermissionsRead = true
                )
        );

        insert assignmentsToInsert;
        insert componentsToInsert;
        insert objectPermissionsToInsert;
        insert fieldPermissionsToInsert;
    }

    /**
     * @description  : Retrieves the test permission set created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : PermissionSet record for testing purposes.
     **/
    private static PermissionSet getTestPermissionSet() {
        return [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Permission_Set' LIMIT 1];
    }

    /**
     * @description  : Retrieves the test user created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : User record for testing purposes.
     **/
    private static User getTestUser() {
        return [SELECT Id, Name, Username FROM User WHERE Username = 'psLabuser@testpslab.com' LIMIT 1];
    }

    /**
     * @description  : Retrieves the test permission set group created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : PermissionSetGroup record for testing purposes.
     **/
    private static PermissionSetGroup getTestPermissionSetGroup() {
        return [
                SELECT Id, DeveloperName
                FROM PermissionSetGroup
                WHERE DeveloperName = 'Test_Permission_Set_Group'
                LIMIT 1
        ];
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Applications for 'TabSet'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByTabSet() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('TabSet', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');
        Boolean isPermissionsLabFound = false;
        for (Object appObject : results) {
            Map<String, Object> appMap = (Map<String, Object>) appObject;
            String appValue = (String) appMap.get('value');
            if (appValue == 'PermissionsLab') {
                isPermissionsLabFound = true;
                break;
            }
        }
        Assert.isTrue(isPermissionsLabFound, 'Results should contain Permissions Lab Application');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns SObjects for 'ObjectPermissions'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByObjectPermissions() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('ObjectPermissions', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isAccountObjectFound = false;
        for (Object result : results) {
            Map<String, Object> orgObject = (Map<String, Object>) result;
            String objectValue = (String) orgObject.get('value');
            if (objectValue == 'Account') {
                isAccountObjectFound = true;
                break;
            }
        }
        Assert.isTrue(isAccountObjectFound, 'Results should contain Account Object');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns fields for 'FieldPermissions'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByFieldPermissions() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper(
                        'FieldPermissions',
                        'Account'
                );
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isTypeFieldFound = false;
        for (Object result : results) {
            Map<String, Object> fieldPermission = (Map<String, Object>) result;
            String objectValue = (String) fieldPermission.get('value');
            if (objectValue == 'Type') {
                isTypeFieldFound = true;
                break;
            }
        }
        Assert.isTrue(isTypeFieldFound, 'Results should contain Type Field');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Apex Classes for 'ApexClass'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByApexClass() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('ApexClass', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isPSLab_PermissionAnalysisControllerClassFound = false;
        for (Object result : results) {
            Map<String, Object> apexClassObject = (Map<String, Object>) result;
            String apexClassObjectValue = (String) apexClassObject.get('value');
            if (apexClassObjectValue == 'PSLab_PermissionAnalysisController') {
                isPSLab_PermissionAnalysisControllerClassFound = true;
                break;
            }
        }
        Assert.isTrue(
                isPSLab_PermissionAnalysisControllerClassFound,
                'Results should contain PSLab_PermissionAnalysisController Apex Class'
        );
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Apex Pages for 'ApexPage'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByApexPage() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('ApexPage', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isPSLab_ApexPageFound = false;
        for (Object result : results) {
            Map<String, Object> apexPageObject = (Map<String, Object>) result;
            String apexPageObjectValue = (String) apexPageObject.get('value');
            if (apexPageObjectValue == 'PSLab_ApexPage') {
                isPSLab_ApexPageFound = true;
                break;
            }
        }
        Assert.isTrue(isPSLab_ApexPageFound, 'Results should contain PSLab_ApexPage Apex page');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Flows for 'FlowDefinition'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByFlowDefinition() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('FlowDefinition', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Custom Metadata for 'CustomMetadataType'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByCustomMetadataType() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('CustomMetadataType', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isCustomMetadataTypeFound = false;
        for (Object result : results) {
            Map<String, Object> customMetadataTypeObject = (Map<String, Object>) result;
            String customMetadataTypeObjectValue = (String) customMetadataTypeObject.get('value');
            if (customMetadataTypeObjectValue == 'PSLab_SP') {
                isCustomMetadataTypeFound = true;
                break;
            }
        }
        Assert.isTrue(isCustomMetadataTypeFound, 'Results should contain PSLab_SP Custom metadata type');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Custom Settings for 'CustomSetting'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByCustomSetting() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('CustomSetting', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isCustomSettingFound = false;
        for (Object result : results) {
            Map<String, Object> customSettingObject = (Map<String, Object>) result;
            String customSettingObjectValue = (String) customSettingObject.get('value');
            if (customSettingObjectValue == 'PSLab_CustomSetting') {
                isCustomSettingFound = true;
                break;
            }
        }
        Assert.isTrue(isCustomSettingFound, 'Results should contain PSLab_CustomSetting Custom setting');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Custom Permissions for 'CustomPermission'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByCustomPermission() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('CustomPermission', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isCustomPermissionFound = false;
        for (Object result : results) {
            Map<String, Object> customPermissionObject = (Map<String, Object>) result;
            String customPermissionObjectValue = (String) customPermissionObject.get('value');
            if (customPermissionObjectValue == 'PSLab_CustomPermission') {
                isCustomPermissionFound = true;
                break;
            }
        }
        Assert.isTrue(isCustomPermissionFound, 'Results should contain PSLab_CustomPermission Custom permission');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns Tab Definitions for 'PermissionSetTabSetting'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByPermissionSetTabSetting() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper(
                        'PermissionSetTabSetting',
                        ''
                );
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');

        Boolean isTabFound = false;
        for (Object result : results) {
            Map<String, Object> tabObject = (Map<String, Object>) result;
            String tabValue = (String) tabObject.get('value');
            if (tabValue == 'Permissions_Analyser') {
                isTabFound = true;
                break;
            }
        }
        Assert.isTrue(isTabFound, 'Results should contain Permissions_Analyser Custom tab');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns System Permissions for 'PermissionSet'.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsBySystemPermissions() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('PermissionSet', '');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');
    }

    /**
     * @description  : Verifies getOptionsBySelectedPermissionHelper returns an empty list for invalid input.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsByEmptyValues() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper('', '');
            }
            Test.stopTest();
        }
        Assert.isTrue(results.isEmpty(), 'The result list should be empty.');
    }

    /**
     * @description  : Verifies the construction of a permission hierarchy for a specific user.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionSetHierarchyByUserId() {
        User psLabUser = getTestUser();
        PSLab_HierarchyNode permissionsHierarchy = new PSLab_HierarchyNode();
        List<PSLab_HierarchyNode> hierarchyChildren = new List<PSLab_HierarchyNode>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                permissionsHierarchy = PSLab_PermissionAnalysisHelper.getPermissionSetHierarchyByUserId(psLabUser.Id);
                hierarchyChildren = permissionsHierarchy.children;
            }
            Test.stopTest();
        }
        Assert.isNotNull(permissionsHierarchy, 'Hierarchy should not be null');
        Assert.areEqual(
                psLabUser.Name + '\n(' + psLabUser.Username + ')',
                permissionsHierarchy.name,
                'Hierarchy name should be: ' + psLabUser.Name + '\n(' + psLabUser.Username + ')'
        );
        Assert.areEqual(
                2,
                hierarchyChildren.size(),
                'Children hierarchy should contain standalone permission sets and permission set groups'
        );
    }

    /**
     * @description  : Verifies the construction of the hierarchy for all permissions in the org.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionSetHierarch() {
        User psLabUser = getTestUser();
        PSLab_HierarchyNode permissionsHierarchy = new PSLab_HierarchyNode();
        List<PSLab_HierarchyNode> hierarchyChildren = new List<PSLab_HierarchyNode>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                permissionsHierarchy = PSLab_PermissionAnalysisHelper.getPermissionSetHierarchy();
                hierarchyChildren = permissionsHierarchy.children;
                System.debug(JSON.serializePretty(permissionsHierarchy));
            }
            Test.stopTest();
        }
        Assert.isNotNull(permissionsHierarchy, 'Hierarchy should not be null');
        Assert.areEqual('parentNode', permissionsHierarchy.type, 'Hierarchy parent type should be: parentNode');
        Assert.areEqual(
                2,
                hierarchyChildren.size(),
                'Children hierarchy should contain standalone permission sets and permission set groups'
        );
    }

    /**
     * @description  : Verifies the retrieval of all Permission Sets.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOrgPermissionSets() {
        User psLabUser = getTestUser();
        List<Object> permissionSets = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                permissionSets = PSLab_PermissionAnalysisHelper.getPermissionsOrUsersList('PS');
            }
            Test.stopTest();
        }

        Assert.isNotNull(permissionSets, 'The permissionSets list should not be null.');

        Boolean isPSLabPermissionSetFound = false;
        for (Object result : permissionSets) {
            Map<String, Object> permissionSet = (Map<String, Object>) result;
            String permissionSetName = (String) permissionSet.get('value');
            if (permissionSetName == 'PSLabUser') {
                isPSLabPermissionSetFound = true;
                break;
            }
        }

        Assert.isTrue(isPSLabPermissionSetFound, 'Results should contain PSLabUser Permission set');
    }

    /**
     * @description  : Verifies the retrieval of all Permission Set Groups.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOrgPermissionSetGroups() {
        User psLabUser = getTestUser();
        List<Object> permissionSetGroups = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                permissionSetGroups = PSLab_PermissionAnalysisHelper.getPermissionsOrUsersList('PSG');
            }
            Test.stopTest();
        }

        Assert.isNotNull(permissionSetGroups, 'The permission Set groups list should not be null.');

        Boolean isPSLabPermissionSetGroupFound = false;
        for (Object result : permissionSetGroups) {
            Map<String, Object> permissionSetGroup = (Map<String, Object>) result;
            String permissionSetGroupName = (String) permissionSetGroup.get('value');
            if (permissionSetGroupName == 'PSLab_PermissionSetGroup') {
                isPSLabPermissionSetGroupFound = true;
                break;
            }
        }

        Assert.isTrue(
                isPSLabPermissionSetGroupFound,
                'Results should contain PSLab_PermissionSetGroup Permission set group'
        );
    }

    /**
     * @description  : Verifies the retrieval of all Users.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOrgUsers() {
        User psLabUser = getTestUser();
        List<Object> users = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                users = PSLab_PermissionAnalysisHelper.getPermissionsOrUsersList('User');
            }
            Test.stopTest();
        }

        Assert.isNotNull(users, 'The users list should not be null.');
    }

    /**
     * @description  : Verifies getPermissionsOrUsersList returns an empty list for invalid input.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionsOrUsersListWithEmptyValue() {
        User psLabUser = getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisHelper.getPermissionsOrUsersList('');
            }
            Test.stopTest();
        }

        Assert.isTrue(results.isEmpty(), 'The result list should be empty.');
    }

    /**
     * @description  : Verifies detection of Object Permissions.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetDetectedPermissionsObjectPerms() {
        User psLabUser = getTestUser();
        PermissionSet ps = getTestPermissionSet();
        Map<String, Object> payload = new Map<String, Object>{
                'permission' => 'ObjectPermissions',
                'permissionType' => 'PS',
                'permissionsAPINames' => ps.Name,
                'metadataNames' => 'Account',
                'securityPermissions' => 'PermissionsRead,PermissionsEdit',
                'condition' => 'OR'
        };
        List<PSLab_DetectedPermission> results;
        System.runAs(psLabUser) {
            Test.startTest();
            results = PSLab_PermissionAnalysisHelper.getDetectedPermissions(payload);
            Test.stopTest();
        }
        Assert.areEqual(1, results.size(), 'Should find one matching permission');
        Assert.areEqual(ps.Id, results[0].permissionSetId, 'Permission Set Id should match');
        Assert.isTrue(results[0].objectPermissionDetails.permissionsRead, 'Read permission should be true');
    }

    /**
     * @description   : Verifies detection of Field Permissions.
     * @author        : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetDetectedPermissionsFieldPerms() {
        User psLabUser = getTestUser();
        PermissionSet ps = getTestPermissionSet();
        Map<String, Object> payload = new Map<String, Object>{
                'permission' => 'FieldPermissions',
                'permissionType' => 'PS',
                'permissionsAPINames' => ps.Name,
                'metadataNames' => 'Account',
                'subMetadataAPIName' => 'Account.Type',
                'securityPermissions' => 'PermissionsRead',
                'condition' => 'OR'
        };
        List<PSLab_DetectedPermission> results;
        System.runAs(psLabUser) {
            Test.startTest();
            results = PSLab_PermissionAnalysisHelper.getDetectedPermissions(payload);
            Test.stopTest();
        }
        Assert.areEqual(1, results.size(), 'Should find one matching permission');
        Assert.areEqual('Account.Type', results[0].fieldPermissionDetails.field, 'Field API name should match');
    }

    /**
     * @description   : Verifies detection of Apex Class access.
     * @author        : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetDetectedPermissionsApexClass() {
        User psLabUser = getTestUser();
        PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'PSLabUser' LIMIT 1];
        Map<String, Object> payload = new Map<String, Object>{
                'permission' => 'ApexClass',
                'permissionType' => 'PS',
                'permissionsAPINames' => ps.Name,
                'metadataNames' => 'PSLab_PermissionAnalysisHelper',
                'condition' => 'OR'
        };
        List<PSLab_DetectedPermission> results;
        System.runAs(psLabUser) {
            Test.startTest();
            results = PSLab_PermissionAnalysisHelper.getDetectedPermissions(payload);
            Test.stopTest();
        }
        Assert.areEqual(1, results.size(), 'Should find one matching permission');
        Assert.areEqual('PSLab_PermissionAnalysisHelper', results[0].apexClassPermissionDetails.name);
    }

    /**
     * @description  : Verifies detection of System Permissions.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetDetectedPermissionsSystemPerms() {
        User psLabUser = getTestUser();
        PermissionSet ps = getTestPermissionSet();
        Map<String, Object> payload = new Map<String, Object>{
                'permission' => 'PermissionSet',
                'permissionType' => 'PS',
                'permissionsAPINames' => ps.Name,
                'metadataNames' => 'PermissionsApiUserOnly',
                'condition' => 'OR'
        };
        List<PSLab_DetectedPermission> results;
        System.runAs(psLabUser) {
            Test.startTest();
            results = PSLab_PermissionAnalysisHelper.getDetectedPermissions(payload);
            System.debug(results);
            Test.stopTest();
        }
        Assert.isTrue(results.size() > 0, 'Should not be empty');
        Assert.isTrue(results[0].genericPermissionSetDetails.permissions.get('PermissionsApiUserOnly'));
    }

    /**
     * @description  : Verifies detection of Tab Settings using a mock callout.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetDetectedPermissionsTabSettingCallout() {
        User psLabUser = getTestUser();
        PermissionSet ps = getTestPermissionSet();
        Map<String, Object> payload = new Map<String, Object>{
                'permission' => 'PermissionSetTabSetting',
                'permissionType' => 'PS',
                'permissionsAPINames' => ps.Name,
                'metadataNames' => 'Account',
                'securityPermissions' => 'Visible',
                'condition' => 'OR'
        };
        List<PSLab_DetectedPermission> results;
        System.runAs(psLabUser) {
            Test.setMock(HttpCalloutMock.class, new ToolingApiMock());
            Test.startTest();
            results = PSLab_PermissionAnalysisHelper.getDetectedPermissions(payload);
            Test.stopTest();
        }
        Assert.areEqual(1, results.size(), 'Should find one tab setting from mock');
        Assert.areEqual('Visible', results[0].tabSettingDetails.visibility);
    }

    /**
     * @description  : Verifies permission detection filtering by Permission Set Group.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetDetectedPermissionsPSGFilter() {
        User psLabUser = getTestUser();
        PermissionSetGroup psg = getTestPermissionSetGroup();
        Map<String, Object> payload = new Map<String, Object>{
                'permission' => 'ObjectPermissions',
                'permissionType' => 'PSG',
                'permissionsAPINames' => psg.DeveloperName,
                'metadataNames' => 'Account',
                'securityPermissions' => 'PermissionsRead',
                'condition' => 'OR'
        };
        List<PSLab_DetectedPermission> results;
        System.runAs(psLabUser) {
            Test.startTest();
            results = PSLab_PermissionAnalysisHelper.getDetectedPermissions(payload);
            Test.stopTest();
        }
        Assert.areEqual(1, results.size(), 'Should find one permission via PSG');
        Assert.isTrue(results[0].includedIn.contains(psg.DeveloperName), 'Should be included in the test PSG');
    }
}