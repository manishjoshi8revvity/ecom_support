import { LightningElement, api } from "lwc";
import { ecom_ss_ImageUrl, ecom_ss_PointerFollowAimation } from "c/ecom_ss_utils";
import IMAGES from "@salesforce/resourceUrl/ecom_ss_static_files";

export default class Ecom_ss_twoColumnImageDescription extends LightningElement {
  @api imageUrl;
  @api imageAlt = "";
  @api componentTitle;
  @api componentDescription;
  @api buttonLabel;
  @api buttonUrl;

  bgSvgUrl = IMAGES + '/2-col-img-bg.svg';

  get finalImageUrl() {
    return ecom_ss_ImageUrl(this.imageUrl);
  }

  get showButton() {
    return this.buttonLabel && this.buttonUrl;
  }

  get buttonConfig() {
    return { href: this.buttonUrl };
  }

  renderedCallback() {
    ecom_ss_PointerFollowAimation(
      this.refs.rowElement.querySelector('.ecom-ss-2-col-img-desc-img-bg'),
      this.refs.rowElement,
      20,
      20
    );

    ecom_ss_PointerFollowAimation(
      this.refs.rowElement.querySelector('.ecom-ss-2-col-img-desc-img'),
      this.refs.rowElement,
      10,
      10,
      false
    );
  }
}