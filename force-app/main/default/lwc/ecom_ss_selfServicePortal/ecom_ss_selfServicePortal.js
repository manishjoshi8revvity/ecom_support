import { LightningElement, api, track } from "lwc";
import IMAGES from "@salesforce/resourceUrl/ecom_ss_static_files";
import { ecom_ss_ImageUrl } from "c/ecom_ss_utils";
import { ecom_ss_GetDataFromSession } from "c/ecom_ss_utils";

// RWPS-3834 start
import ECOM_Self_Service_Order_Search_Title from '@salesforce/label/c.ECOM_Self_Service_Order_Search_Title';
import ECOM_Self_Service_Order_Search_TooltipText from '@salesforce/label/c.ECOM_Self_Service_Order_Search_TooltipText';
import ECOM_Self_Service_Order_Search_Tooltip_Image from '@salesforce/label/c.ECOM_Self_Service_Order_Search_Tooltip_Image';
import ECOM_Self_Service_Order_Search_Submit_Button_Text from '@salesforce/label/c.ECOM_Self_Service_Order_Search_Submit_Button_Text';
import ECOM_Self_Service_Order_Search_Order_Number_Input_Label from '@salesforce/label/c.ECOM_Self_Service_Order_Search_Order_Number_Input_Label';
import ECOM_Self_Service_Order_Search_PO_Or_Postal_Code_Input_Label from '@salesforce/label/c.ECOM_Self_Service_Order_Search_PO_Or_Postal_Code_Input_Label';
// RWPS-3834 end

export default class Ecom_ss_self_service_portal extends LightningElement {
  // RWPS-3834 start
  _displayTitle;
  @api get displayTitle() {
    return this._displayTitle || ECOM_Self_Service_Order_Search_Title;
  }
  set displayTitle(value) {
    this._displayTitle = value;
  }
  #escapeKeyCallback; // RWPS-4134

  _tooltipText;
  @api get tooltipText() {
    return this._tooltipText || ECOM_Self_Service_Order_Search_TooltipText;
  }
  set tooltipText(value) {
    this._tooltipText = value;
  }

  _tooltipImage;
  @api get tooltipImage() {
    return this._tooltipImage || ECOM_Self_Service_Order_Search_Tooltip_Image;
  }
  set tooltipImage(value) {
    this._tooltipImage = value;
  }

  _submitButtonText;
  @api get submitButtonText() {
    return this._submitButtonText || ECOM_Self_Service_Order_Search_Submit_Button_Text;
  }
  set submitButtonText(value) {
    this._submitButtonText = value;
  }

  get orderNumberInputLabel() {
    return ECOM_Self_Service_Order_Search_Order_Number_Input_Label;
  }

  get poNumberOrPostalCodeInputLabel() {
    return ECOM_Self_Service_Order_Search_PO_Or_Postal_Code_Input_Label;
  }
  // RWPS-3834 end

  formAction = (location.pathname.includes('/selfservice') ? '/selfservice' : '') + '/track-order';

  userName = "";
  get showSecondInput() {
    if (this.userName) {
      return false;
    }
    return true;
  }

  get helpImageUrl() {
    return ecom_ss_ImageUrl(this.tooltipImage);
  }

  helpIconUrl = IMAGES + "/track-order-help-icon.svg";

  @track helpSectionStyle = "display: none;";
  showHelpSection() {
    this.helpSectionStyle = "display: block;";
  }

  hideHelpSection() {
    this.helpSectionStyle = "display: none;";
  }
   /*RWPS-4134 start*/
  escapeKeyCallback(event) {
    if (event.key === 'Escape' || event.keyCode === 27) {
        this.hideHelpSection();
    }
  }/*RWPS-4134 end*/

  @track submitButtonAttributes = {
    type: "submit"
  };

  connectedCallback() {
    // RWPS-4134 start
    this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
    document.addEventListener('keydown', this.#escapeKeyCallback);
    // RWPS-4134 end
    ecom_ss_GetDataFromSession().then((data) => {
      if (data.success) {
        this.userName = data.name;
      }
    }).catch(() => {});
  }
  /*RWPS-4134 start*/
  disconnectedCallback() {
    if (this.#escapeKeyCallback) {
      document.removeEventListener('keydown', this.#escapeKeyCallback);
    }
  }/*RWPS-4134 end*/
}