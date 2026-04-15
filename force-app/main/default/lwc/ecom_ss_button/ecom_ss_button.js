import { LightningElement, api } from "lwc";

export default class Ecom_ss_button extends LightningElement {
  @api label;
  @api icon;
  @api type = "primary"; // primary or secondary
  @api tag = "button"; // button, a, input or span
  @api attributes = {};
  @api iconAlt = "";//RWPS-4134
  @api handleClick = () => {};

  renderedCallback() {
    let button = document.createElement(this.tag);
    button.classList.add("slds-button");

    let outer = this.refs.ecomSsButton;
    let attributes = outer.getAttributeNames();

    let lwcKey;

    for (let i = 0; i < attributes.length; i++) {
      if (attributes[i].startsWith("lwc-")) {
        button.setAttribute(attributes[i], "");
        lwcKey = attributes[i];
        break;
      }
    }

    if (this.tag.toLowerCase() == "input") {
      button.value = this.label;
    } else {
      let btnText = document.createElement("span");
      btnText.innerHTML = this.label;
      btnText.setAttribute(lwcKey, "");

      let iconTag = "";
      if (this.icon) {
        iconTag = document.createElement("img");
        iconTag.src = this.icon;
        iconTag.alt = `${this.label} icon`; //RWPS-4134
        iconTag.setAttribute(lwcKey, "");
      }
      if (iconTag) {
        button.appendChild(iconTag);
      }
      button.appendChild(btnText);
    }
    button.classList.add("ecom-ss-button-" + this.type);
    button.addEventListener("click", this.handleClick);
    for (let key in this.attributes) {
      button.setAttribute(key, this.attributes[key]);
    }

    outer.innerHTML = "";
    outer.appendChild(button);
  }
}