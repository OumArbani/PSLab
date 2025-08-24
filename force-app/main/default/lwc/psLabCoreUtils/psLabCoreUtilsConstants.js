const PERMISSIONSET_TYPE_OPTIONS = [
  { label: "Permission Set Group", value: "PSG" },
  { label: "Permission Set", value: "PS" },
  { label: "User", value: "User" }
];

const PERMISSION_OPTIONS = [
  { label: "Assigned Apps", value: "TabSet" },
  { label: "Object Level Security", value: "ObjectPermissions" },
  { label: "Field Level Security", value: "FieldPermissions" },
  { label: "Tab Visibility Access", value: "PermissionSetTabSetting" },
  { label: "Apex Class Access", value: "ApexClass" },
  { label: "Visualforce Page Access", value: "ApexPage" },
  { label: "Flow Access", value: "FlowDefinition" },
  { label: "Custom Permissions Access", value: "CustomPermission" },
  { label: "Custom Metadata Types Access", value: "CustomMetadataType" },
  { label: "Custom Setting Definitions Access", value: "CustomSetting" },
  { label: "System Permissions", value: "PermissionSet" }
];

const OLS_OPTIONS = [
  { label: "All", value: "All" },
  { label: "Create", value: "PermissionsCreate" },
  { label: "Read", value: "PermissionsRead" },
  { label: "Edit", value: "PermissionsEdit" },
  { label: "Delete", value: "PermissionsDelete" },
  { label: "View All Records", value: "PermissionsViewAllRecords" },
  { label: "Modify All Records", value: "PermissionsModifyAllRecords" },
  { label: "View All Fields", value: "PermissionsViewAllFields" }
];

const FLS_OPTIONS = [
  { label: "All", value: "All" },
  { label: "Read", value: "PermissionsRead" },
  { label: "Edit", value: "PermissionsEdit" }
];

const TABS_OPTIONS = [{ label: "Default On", value: "DefaultOn" }];

const FILTER_OPTIONS = [
  { label: "All Conditions Are Met", value: "AND" },
  { label: "Any Condition Is Met", value: "OR" }
];

const PSG_INPUT_LABEL = "Permission Set Group API Names";
const PS_INPUT_LABEL = "Permission Sets API Names";
const USER_INPUT_LABEL = "Targeted User";

export const permissionDetectorFilterSettings = {
  permissionTypeOptions: PERMISSIONSET_TYPE_OPTIONS,
  permissionOptions: PERMISSION_OPTIONS,
  olsOptions: OLS_OPTIONS,
  flsOptions: FLS_OPTIONS,
  tabsOptions: TABS_OPTIONS,
  filterOptions: FILTER_OPTIONS,
  psgInputLabel: PSG_INPUT_LABEL,
  psInputLabel: PS_INPUT_LABEL,
  userInputLabel: USER_INPUT_LABEL
};