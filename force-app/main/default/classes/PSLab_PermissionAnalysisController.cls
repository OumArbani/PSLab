/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : 
 * @group        : PSLab
 **/
public with sharing class PSLab_PermissionAnalysisController{

    @AuraEnabled(Cacheable = true)
    public static List<Object> getPermissionsOrUsersList(String searchType) {
        return PSLab_PermissionAnalysisHelper.getPermissionsOrUsersList(searchType);
    }

    @AuraEnabled(Cacheable = true)
    public static List<Object> searchUsers(String searchTerm) {
        return PSLab_PermissionAnalysisHelper.searchUsers(searchTerm);
    }

    @AuraEnabled(Cacheable = true)
    public static PSLab_HierarchyNode getPermissionSetHierarchy() {
        return PSLab_PermissionAnalysisHelper.getPermissionSetHierarchy();
    }

    @AuraEnabled (Cacheable = true)
    public static List<Object> getOptionsBySelectedPermission(String selectedPermission, String objectName){
        return PSLab_PermissionAnalysisHelper.getOptionsBySelectedPermissionHelper(selectedPermission, objectName);
    }

    @AuraEnabled(Cacheable=true)
    public static PSLab_HierarchyNode getPermissionSetHierarchyByUserId(String userId){
        return PSLab_PermissionAnalysisHelper.getPermissionSetHierarchyByUserId(userId);
    }

    @AuraEnabled
    public static List<PSLab_DetectedPermission> getDetectedPermissions(Map<String, Object> payload) {
       return PSLab_PermissionAnalysisHelper.getDetectedPermissions(payload);
    }
}