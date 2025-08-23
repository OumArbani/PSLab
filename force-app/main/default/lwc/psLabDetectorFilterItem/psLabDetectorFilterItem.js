/**
 * Created by oarbani on 16/4/2025.
 */

import { LightningElement, api } from "lwc";

export default class PsLabDetectorFilterItem extends LightningElement {
  selectedOptions = [];


  _filterItemData;

  get filterItemData() {
    return this._filterItemData;
  }

  @api
  set filterItemData(filterItemData) {
    this._filterItemData = filterItemData;
    if (filterItemData?.initialValue) {
      this.selectedOptions = filterItemData.initialValue;
      this.dispatchEvent(
          new CustomEvent("selectionchange", {
            detail: { values: this.selectedOptions }
          })
      );
    }
  }

  get label() {
    return this.filterItemData.label;
  }

  get options() {
    return this.filterItemData.options;
  }

  get isRequired() {
    return this.filterItemData.isRequired;
  }

  get isDisabled() {
    return this.filterItemData?.disabled;
  }

  get isMultiSelect() {
    return this.filterItemData.isMultiSelect;
  }

  get isStandardCombobox() {
    return this.filterItemData?.isStandardCombobox;
  }

  get isCustomCombobox() {
    return this.filterItemData?.isCustomCombobox;
  }

  get isCheckboxGroup() {
    return this.filterItemData?.isCheckboxGroup;
  }

  handleOptionsChange(event) {
    let selectedValues = [];
    if (this.isStandardCombobox) {
      selectedValues = event.detail.value ? [event.detail.value] : [];
    } else if (this.isCustomCombobox) {
      selectedValues = event.detail.values || [];
    } else if (this.isCheckboxGroup) {
      selectedValues = event.detail.value || [];
    }

    const allOption = "All";
    const allValues = (this.options || []).map((opt) => opt.value);
    if (selectedValues.includes(allOption)) {
      this.selectedOptions = allValues;
      selectedValues = allValues.filter((v) => v !== allOption);
    } else if (
      this.selectedOptions &&
      this.selectedOptions.includes(allOption) &&
      !selectedValues.includes(allOption)
    ) {
      this.selectedOptions = [];
      selectedValues = [];
    } else {
      this.selectedOptions = selectedValues;
      selectedValues = selectedValues.filter((v) => v !== allOption);
    }
    this.dispatchEvent(
      new CustomEvent("selectionchange", {
        detail: { values: selectedValues }
      })
    );
  }

  @api
  resetInternalSelection() {
    this.selectedOptions = [];
  }
}