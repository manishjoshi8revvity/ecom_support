import { LightningElement, api, track } from "lwc";

export default class Ecom_ss_footer extends LightningElement {
  @api link1Text;
  @api link1Url;
  @api link2Text;
  @api link2Url;
  @api link3Text;
  @api link3Url;
  @api copyrightText;

  year = new Date().getFullYear();

  get _copyrighttext () {
    return this.copyrightText.replace('{year}', year);
  }

  @track links = [];

  connectedCallback() {
    for (let i = 1; i <= 3; i++) {
      if(this[`link${i}Text`] && this[`link${i}Url`]) {
        this.links.push({
          key: `footerLink${i}`,
          text: this[`link${i}Text`],
          url: this[`link${i}Url`]
        })
      }
    }
  }
}