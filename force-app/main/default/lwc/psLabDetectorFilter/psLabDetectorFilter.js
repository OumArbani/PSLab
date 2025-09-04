/**

 * Created by oarbani on 16/4/2025.

 */

import { LightningElement, track } from "lwc";

import { permissionDetectorFilterSettings } from "c/psLabCoreUtils";

import getPermissionsOrUsersList from "@salesforce/apex/PSLab_PermissionAnalysisController.getPermissionsOrUsersList";

import searchUsers from "@salesforce/apex/PSLab_PermissionAnalysisController.searchUsers";

import getPermissionSetHierarchyByUserId from "@salesforce/apex/PSLab_PermissionAnalysisController.getPermissionSetHierarchyByUserId";

import getOptionsBySelectedPermission from "@salesforce/apex/PSLab_PermissionAnalysisController.getOptionsBySelectedPermission";

import getDetectedPermissions from "@salesforce/apex/PSLab_PermissionAnalysisController.getDetectedPermissions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
const SEARCH_DELAY = 350;

export default class PsLabDetectorFilter extends LightningElement {
  filterSettings = permissionDetectorFilterSettings;

  selectedPermissionTypeOption;

  selectedPermissionToCheck;
  selectedPermissionToCheckPreviousState;
  selectedObjectForFLS;
  @track optionsList;
  @track usersAndPermissionsOptions;

  @track filterItemData = {};

  showSpinner = false;

  _options;

  @track selectedMetadataOptions = [];

  @track selectedSecurityOptions = [];
  selectedFilterConditionValue;
  permissionSetsOrPSGApiNames;

  @track _objectOptionsForFLS = [];

  get objectOptionsForFLS() {
    return this._objectOptionsForFLS;
  }

  get permissionTypeOptions() {
    return this.filterSettings.permissionTypeOptions;
  }

  get permissionOptions() {
    return this.filterSettings.permissionOptions;
  }

  get filterOptions() {
    return this.filterSettings.filterOptions;
  }

  get permissionsLabel() {
    const labels = {
      PSG: this.filterSettings.psgInputLabel,
      PS: this.filterSettings.psInputLabel,
      User: this.filterSettings.userInputLabel
    };
    return labels[this.selectedPermissionTypeOption] || "";
  }

  get isPermissionTypeSelected() {
    return ["PSG", "PS", "User"].includes(this.selectedPermissionTypeOption);
  }

  get showObjectSelectionForFLS() {
    return this.selectedPermissionToCheck === "FieldPermissions";
  }

  get noFieldsAvailable() {
    return this.filterItemData && Array.isArray(this.filterItemData.options) && this.filterItemData.options.length === 0;
  }

  get filterSecurityPermissions() {
    if (
      Array.isArray(this.selectedMetadataOptions) &&
      this.securityOptions.length
    ) {
      const isSingleOption = this.securityOptions.length === 1;
      return {
        label:
          this.permissionOptions.find(
            (item) => item.value === this.selectedPermissionToCheck
          ).label + " Permissions",

        isRequired: true,
        isStandardCombobox: false,
        isCustomCombobox: false,
        isCheckboxGroup: true,
        options: this.securityOptions,
        disabled: this.noFieldsAvailable || isSingleOption,
        initialValue: isSingleOption  ? [this.securityOptions[0].value] : []
      };
    }
    return {};
  }

  get securityOptions() {
    switch (this.selectedPermissionToCheck) {
      case "PermissionSetTabSetting":
        return this.filterSettings.tabsOptions;

      case "ObjectPermissions":
        return this.filterSettings.olsOptions;

      case "FieldPermissions":
        return this.filterSettings.flsOptions;

      default:
        return "";
    }
  }

  get showFilterItemData() {
    return this.filterItemData;
  }

  get filterItemDataObjectForFLS() {
    return {
      label: "Object",
      isCustomCombobox: true,
      isStandardCombobox: false,
      isRequired: true,
      isMultiSelect: false,
      options: this.objectOptionsForFLS
    };
  }

  get isMultiSelect() {
    return (
      this.selectedPermissionTypeOption === "PSG" ||
      this.selectedPermissionTypeOption === "PS"
    );
  }

  get isRequired() {
    return this.selectedPermissionTypeOption === "User";
  }

  get metadataNames() {
    if (
      [
        "TabSet",
        "FlowDefinition",
        "CustomMetadataType",
        "CustomSetting"
      ].includes(this.selectedPermissionToCheck)
    ) {
      let foundElements;
      if (Array.isArray(this.selectedMetadataOptions)) {
        foundElements = this._options.filter((element) =>
          this.selectedMetadataOptions.includes(element.value)
        );
      } else if (this.selectedMetadataOptions) {
        const foundElement = this._options.find(
          (element) => element.value === this.selectedMetadataOptions
        );
        foundElements = foundElement ? [foundElement] : [];
      } else {
        return "";
      }
      if (this.selectedPermissionToCheck === 'FlowDefinition'){
        return foundElements.map((element) => element.value).toString();
      }
      return foundElements.map((element) => element.Id).toString();
    }

    if (this.selectedObjectForFLS) {
      return this.selectedObjectForFLS.toString();
    }

    if (this.selectedMetadataOptions.length) {
      return Array.isArray(this.selectedMetadataOptions)
        ? this.selectedMetadataOptions.join(", ")
        : this.selectedMetadataOptions.toString();
    }

    return "";
  }

  get disableDetectButton() {
    if (
      !this.selectedPermissionTypeOption ||
      this.selectedMetadataOptions.length === 0 ||
      !this.selectedFilterConditionValue
    ) {
      return true;
    }

    switch (this.selectedPermissionToCheck) {
      case "ObjectPermissions":
        return this.selectedSecurityOptions.length === 0;
      case "FieldPermissions":
        return (
            this.selectedSecurityOptions.length === 0 || !this.selectedObjectForFLS
        );
      default:
        return false;
    }
  }

  get isUserSearchMode() {
    return this.selectedPermissionTypeOption === 'User';
  }


  connectedCallback() {
    this.selectedFilterConditionValue = this.filterOptions[0]?.value || "";
  }

  handlePermissionTypeChange(event) {
    this.permissionSetsOrPSGApiNames = "";
    this.selectedPermissionTypeOption = event.detail.value;
    const clearContextEvent = new CustomEvent("clearcontext");
    this.dispatchEvent(clearContextEvent);
    this.getPermissionsOrUsersList();
  }

  handleUserSearch(event) {
    const searchTerm = event.detail.value;
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    this.searchTimeout = setTimeout(() => {
      if (searchTerm && searchTerm.length >= 2) {
        this.showSpinner = true;
        searchUsers({ searchTerm: searchTerm })
            .then(result => {
              this.usersAndPermissionsOptions = result;
            })
            .catch(error => {
              this.showToast('Error', 'User search failed.', 'error');
              console.error('User search error:', error);
              this.usersAndPermissionsOptions = [];
            })
            .finally(() => {
              this.showSpinner = false;
            });
      } else {
        this.usersAndPermissionsOptions = [];
      }
    }, SEARCH_DELAY);
  }

  handlePermissionOptionsChange(event) {
    this.selectedObjectForFLS = "";
    this.selectedMetadataOptions.length = 0;
    this.selectedPermissionToCheck = event.detail.value;
    if (this.selectedPermissionToCheck === "FieldPermissions") {
      this.selectedPermissionToCheckPreviousState = "FieldPermissions";
      this.selectedPermissionToCheck = "ObjectPermissions";
    }

    this.template.querySelectorAll('c-ps-lab-detector-filter-item')
        .forEach(child => child.resetInternalSelection());

    this.getOptionsBySelectedPermission();

    const selectedPermission = this.selectedPermissionToCheckPreviousState
      ? this.selectedPermissionToCheckPreviousState
      : this.selectedPermissionToCheck;
    this.filterItemData = {
      label: this.permissionOptions.find(
        (item) => item.value === selectedPermission
      ).label,
      isCustomCombobox: true,
      isStandardCombobox: false,
      isRequired: true,
      isMultiSelect: !(
        this.selectedPermissionToCheck === "ObjectPermissions" ||
        this.selectedPermissionToCheck === "FieldPermissions"
      )
    };
  }

  handleObjectSelectionForFLS(event) {
    this.selectedObjectForFLS = event.detail.values;
    this.getOptionsBySelectedPermission(this.selectedObjectForFLS?.toString());
  }

  handleMetadataSelectionChange(event) {
    this.selectedMetadataOptions = event.detail.values || [];
    //this.selectedSecurityOptions = [];
  }

  handleMetadataPermissionsSelectionChange(event) {
    this.selectedSecurityOptions = event.detail.values;
  }

  handlePermissionsAPINameChange(event) {
    this.permissionSetsOrPSGApiNames = event.detail.values;
    if (
      this.selectedPermissionTypeOption === "User" &&
      this.permissionSetsOrPSGApiNames
    ) {
      this.getPermissionSetHierarchyByUserId();
    } else {
      const clearContextEvent = new CustomEvent("clearcontext");
      this.dispatchEvent(clearContextEvent);
    }
  }

  handleFilterConditionChange(event) {
    this.selectedFilterConditionValue = event.detail.value;
  }

  async getPermissionsOrUsersList() {
    this.showSpinner = true;
    try {
      const data = await getPermissionsOrUsersList({
        searchType: this.selectedPermissionTypeOption
      });
      if (data) {
        this.usersAndPermissionsOptions = data;
      }
    } catch (error) {
      console.error("getPermissionsOrUsersList error:", error);
      this.showToast(
        "Error",
        "Failed to load permissions/users list. Please try again.",
        "error"
      );
      this.usersAndPermissionsOptions = [];
    } finally {
      this.showSpinner = false;
    }
  }

  async getPermissionSetHierarchyByUserId() {
    try {
      const data = await getPermissionSetHierarchyByUserId({
        userId: this.permissionSetsOrPSGApiNames.toString()
      });
      if (data) {
        const detectionEvent = new CustomEvent("detection", {
          detail: {
            permissionSets: data,
            payload: {}
          }
        });
        this.dispatchEvent(detectionEvent);
      } else {
        this.showToast(
          "Warning",
          "No permission set hierarchy found for this user.",
          "warning"
        );
      }
    } catch (error) {
      console.error("getPermissionSetHierarchyByUserId error:", error);
      this.showToast(
        "Error",
        "Unable to retrieve permission set hierarchy.",
        "error"
      );
    }
  }

  async detectPermissions() {
    const payload = {
      permissionType: this.selectedPermissionTypeOption, // 'PS OR PSG'
      permissionsAPINames: this.permissionSetsOrPSGApiNames?.toString(),
      permission: this.selectedPermissionToCheck, // 'OLS, FLS, APP Assignment...'
      metadataNames: this.metadataNames, // Account, Contact, Apex Class name...
      subMetadataAPIName: this.selectedObjectForFLS
        ? this.selectedObjectForFLS +
          "." +
          this.selectedMetadataOptions.toString()
        : "", // Object fields (Account.Type)
      securityPermissions: this.selectedSecurityOptions.toString(), // READ, EDIT, ETC..
      condition: this.selectedFilterConditionValue
    };

    try {
      const permissionSets = await getDetectedPermissions({ payload: payload });
      if (permissionSets) {
        const detectionEvent = new CustomEvent("detection", {
          detail: {
            permissionSets: permissionSets,
            payload: payload
          }
        });

        this.dispatchEvent(detectionEvent);
      } else {
        this.showToast(
          "No Results",
          "No matching permissions detected.",
          "warning"
        );
      }
    } catch (error) {
      console.error("detectPermissions error:", error);
      this.showToast(
        "Error",
        "Failed to detect permissions. Please try again.",
        "error"
      );
    }
  }

  async getOptionsBySelectedPermission(objectName) {
    this.showSpinner = true;
    try {
      const options = await getOptionsBySelectedPermission({
        objectName: objectName,
        selectedPermission: this.selectedPermissionToCheck
      });
      if (options) {
        this.filterItemData.options = options;
        this._options = options;
        if (this.selectedPermissionToCheckPreviousState) {
          this.filterItemData.options = [];
          this._objectOptionsForFLS = options;
          this.selectedPermissionToCheck =
            this.selectedPermissionToCheckPreviousState;
          this.selectedPermissionToCheckPreviousState = "";
        }
      } else {
        this.showToast(
          "No Results",
          "No options found for the selected permission.",
          "warning"
        );
        this.filterItemData.options = [];
      }
    } catch (error) {
      console.error("getOptionsBySelectedPermission error:", error);
      this.showToast(
        "Error",
        "Failed to load options for the selected permission.",
        "error"
      );
      this.filterItemData.options = [];
    } finally {
      this.showSpinner = false;
    }
  }

  resetFilterInputs() {
    this.dispatchEvent(new CustomEvent("filterreset"));

    // Reset all selected values
    this.selectedPermissionTypeOption = null;
    this.selectedPermissionToCheck = null;
    this.selectedObjectForFLS = '';
    this.permissionSetsOrPSGApiNames = null;
    this.selectedMetadataOptions = [];
    this.selectedSecurityOptions = [];
    this.selectedFilterConditionValue = this.filterOptions[0]?.value || '';

    // Reset the data sources for all child components
    this.usersAndPermissionsOptions = [];
    this.filterItemData = {};
    this._objectOptionsForFLS = [];

    this.template.querySelectorAll('c-ps-lab-detector-filter-item')
        .forEach(child => child.resetInternalSelection());
  }

  showToast(title, message, variant = "info") {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}