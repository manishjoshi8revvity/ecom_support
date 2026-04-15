import { LightningElement, api } from "lwc";

export default class Ecom_ss_heading extends LightningElement {
  @api headingText;
  @api headingElement;
  @api textAlign;
  @api textColor;
  @api fontSize;
  @api fontWeight;
  @api lineHeight;
  @api containerAround;

  get headingType() {
    return { [this.headingElement]: true };
  }

  get headingStyle() {
    return `
      text-align: ${this.textAlign};
      color: ${this.textColor};
      ${this.fontSize ? `font-size: ${this.fontSize}px;` : ""}
      ${this.fontWeight ? `font-weight: ${this.fontWeight};` : ""}
      ${this.lineHeight ? `line-height: ${this.lineHeight}px;` : ""}
    `;
  }

  get containerClass() {
    return this.containerAround ? "ecom-ss-boxed-container" : "";
  }
}