import { LightningElement, api } from "lwc";
import IMAGES from "@salesforce/resourceUrl/ecom_ss_static_files";
import { ecom_ss_ImageUrl, ecom_ss_PointerFollowAimation } from "c/ecom_ss_utils";

export default class Ecom_ss_threeColumnCards extends LightningElement {
  @api componentTitle;

  @api card1ImageUrl;
  @api card1ImageAlt;
  @api card1Title;
  @api card1Description;
  @api card1ButtonLabel;
  @api card1ButtonUrl;

  @api card2ImageUrl;
  @api card2ImageAlt;
  @api card2Title;
  @api card2Description;
  @api card2ButtonLabel;
  @api card2ButtonUrl;

  @api card3ImageUrl;
  @api card3ImageAlt;
  @api card3Title;
  @api card3Description;
  @api card3ButtonLabel;
  @api card3ButtonUrl;

  @api card4ImageUrl;
  @api card4ImageAlt;
  @api card4Title;
  @api card4Description;
  @api card4ButtonLabel;
  @api card4ButtonUrl;

  get cardData() {
    let finalData = [
      {
        imageUrl: ecom_ss_ImageUrl(this.card1ImageUrl),
        bgSvg: IMAGES + '/need-some-help-svg-1.svg',
        alt: this.card1ImageAlt,
        title: this.card1Title,
        description: this.card1Description,
        buttonLabel: this.card1ButtonLabel,
        showButton: this.card1ButtonLabel && this.card1ButtonUrl,
        buttonAttributes: { href: this.card1ButtonUrl },
        key: "help-card-key-1"
      },
      {
        imageUrl: ecom_ss_ImageUrl(this.card2ImageUrl),
        bgSvg: IMAGES + '/need-some-help-svg-2.svg',
        alt: this.card2ImageAlt,
        title: this.card2Title,
        description: this.card2Description,
        buttonLabel: this.card2ButtonLabel,
        showButton: this.card2ButtonLabel && this.card2ButtonUrl,
        buttonAttributes: { href: this.card2ButtonUrl },
        key: "help-card-key-2"
      },
      {
        imageUrl: ecom_ss_ImageUrl(this.card3ImageUrl),
        bgSvg: IMAGES + '/need-some-help-svg-3.svg',
        alt: this.card3ImageAlt,
        title: this.card3Title,
        description: this.card3Description,
        buttonLabel: this.card3ButtonLabel,
        showButton: this.card3ButtonLabel && this.card3ButtonUrl,
        buttonAttributes: { href: this.card3ButtonUrl },
        key: "help-card-key-3"
      }
    ];

    if(this.card4Title) {
      finalData.push({
        imageUrl: ecom_ss_ImageUrl(this.card4ImageUrl),
        bgSvg: IMAGES + '/need-some-help-svg-4.svg',
        alt: this.card4ImageAlt,
        title: this.card4Title,
        description: this.card4Description,
        buttonLabel: this.card4ButtonLabel,
        showButton: this.card4ButtonLabel && this.card4ButtonUrl,
        buttonAttributes: { href: this.card4ButtonUrl },
        key: "help-card-key-4"
      })
    }

    return {
      cardDetails: finalData,
      cardClass:
        finalData.length > 3
        ? 'slds-col slds-size_1-of-1 slds-large-size_6-of-12 ecom-ss-3-col-cards-card-col'
        : 'slds-col slds-size_1-of-1 slds-large-size_4-of-12 ecom-ss-3-col-cards-card-col'
    }
  }

  renderedCallback() {
    this.template
      .querySelectorAll('.ecom-ss-3-col-cards-card-col').forEach((card) => {
        ecom_ss_PointerFollowAimation(
          card.querySelector('.ecom-ss-3-col-cards-card-image-bg'),
          card,
          15,
          15
        );

        ecom_ss_PointerFollowAimation(
          card.querySelector('.ecom-ss-3-col-cards-card-image'),
          card,
          8,
          8,
          false
        );
      });
  }
}