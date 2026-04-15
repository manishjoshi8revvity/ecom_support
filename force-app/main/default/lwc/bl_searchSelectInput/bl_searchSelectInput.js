import { api, LightningElement } from 'lwc';

export default class Bl_searchSelectInput extends LightningElement {
  @api label;
  @api placeholder = 'Select an option';
  @api defaultValue;
  @api options = [];
  @api resetToDefault() {
    this.currentValue = this.defaultValue;
    this.emitValue();
    this.optionsVisible = false;
  }

  currentValue;
  optionsVisible = false;
  clickOnComponent = false;

  _outsideClickHandler;
  _arrowKeyHandler;

  connectedCallback() {
    this.currentValue = this.defaultValue;
    this.emitValue();
    window.addEventListener('click', this._outsideClickHandler = this.handleOutsideClick.bind(this));
    window.addEventListener('keydown', this._arrowKeyHandler = this.handleArrowKey.bind(this));
  }

  disconnectedCallback() {
    window.removeEventListener('click', this._outsideClickHandler);
    window.removeEventListener('keydown', this._arrowKeyHandler);
  }

  handleOutsideClick() {
    if(!this.optionsVisible || this.clickOnComponent) {
      this.clickOnComponent = false;
      return;
    }

    this.optionsVisible = false;
  }

  handleComponentClick(event) {
    this.clickOnComponent = true;
  }

  handleEnter(event) {
    if(event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      event.stopPropagation();
      this.showOptions(event);
    }
  }

  handleArrowKey(event) {
    let arrowDirection;

    if(!this.optionsVisible) {
      return;
    } else if(event.key === 'Escape') {
      this.optionsVisible = false;
      this.refs.mainInput.focus();
      return;
    } else if(event.key === 'Enter') {
      const option = this.refs.dropdownOptions?.querySelector('.highlighted.dropdown-option:not(.d-none)');
      option?.click();
      return;
    } else if(event.key === 'ArrowDown') {
      arrowDirection = 'down';
    } else if(event.key === 'ArrowUp') {
      arrowDirection = 'up';
    } else {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    const options = this.refs.dropdownOptions?.querySelectorAll('.dropdown-option:not(.d-none)');

    if(!options || options.length === 0) return;

    let highlightedOptionIndex = -1;
    for(let i = 0; i < options.length; i++) {
      if(options[i].classList.contains('highlighted')) {
        highlightedOptionIndex = i;
        break;
      }
    }

    if(highlightedOptionIndex == -1) {
      options[0].classList.add('highlighted');
    } else {
      options[highlightedOptionIndex].classList.remove('highlighted');
      if(arrowDirection === 'down') {
        highlightedOptionIndex = (highlightedOptionIndex + 1) >= options.length ? highlightedOptionIndex : (highlightedOptionIndex + 1);
      } else if(arrowDirection === 'up') {
        highlightedOptionIndex = (highlightedOptionIndex - 1) < 0 ? highlightedOptionIndex : (highlightedOptionIndex - 1);
      }
      options[highlightedOptionIndex].classList.add('highlighted');
      options[highlightedOptionIndex].scrollIntoView({ behavior: 'smooth', block: 'start', container: 'nearest' });
    }
  }

  emitValue() {
    const valueChangeEvent = new CustomEvent('valuechange', {
      detail: this.currentValue,
    });
    this.dispatchEvent(valueChangeEvent);
  }

  showOptions(e) {
    if(!this.optionsVisible) {
      this.optionsVisible = true;
      this.refs.searchInput.value = '';
      setTimeout(() => {
        this.refs.searchInput.focus();
      }, 0);


      this.refs.dropdownOptions.scrollTop = 0;
      this.handleSearch();
    } else {
      this.optionsVisible = false;
    }
  }

  handleOptionClick(event) {
    const selectedValue = event.target.getAttribute('data-value');
    this.currentValue = selectedValue;
    this.emitValue();
    this.optionsVisible = false;
  }

  handleSearch() {
    const searchTerm = this.refs.searchInput.value.toLowerCase().trim();
    const options = this.refs.dropdownOptions?.querySelectorAll('.dropdown-option');

    if(!options || options.length === 0) return;

    this.refs.dropdownOptions.scrollTop = 0;

    let firstOptionFound = false;
    options.forEach(option => {
      const label = option.getAttribute('data-value').toLowerCase();
      if(label.includes(searchTerm)) {
        option.classList.remove('d-none');
        if(!firstOptionFound) {
          option.classList.add('highlighted');
          firstOptionFound = true;
        } else {
          option.classList.remove('highlighted');
        }
      } else {
        option.classList.add('d-none');
      }
    });
  }
}