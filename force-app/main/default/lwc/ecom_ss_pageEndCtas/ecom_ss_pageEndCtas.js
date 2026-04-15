import { LightningElement, api } from "lwc";
import { ecom_ss_ImageUrl } from "c/ecom_ss_utils";

export default class Ecom_ss_pageEndCtas extends LightningElement {
  @api componentTitle;
  @api componentSubTitle;
  @api cta1Label;
  @api cta1Icon;
  @api cta1Url;
  @api cta2Label;
  @api cta2Icon;
  @api cta2Url;

  get ctaData() {
    return [
      {
        label: this.cta1Label,
        attributes: { href: this.cta1Url },
        icon: ecom_ss_ImageUrl(this.cta1Icon),
        show: this.cta1Label && this.cta1Url,
        key: "page-end-cta-1"
      },
      {
        label: this.cta2Label,
        attributes: { href: this.cta2Url },
        icon: ecom_ss_ImageUrl(this.cta2Icon),
        show: this.cta2Label && this.cta2Url,
        key: "page-end-cta-2"
      }
    ];
  }
}