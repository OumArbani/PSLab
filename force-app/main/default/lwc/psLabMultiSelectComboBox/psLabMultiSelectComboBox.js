/**
 * @description Multi-select combobox component for LWC.
 *
 * NOTE: This component was adapted from an open-source project that I can
 * no longer locate. The original author deserves full credit for the core
 * logic and structure. If you recognize this code, please open an issue on
 * this project's GitHub repository so that proper attribution can be provided.
 */

import { LightningElement, api, track } from "lwc";

export default class PsLabMultiSelectComboBox extends LightningElement {
  _options = [];

  @track selectedValues = [];
  @track searchTerm = '';
  showDropdown = false;

  @api label = '';
  @api showSpinner = false;
  @api name = '';
  @api required = false;
  @api isMultiSelect;
  @api isServerSearch = false;

  get options() {
    return this._options;
  }

  @api
  set options(options) {
    if (options) {
      this._options = options.map((opt, index) => {
        return {
          ...opt,
          uniqueKey: `${opt.value}-${index}`
        };
      });
    } else {
      this._options = [];
    }
  }

  @api
  get value() {
    return this.selectedValues;
  }

  set value(val) {
    if (Array.isArray(val)) {
      this.selectedValues = val;
    } else if (val) {
      this.selectedValues = [val];
    } else {
      this.selectedValues = [];
    }

    if (!this.isMultiSelect) {
      const selected = this.selectedOptions[0];
      this.searchTerm = selected ? selected.label : '';
    }
  }

  get hasOptions() {
    return this.options && this.options.length > 0;
  }

  connectedCallback() {
    document.addEventListener('click', this.handleOutsideClick);
  }

  disconnectedCallback() {
    document.removeEventListener('click', this.handleOutsideClick);
  }

  handleOutsideClick = () => {
    this.showDropdown = false;
  };

  stopPropagation(event) {
    event.stopPropagation();
  }

  get selectedOptions() {
    if (!this.options) {
      return [];
    }
    return this.options.filter(opt => this.selectedValues.includes(opt.value));
  }

  get filteredOptions() {
    if (!this.options) {
      return [];
    }
    const lower = this.searchTerm.toLowerCase();
    return this.options.filter(
      opt =>
        opt.label.toLowerCase().includes(lower) &&
        (!this.isMultiSelect || !this.selectedValues.includes(opt.value))
    );
  }

  get computedInputValue() {
    return this.searchTerm;
  }

  get noOptions() {
    return this.filteredOptions.length === 0;
  }

  handleInput(event) {
    this.searchTerm = event.target.value;
    this.showDropdown = true;

    if (this.isServerSearch) {
      this.dispatchEvent(new CustomEvent('search', {
        detail: { value: this.searchTerm }
      }));
    }
  }

  openDropdown() {
    this.showDropdown = true;
  }

  toggleDropdown() {
    this.showDropdown = !this.showDropdown;
  }

  handleSelect(event) {
    const value = event.currentTarget.dataset.value;
    const selected = this.options.find(opt => opt.value === value);

    if (this.isMultiSelect) {
      if (!this.selectedValues.includes(value)) {
        this.selectedValues = [...this.selectedValues, value];
        this.searchTerm = '';
      }
    } else {
      this.selectedValues = [value];
      this.searchTerm = event.currentTarget.dataset.label
    }

    this.dispatchEvent(new CustomEvent('change', {
      detail: { values: this.selectedValues }
    }));

    if (!this.isMultiSelect && selected) {
      this.searchTerm = selected.label;
    } else {
      this.searchTerm = '';
    }



    this.showDropdown = false;
  }

  handleRemove(event) {
    const value = event.currentTarget.dataset.value;
    this.selectedValues = this.selectedValues.filter(v => v !== value);

    this.dispatchEvent(new CustomEvent('change', {
      detail: { values: this.selectedValues }
    }));
  }
}
