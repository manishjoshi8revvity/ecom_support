import { api, LightningElement } from "lwc";

export default class Ecom_punchoutAnalyzerMultiSelectInput extends LightningElement {
  @api defaultValue;
  @api options;
  @api label;

  @api resetToDefault() {
    this.checkAll();
    this.refs.searchInput.value = "";
    this.handleSearchInput();
  }

  currentValue;
  allChecked;
  selectedOptionsCount;
  optionsVisible = false;
  componentClicked = false;

  labelFocussedClass = "option-label-focussed";

  get optionsCount() {
    return this.options.length;
  }

  #handleOutsideClick;
  handleOutsideClick() {
    if (!this.componentClicked && this.optionsVisible) {
      this.closeOptions();
    }
    this.componentClicked = false;
  }

  #handleKeyDown;
  handleKeyDown(event) {
    if (!this.optionsVisible) {
      return;
    }

    if (event.key === "Escape") {
      this.closeOptions();
      return;
    }

    if (event.key == "ArrowUp" || event.key == "ArrowDown") {
      let focussedPosition = -1;

      let options = this.template.querySelectorAll(".option-label");
      for (let i = 0; i < options.length; i++) {
        if (options[i].classList.contains(this.labelFocussedClass)) {
          focussedPosition = i;
          options[i].classList.remove(this.labelFocussedClass);
          break;
        }
      }

      if (focussedPosition === -1) {
        focussedPosition = 0;
      } else if (event.key == "ArrowUp") {
        focussedPosition--;
      } else {
        focussedPosition++;
      }

      options[
        Math.max(0, Math.min(this.optionsCount - 1, focussedPosition))
      ]?.classList.add(this.labelFocussedClass);

      return;
    }

    if (event.key === "Enter") {
      let focussedOption = this.template.querySelector(
        "." + this.labelFocussedClass
      );
      focussedOption?.click();
      return;
    }
  }

  connectedCallback() {
    this.currentValue = this.defaultValue;
    this.allChecked = true;
    this.selectedOptionsCount = this.optionsCount;

    this.#handleOutsideClick = this.handleOutsideClick.bind(this);
    document.addEventListener("click", this.#handleOutsideClick);

    this.#handleKeyDown = this.handleKeyDown.bind(this);
    document.addEventListener("keydown", this.#handleKeyDown);
  }

  disconnectedCallback() {
    document.removeEventListener("click", this.#handleOutsideClick);
    document.removeEventListener("keydown", this.#handleKeyDown);
  }

  handleComponentClick() {
    if (this.optionsVisible) {
      this.componentClicked = true;
      this.refs.searchInput.focus();
    }
  }

  toggleOptions() {
    if (this.optionsVisible) {
      this.closeOptions();
    } else {
      this.openOptions();
    }
  }

  openOptions() {
    this.optionsVisible = true;

    let checkedCount = this.template.querySelectorAll(
      ".option-label input:checked"
    );
    if (checkedCount.length === 0) {
      this.checkAll(true);
    }

    this.refs.searchInput.value = "";
    this.handleSearchInput();

    this.template
      .querySelector(".option-label")
      ?.classList.add(this.labelFocussedClass);

    setTimeout(() => {
      this.refs.searchInput.focus();
    }, 1);
  }

  closeOptions() {
    this.optionsVisible = false;
    this.refs.mainInput.focus();

    this.template
      .querySelector("." + this.labelFocussedClass)
      ?.classList.remove(this.labelFocussedClass);
  }

  checkAll(includeHidden = false) {
    this.template
      .querySelectorAll(
        `.option-label${includeHidden ? "" : ":not(.d-none)"} input`
      )
      .forEach((input) => {
        input.checked = true;
      });
  }

  handleAllCheckedChange(e) {
    this.allChecked = e.target.checked;

    if (this.allChecked) {
      this.checkAll();
    } else {
      this.template.querySelectorAll(".option-label input").forEach((input) => {
        input.checked = false;
      });
    }

    this.recalculateValue();
  }

  recalculateAllChecked() {
    if (
      this.template.querySelectorAll(".option-label:not(.d-none) input:checked")
        .length ===
      this.template.querySelectorAll(".option-label:not(.d-none)").length
    ) {
      this.allChecked = true;
    } else {
      this.allChecked = false;
    }
  }

  recalculateValue() {
    let selectedOptions = this.template.querySelectorAll(
      ".option-label input:checked"
    );
    let selectedValues = [];
    selectedOptions.forEach((option) => {
      selectedValues.push(option.dataset.value);
    });

    this.selectedOptionsCount = selectedOptions.length;

    if (
      selectedOptions.length === this.optionsCount ||
      selectedOptions.length === 0
    ) {
      this.currentValue = this.defaultValue;

      this.dispatchEvent(
        new CustomEvent("valuechange", {
          detail: []
        })
      );
    } else {
      this.currentValue =
        selectedOptions.length + "/" + this.optionsCount + " selected";

      this.dispatchEvent(
        new CustomEvent("valuechange", {
          detail: selectedValues
        })
      );
    }

    this.recalculateAllChecked();
  }

  handleSearchInput() {
    let searchValue = this.refs.searchInput.value.trim().toLowerCase();

    let options = this.template.querySelectorAll(".option-label");
    options.forEach((option) => {
      if (option.dataset.value.toLowerCase().includes(searchValue)) {
        option.classList.remove("d-none");
      } else {
        option.classList.add("d-none");
      }
    });

    this.recalculateValue();
  }

  handleMainKeyDown(e) {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      this.toggleOptions();
      return;
    }
  }
}