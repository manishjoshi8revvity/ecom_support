import { LightningElement, track, wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import SPECIAL_INSTRUCTIONS_FIELD from '@salesforce/schema/Contact.ECOM_Special_Instructions__c';
import COUNTRY_PHONE_CODE_FIELD from '@salesforce/schema/Contact.ECOM_Country_Phone_Code__c';

import Ecom_Profile_Settings  from '@salesforce/label/c.Ecom_Profile_Settings';
import Ecom_Profile_Information  from '@salesforce/label/c.Ecom_Profile_Information';
import Ecom_First_Name  from '@salesforce/label/c.Ecom_First_Name';
import Ecom_Last_Name  from '@salesforce/label/c.Ecom_Last_Name';
import Ecom_Email_Address_Password  from '@salesforce/label/c.Ecom_Email_Address_Password';
import Ecom_Email_Message  from '@salesforce/label/c.Ecom_Email_Message';
import ECOM_EmailAddress  from '@salesforce/label/c.ECOM_EmailAddress';
import Ecom_Password  from '@salesforce/label/c.Ecom_Password';
import Ecom_Contact_Information  from '@salesforce/label/c.Ecom_Contact_Information';
import Ecom_Change  from '@salesforce/label/c.Ecom_Change';
import Ecom_Phone_Number  from '@salesforce/label/c.Ecom_Phone_Number';
import Ecom_Shipping_Information  from '@salesforce/label/c.Ecom_Shipping_Information';
import Ecom_Email_Associated_Message  from '@salesforce/label/c.Ecom_Email_Associated_Message';
import ECOM_OrderConfirmation  from '@salesforce/label/c.ECOM_OrderConfirmation';
import ECOM_ShipmentNotification  from '@salesforce/label/c.ECOM_ShipmentNotification';
import ECOM_AdditionalEmailMessage  from '@salesforce/label/c.ECOM_AdditionalEmailMessage';
import Ecom_Add_Email  from '@salesforce/label/c.Ecom_Add_Email';
import Ecom_Save_Changes  from '@salesforce/label/c.Ecom_Save_Changes';
import Ecom_Cancel_close  from '@salesforce/label/c.Ecom_Cancel_close';
import Ecom_Change_Password  from '@salesforce/label/c.Ecom_Change_Password';
import Ecom_Show_Password  from '@salesforce/label/c.Ecom_Show_Password';
import Ecom_Hide_Password  from '@salesforce/label/c.Ecom_Hide_Password';
import Ecom_Password_Strength  from '@salesforce/label/c.Ecom_Password_Strength';
import Ecom_Password_Blank  from '@salesforce/label/c.Ecom_Password_Blank';
import Ecom_Confirm_Password  from '@salesforce/label/c.Ecom_Confirm_Password';
import Ecom_Password_Match  from '@salesforce/label/c.Ecom_Password_Match';
import ECOM_Save  from '@salesforce/label/c.ECOM_Save';
import ECOM_Cancel  from '@salesforce/label/c.ECOM_Cancel';
import ECOM_Country  from '@salesforce/label/c.ECOM_Country';
import ECOM_Phone_Number_Pattern  from '@salesforce/label/c.ECOM_Phone_Number_Pattern';
import Ecom_Phone_Number_Blank  from '@salesforce/label/c.Ecom_Phone_Number_Blank';
import ECOM_Addition_Shipping_Info  from '@salesforce/label/c.ECOM_Addition_Shipping_Info';
import ECOM_Changes_Submitted  from '@salesforce/label/c.ECOM_Changes_Submitted';
import ECOM_Ok  from '@salesforce/label/c.ECOM_Ok';
import ECOM_EmailNotifications  from '@salesforce/label/c.ECOM_EmailNotifications';



import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import getUser from '@salesforce/apex/ECOM_UserController.getUser';
import updateUser from '@salesforce/apex/ECOM_UserController.updateUser';
import updateContact from '@salesforce/apex/ECOM_ContactController.saveContact';
import updateUserPassword from '@salesforce/apex/ECOM_UserController.updateUserPassword';
import getEmailPreferences from '@salesforce/apex/ECOM_AccountsController.getEmailPreferences';
import upsertEmailPreferences from '@salesforce/apex/ECOM_AccountsController.upsertEmailPreferences';
import deleteEmailPreferences from '@salesforce/apex/ECOM_AccountsController.deleteEmailPreferences';
import ECOM_EmailInvalidErrorMessage  from '@salesforce/label/c.ECOM_EmailInvalidErrorMessage';//RWPS-2722
//RWPS-3306 start
import ECOM_Type  from '@salesforce/label/c.ECOM_Type';
import ECOM_Action  from '@salesforce/label/c.ECOM_Action';
import ECOM_Cart_Reminder_Email  from '@salesforce/label/c.ECOM_Cart_Reminder_Email';
import ECOM_Transactional_Email  from '@salesforce/label/c.ECOM_Transactional_Email';
import ECOM_Order_Shipment_Notifications  from '@salesforce/label/c.ECOM_Order_Shipment_Notifications';
import ECOM_Email_Notification_Description  from '@salesforce/label/c.ECOM_Email_Notification_Description';
//RWPS-3306 end
import recipientTitle from '@salesforce/label/c.ecom_Attention_Recipient_Title';//RWPS-4824

import { sendPostMessage } from 'c/ecom_util';
const CONTAINER_HTML_BLANK  = `<div></div>`;
const CONTAINER_HTML = `<div class="slds-grid slds-wrap " >
                    <div class="slds-col slds-size_5-of-12 slds-large-size_5-of-12  ecom-center">&nbsp;</div>
                    <div class="slds-col slds-size_5-of-12 slds-large-size_5-of-12  ecom-center">
                        <p class="slds-form-element__help ecom-red-text" data-help-message role="alert" part="help-text" >Please choose at least one option.</p>
                    </div>
                    <div class="slds-col slds-size_3-of-12">&nbsp;</div>
                </div>`;
const CONTAINER_HTML_SMALL = `<div class="slds-col slds-size_1-of-1 slds-small-size_1-of-1"><p class="slds-form-element__help ecom-red-text" data-help-message role="alert" part="help-text" >Please choose at least one option.</p></div>`

export default class Ecom_profileAndSettings extends LightningElement {

    labels = {
        Ecom_Profile_Settings,
        Ecom_Profile_Information,
        Ecom_First_Name,
        Ecom_Last_Name,
        Ecom_Email_Address_Password,
        Ecom_Email_Message,
        ECOM_EmailAddress,
        Ecom_Password,
        Ecom_Change,
        Ecom_Contact_Information,
        Ecom_Phone_Number,
        Ecom_Shipping_Information,
        Ecom_Email_Associated_Message,
        ECOM_OrderConfirmation,
        ECOM_ShipmentNotification,
        ECOM_AdditionalEmailMessage,
        Ecom_Add_Email,
        Ecom_Save_Changes,
        Ecom_Cancel_close,
        Ecom_Change_Password,
        Ecom_Show_Password,
        Ecom_Hide_Password,
        Ecom_Password_Strength,
        Ecom_Password_Blank,
        Ecom_Confirm_Password,
        Ecom_Password_Match,
        ECOM_Cancel,
        ECOM_Save,
        ECOM_Country,
        ECOM_Phone_Number_Pattern,
        Ecom_Phone_Number_Blank,
        ECOM_Addition_Shipping_Info,
        ECOM_Changes_Submitted,
        ECOM_Ok,
        ECOM_EmailNotifications,
        ECOM_EmailInvalidErrorMessage,//RWPS-2722
        ECOM_Type,//RWPS-3306 start
        ECOM_Action,
        ECOM_Cart_Reminder_Email,
        ECOM_Transactional_Email,
        ECOM_Order_Shipment_Notifications,
        ECOM_Email_Notification_Description,//RWPS-3306 end
        recipientTitle//RWPS-4824
    }

   /* New changes starts*/
   loggedinUser;
   copyLoggedinUser;
   contactData;
   copyContactData=[];
   isUserNameChanged = false;
   isChangePasswordModalOpen = false;
   newPassword = '';
   newPassword2 = '';
   pwrdStrength = 'Weak';
   showPasswordSaveButton = false;
   isPassMasked = true;
   isPassMasked2 = true;
   isPass1Blank = false;
   isPass2Blank = false;
   isPassMatch = true;
   countryPhoneCode = [];
   showSpinner = false;
   messageType="success";
   message='';
   timeSpan=3000;
   showMessage = false;
   changesDetected = false;
   emailDeleted = false;  // RWPS-2562 added flag  to delete email correctly
   sidebarCSS='';
   middleSpaceCSS = '';
   mainSectionCSS = '';
   //RWPS-3306 start
   isOptOutCartEmailChanged = false;
   hasScrolledToEmail = false;
   hasInitializedScrollObserver = false;
   scrollTimer;
   //RWPS-3306 end
   hasFocusedModal = false;//RWPS-3764
   // Add properties for cart reminder email logic
   @track loggedInUserEmail;
   @track isCartReminder = true
   @track emailDataWithoutErpAddress = null;
   @track bodyScroll = 'body slds-align_absolute-center slds-p-right_medium';//RWPS-3764
   #escapeKeyCallback; // RWPS-4087


   device = {
        isMobile : FORM_FACTOR ==='Small',
        isDesktop : FORM_FACTOR ==='Large',
        isTablet : FORM_FACTOR ==='Medium'
    }

    @track
    images = {
        deleteblack: ssrc_ECOM_Theme + '/img/deleteblack.png',
        blackdelete: sres_ECOM_CartIcons + '/img/deleteblack.png',
        purpledelete: sres_ECOM_CartIcons + '/img/delete-icon-purple.svg',
        qodelete:sres_ECOM_CartIcons + '/img/qo-delete.png',
    }
    @track isEmailInvalid = false;//RWPS-2722
    @track emailValue = '';//RWPS-2722
    lastFocusedElement;//RWPS-4087
    originalTriggerElement;//RWPS-4153
    //RWPS-2722 Start
    get firstNameLabel() {
        return `${this.labels.Ecom_First_Name} *`;
    }
    get lastNameLabel() {
        return `${this.labels.Ecom_Last_Name} *`;
    }
    //RWPS-2722 end
    connectedCallback() {
        this.loadBasedOnDeviceType();
        window.addEventListener('resize', this.handleResize.bind(this));//RWPS-3306
        this.getLoggedinUserInfo();
        // RWPS-4087 start
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);
        // RWPS-4087 end

    }

    renderedCallback() {
        if (this.hasInitializedScrollObserver) return;
        this.hasInitializedScrollObserver = true;

        const shouldScrollToEmail = window.location.hash === '#email-notifications';
        const scrollTarget = sessionStorage.getItem('scrollTarget');

        // Only set up observer if we need to scroll
        if (!shouldScrollToEmail && !scrollTarget) {
            window.scrollTo({ top: 0, behavior: 'smooth' });
            return;
        }

        // Setup observer to handle both direct hash and sessionStorage cases
        const observer = new MutationObserver(() => {
            clearTimeout(this.scrollTimer);
            this.scrollTimer = setTimeout(() => {
                const emailSection = this.template.querySelector('[data-id="email-notification"]');
                if (emailSection) {
                    emailSection.scrollIntoView({ behavior: "smooth", block: "end" });
                    if (scrollTarget) {
                        sessionStorage.removeItem('scrollTarget');
                    }
                    window.history.replaceState(null, '', window.location.pathname + window.location.search);
                    observer.disconnect();
                }
            }, 800);
        });

        observer.observe(this.template, { childList: true, subtree: true });
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.handleResize.bind(this));
        //RWPS-4087 start
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
    
            if (this.isChangePasswordModalOpen) {
                this.changePasswordHandleClose();
            }
    
            if (this.isChangePhoneModalOpen) {
                this.onPhoneModalClose();
            }
    
            if (this.isChangedSubmittedModalOpen) {
                this.onChangesSubmittedModalClose();
            }
            if (this.isChangeEmailNotiModalOpen) {
                this.onEmailNotiModalClose();
            }
            if (this.isChangeShippingModalOpen) {
                this.onShippingModalClose();
            }
            //RWPS-4473 Start
            if (this.isNoChangesModalOpen) {
                this.onNoChangesModalClose(); // ← This closes the popup
            }
            //RWPS-4473 End
            if (this.showErrorModal) {
                this.onCloseErrorModal();
            }
        }
    }
    
    // RWPS-4087 end

    handleResize() {
        const width = window.innerWidth;
        this.isSmallScreen = width <= 768;
    }//RWPS-3306 end
    loadBasedOnDeviceType() {
        //RWPS-3306 start
        const width = window.innerWidth || screen.width;
        const isTablet = FORM_FACTOR === 'Medium' || width <= 1025;
        const isMobile = width <= 768;

        if (isTablet) {
            this.sidebarCSS = 'slds-size_12-of-12';
            this.middleSpaceCSS = 'slds-hide';
            this.mainSectionCSS = 'slds-size_12-of-12';
        } else {
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12';
            this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-medium-size_1-of-12';
            this.mainSectionCSS = 'slds-size_12-of-12 slds-large-size_8-of-12 slds-medium-size_8-of-12';
        }

        this.isSmallScreen = isMobile;
        this.modalSize = isMobile
            ? "slds-modal slds-fade-in-open slds-modal_full"
            : "slds-modal slds-fade-in-open";
            //RWPS-3306 end
    }

    getLoggedinUserInfo(){
        getUser()
        .then(result=>{
            if(result.Success) {
                let contactId=result?.User?.ContactId;
                this.loggedinUser = result?.User;
                this.copyLoggedinUser =  result?.User;
                this.contactData =  result?.User.Contact;
                this.loggedInUserEmail =this.contactData.Email;//RWPS-3306
                // Copy for HTML To not be updated in real time per QA - row 61
                this.copyContactData = this.loggedinUser.Contact;
                this.contactData = JSON.parse(JSON.stringify(this.copyContactData));
                this.copyContactData = JSON.parse(JSON.stringify(this.copyContactData));
                this.copyContactData.ECOM_Attention_Recipient__c = this.copyContactData?.ECOM_Attention_Recipient__c || '';
                this.contactData.ECOM_Attention_Recipient__c = this.contactData?.ECOM_Attention_Recipient__c || '',
                this.shippingSpecialInstruction = this.contactData?.ECOM_Special_Instructions__c || '';
                this.getEmailPref();
            }
        }).catch(error=>{
            console.log('error in user info: '+JSON.stringify(error));
        });
    }
    handleUserNameChange(event) {
        //RWPS-2722 start
        const fieldId = event.target.dataset.id;
        const value = event.target.value?.trim();
        // Validate required field
        if (!value) {
            event.target.setCustomValidity('Complete this field');
        } else {
            event.target.setCustomValidity('');
        }
        event.target.reportValidity();

        // Update First Name
        if (fieldId === 'fName-Id') {
            this.loggedinUser = { ...this.loggedinUser, FirstName: value };
            this.contactData = { ...this.contactData, FirstName: value };
            this.isUserNameChanged = true;
            this.contactInfoNeedUpdate = true;
            this.changesDetected = true;
        }

        // Update Last Name
        if (fieldId === 'lName-Id') {
            this.loggedinUser = { ...this.loggedinUser, LastName: value };
            this.contactData = { ...this.contactData, LastName: value };
            this.isUserNameChanged = true;
            this.contactInfoNeedUpdate = true;
            this.changesDetected = true;
        }//RWPS-2722 end
    }

    // PASSWORD CHANGE
    changePasswordModalOpen(){
        this.isChangePasswordModalOpen = true;
        this.openModal('password');//RWPS-3764
        sendPostMessage('hidden');
    }

    changePasswordHandleClose(){
        this.isChangePasswordModalOpen = false;
        this.changePasswordHandleCancel();
        this.closeModal('password'); //RWPS-3764 
        sendPostMessage('auto');
    }

    changePasswordHandleCancel(){
        this.newPassword = '';
        this.newPassword2 = '';
        this.isPassMasked = true;
        this.isPassMasked2 = true;
        this.clearPasswordStatus();
        this.isChangePasswordModalOpen = false;
        this.isPassMatch = true;
        sendPostMessage('auto');
        //RWPS-4153 Start
        if (this.lastFocusedElement) {
            this.lastFocusedElement.focus();
            this.lastFocusedElement = null;
        }//RWPS-4153 End
    }
    clearPasswordStatus(){
        this.weak = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_error rounded ecom-password-h-8px slds-m-right_xx-small';
        this.average = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_warning rounded ecom-password-h-8px slds-m-right_xx-small';
        this.strong = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_success rounded ecom-password-h-8px slds-m-right_xx-small';
        this.pwrdStrength == 'Weak'
    }
     changePasswordHandleSave(){
        this.showMessage = false;
            this.updatePassword();
            this.changePasswordHandleClose();
            this.onChangesSubmittedModalOpen();
            this.showPasswordSaveButton = false;
            this.clearPasswordStatus(); 

    }
      // For Password Strength Modal
      weak = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_error rounded ecom-password-h-8px slds-m-right_xx-small';
      average = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_warning rounded ecom-password-h-8px slds-m-right_xx-small';
      strong = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_success rounded ecom-password-h-8px slds-m-right_xx-small';

      // Check for Password Strength
      checkStrength(input_string){
          const n = input_string.length;
          let hasLower = false;
          let hasUpper = false;
          let hasDigit = false;
          let specialChar = false;
          const normalChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ";

          for (let i = 0; i < n; i++) {
              if (input_string[i] >= "a" && input_string[i] <= "z") {
                hasLower = true;
              }
            //   if (input_string[i] >= "A" && input_string[i] <= "Z") {
            //      hasUpper = true;
            //  }
              if (input_string[i] >= "0" && input_string[i] >= "9") {
              hasDigit = true;
              }
              if (!normalChars.includes(input_string[i])) {
                specialChar = true;
              }
          }

          // Strength of password
          let strength = "Weak";
          if(strength === "Weak"){
              this.weak='ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_error rounded ecom-password-h-8px slds-m-right_xx-small active';
              this.average = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_warning rounded ecom-password-h-8px slds-m-right_xx-small';
              this.strong = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_success rounded ecom-password-h-8px slds-m-right_xx-small';
          }
          if (hasLower  && specialChar && n >=6) {
              strength = "Average";
              this.weak='ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_error rounded ecom-password-h-8px slds-m-right_xx-small active';
              this.average='ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_warning rounded h-8px slds-m-right_xx-small active';
              this.strong = 'ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_success rounded ecom-password-h-8px slds-m-right_xx-small';
          }
          if (hasLower  && hasDigit && specialChar  && n >= 12) {
              strength = "Strong";
              this.weak='ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_error rounded ecom-password-h-8px slds-m-right_xx-small active';
              this.average='ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_warning rounded h-8px slds-m-right_xx-small active';
              this.strong='ecom-password-flex-grow-1 ecom-password-bg-base ecom-password-slds-alert_success rounded ecom-password-h-8px slds-m-right_xx-small active';
              //this.pwrdStrength = strength;
          }
          this.pwrdStrength = strength;
      } // end of check Strength

      //RWPS-2722 start
      handleBlur(event) {
        const value = event.target.value?.trim();

        if (!value) {
            event.target.setCustomValidity('Complete this field');
        } else {
            event.target.setCustomValidity('');
        }

        event.target.reportValidity();
     }

     validateRequiredFields() {
        const inputs = this.template.querySelectorAll('lightning-input');
        let allValid = true;

        inputs.forEach(input => {
            if (input.type === 'text') {
                if (!input.value?.trim()) {
                    input.setCustomValidity('Complete this field');
                    input.reportValidity();
                    allValid = false;
            } else {
                input.setCustomValidity('');
                input.reportValidity();
            }
        }
        });
        return allValid;
    }//RWPS-2722 end
    //RWPS-3306 start
    async handleSaveChanges(){
        this.showMessage = false;
        this.message = '';
        this.messageType = '';
        this.showSpinner = true;

        const isValid = this.validateRequiredFields();
        if (!isValid) {
            this.handleScrollToTop();
            this.showSpinner = false;
            return;
        }

        if(this.emailcheckboxError === true){
            this.showErrorModal = true;
            this.emailDataChange = false;
            this.showSpinner = false;
            return;
        }

        const hasChanges =
            this.isUserNameChanged ||
            this.contactInfoNeedUpdate ||
            this.emailDataChange ||
            this.deleteEmailList.length > 0 ||
            this.isOptOutCartEmailChanged ||
            (this.newEmailAddressRows && this.newEmailAddressRows.length > 0);

        if (!hasChanges) {
            this.isNoChangesModalOpen = true;
            this.showSpinner = false;
            return;
        }

        let savePromises = [];

        if (this.isUserNameChanged) {
            savePromises.push(
                updateUser({ updatedUserData: this.loggedinUser })
                    .then(() => {
                        this.isUserNameChanged = false;
                    })
                    .catch((error) => {

                    })
            );
        }

        if (this.contactInfoNeedUpdate || this.isUserNameChanged) {
            savePromises.push(
                updateContact({ con: this.contactData })
                    .then(() => {
                        this.copyContactData = { ...this.contactData };
                        this.contactInfoNeedUpdate = false;
                    })
                    .catch((error) => {
                    })
            );
        }

        if ((this.emailDataChange || this.isOptOutCartEmailChanged) && !this.isEmailCheckboxBlank) {
            let optInRecords=JSON.parse(JSON.stringify(this.emailDataWithoutErpAddress));

            let savedEmailData = [];

            if (optInRecords && optInRecords.length > 0) {
                optInRecords.forEach(record => {
                    const selectedRecord = this.emailData.find(existing =>
                        existing.Id === record.Id &&
                        existing.ECOM_Email__c === record.ECOM_Email__c
                    );

                    if (selectedRecord) {
                        selectedRecord.Ecom_Opt_Out_from_Cart_Emails__c = record.Ecom_Opt_Out_from_Cart_Emails__c;
                        this.emailData = [...this.emailData];
                    } else {
                        if (!record.ERP_Address__c || record.ERP_Address__c.trim() === '') {
                            record.ERP_Address__c = ' ';
                        }
                        savedEmailData.push(record);
                    }
                });
            }

            savedEmailData = [...this.emailData, ...savedEmailData]; //RWPS-5402, RWPS-6920
            savePromises.push(
                upsertEmailPreferences({ changesList: JSON.stringify(savedEmailData) })
                    .then(() => {
                        this.emailDataChange = false;
                        this.isOptOutCartEmailChanged = false;
                        this.isEmailCheckboxBlank = false;
                        this.getEmailPref();
                    })
                    .catch((error) => {
                    })
            );
        }

        if(this.deleteEmailList.length > 0){
            savePromises.push(
                deleteEmailPreferences({deleteList: JSON.stringify(this.deleteEmailList)})
                    .then(() => {
                        this.emailDeleted = false;
                        this.deleteEmailList = [];
                    })
                    .catch((error) => {
                    })
            );
        }

        try {
            await Promise.all(savePromises);

            if (!this.isNoChangesModalOpen) {
                this.showMessage = true;
                this.message = 'Changes saved successfully.';
                this.messageType = 'success';
                this.handleScrollToTop();
            }
        } catch (error) {
            console.error('Overall save operation failed:', error.message);
            this.showMessage = true;
            this.message = 'An error occurred while saving changes: ' + error.message;
            this.messageType = 'error';
            this.handleScrollToTop();
        } finally {
            this.showSpinner = false;
            this.resetChangeFlags();
            this.checkForChanges();
        }
    }
    resetChangeFlags() {
        this.isUserNameChanged = false;
        this.contactInfoNeedUpdate = false;
        this.emailDataChange = false;
        this.isOptOutCartEmailChanged = false;
        this.deleteEmailList = [];
        this.newEmailAddressRows = [];
        this.isNoChangesModalOpen = false;
        this.emailcheckboxError = false;
        this.emailDeleted = false;
        this.isEmailCheckboxBlank = false;
        this.changesDetected = false;
    }
//RWPS-3306 END
    handleMessageCloseAction(){
        this.showMessage = false;

    }
    
     // CONTACT PHONE
     onPhoneModalOpen(){
        this.isChangePhoneModalOpen = true;
        this.openModal('phone');//RWPS-3764
        sendPostMessage('hidden');
    }

    onPhoneModalClose(){
        this.isChangePhoneModalOpen = false;
        this.showPhoneSaveButton = false;
        this.closeModal('phone');//RWPS-3764
        sendPostMessage('auto');
    }

    // Get the Contact Record Type
    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactObjInfo({ error, data }) {
        if (data) {
            this.contactRecTypeId = data.defaultRecordTypeId ? data.defaultRecordTypeId : '';
        } else if (error) {
        }
    }

    // Get Picklist Values for Special Instructions
    @wire(getPicklistValues, { recordTypeId: '$contactRecTypeId', fieldApiName: SPECIAL_INSTRUCTIONS_FIELD })
    spInstructionsPicklistValues({ error, data }) {
        if (data) {
            this.spInstructionsPicklist.push({label: '--None--', value: ''});
            for(var i=0;i<data.values.length;i++){
                this.spInstructionsPicklist.push({"label" : data.values[i].label, "value" : data.values[i].value});
            }
        } else if (error) {
        }
    }

    // Get Picklist Values for Country Phone Code
    @wire(getPicklistValues, { recordTypeId: '$contactRecTypeId', fieldApiName: COUNTRY_PHONE_CODE_FIELD })
    countryCodePicklistValues({ error, data }) {
        if (data) {
            this.countryPhoneCode = data.values;
        } else if (error) {
        }
    }


    onContactChange(event){
        //RWPS-2917 start
        const nextFocusedElement = event.relatedTarget;
        // If the next element clicked is the cancel button, skip everything
        if (nextFocusedElement?.classList?.contains('ecom_btn-password-cancel')) {
            this.showPhoneSaveButton = false;
            return;
        } //RWPS-2917 end
        let phoneMatchPattern = false;
        let countryCodeValid = false;
        let changeInPhoneExt = false;
        this.isPhoneBlank = false;

        if(event.target.dataset.id === 'newPhone-Id' ){
            if(event.target.value === null || event.target.value === ''){
                this.isPhoneBlank = true;
                this.showPhoneSaveButton = false;
            }
        }
        if(event.target.dataset.id === 'phoneExt-Id' ){
            // this.contactData = {...this.contactData, ECOM_Phone_Extension__c: event.target.value};
            // this.loggedinUser = {...this.loggedinUser, ECOM_Phone_Extension__c: event.target.value};
            this.contactData = {...this.contactData, ECOM_Phone_Extension__c: this.refs.phoneExtId.value};
            this.loggedinUser = {...this.loggedinUser, ECOM_Phone_Extension__c: this.refs.phoneExtId.value};
            this.contactPhoneUpdate = true;
            changeInPhoneExt = true;
        }else {
            changeInPhoneExt = false;
        }

        if(event.target.dataset.id === 'country-phone-code-id' ){
            this.contactData = {...this.contactData, ECOM_Country_Phone_Code__c: event.target.value};
            this.loggedinUser = {...this.loggedinUser, ECOM_Country_Phone_Code__c: event.target.value};
            this.contactPhoneUpdate = true;
        }

        // Validate fields to show Save Button
        //let checkPhone = this.template.querySelector('[data-id="newPhone-Id"]').value;
        let checkPhone = this.refs?.newPhoneId?.value || '';//RWPS-3306

        console.log('checkPhone:: ', checkPhone);//Remove after DEV
        console.log('checkPhone:: ', this.contactData);//Remove after DEV
        console.log('checkPhone:: ', this.userData);//Remove after DEV
        // If the Phone Ext has changed, it is captured above
        if(checkPhone !== null || checkPhone !== '' || checkPhone !==undefined  || (this.contactData && this.contactData?.Phone && checkPhone != this.contactData.Phone)){//RWPS-3306
            // checkPhone = checkPhone.replace(/\D+/g, '');
            // checkPhone = checkPhone.substring(0,10);
            // checkPhone = checkPhone.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
            // this.refs.newPhoneId.value = checkPhone;
            //this.template.querySelector('[data-id="newPhone-Id"]').value = checkPhone;
            // Check phone value matches phone pattern.
            //var phoneRegex = /^[(]{0,1}[0-9]{3}[)]{0,1}[-\s\.]{0,1}[0-9]{3}[-\s\.]{0,1}[0-9]{4}$/;
            //event.target.value = checkPhone;
            this.contactData = {...this.contactData, Phone: checkPhone}; //RWPS-3306
            this.userData = {...this.userData, Phone: checkPhone};//RWPS-3306
            //this.copyContactData = {...this.copyContactData, Phone: this.refs.newPhoneId.value};
            phoneMatchPattern = true;
            this.contactPhoneUpdate = true;
            // if(checkPhone.match(phoneRegex)){
            //     phoneMatchPattern = true;
            //     this.isPhoneBlank = false;
            //     if(event.target.dataset.id === 'newPhone-Id'){
            //         this.contactData = {...this.contactData, Phone: event.target.value};
            //         this.userData = {...this.userData, Phone: event.target.value};
            //     }

            //     this.contactPhoneUpdate = true;
            // }else {
            //     phoneMatchPattern = false;
            //     this.showPhoneSaveButton = false;
            // }
        }

        // Check for Country Code Selection
        const allValid = [
            ...this.template.querySelectorAll('.update-phone-input')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid){
            countryCodeValid = true;
        } else {
            countryCodeValid = false;
        }

        // If phone match, and country code match, (or they match and a change in Phone Ext has happened) show save button
        if((countryCodeValid && phoneMatchPattern) || (countryCodeValid && phoneMatchPattern && changeInPhoneExt)){
            this.showPhoneSaveButton = true;
        } else {
            this.showPhoneSaveButton = false;
        }
        //RWPS-3306 start
        if (event.target.dataset.id !== 'OptOutCartEmail') return;


        if (event.target.dataset.id === 'OptOutCartEmail') {
            const isChecked = event.target.checked;
            const newOptOutValue = !isChecked; // The value to be stored in Ecom_Opt_Out_from_Cart_Emails__c field

            this.isCartReminder = isChecked; // Update UI toggle state

            let dataUpdated = false;

            // Find existing preference record for the logged-in user's email without ERP address
            let pref = this.emailDataWithoutErpAddress.find(record =>
                record.ECOM_Contact__c === this.contactData.Id &&
                record.ECOM_Email__c === this.loggedInUserEmail &&
                record.ECOM_isActive__c === true
            );

            if (pref) {
                // If a preference exists, update only if the value actually changed
                if (pref.Ecom_Opt_Out_from_Cart_Emails__c !== newOptOutValue) {
                    pref.Ecom_Opt_Out_from_Cart_Emails__c = newOptOutValue;
                    dataUpdated = true;
                }
            } else {
                // No existing preference record found for this email. Create a new one.
                const newPref = {
                    ECOM_Email__c: this.loggedInUserEmail,
                    ECOM_Contact__c: this.copyContactData.Id,
                    ERP_Address__c: null,
                    Ecom_Opt_Out_from_Cart_Emails__c: newOptOutValue,
                    ECOM_Send_Invoice__c: false,
                    ECOM_Order_Confirmation__c: false,
                    ECOM_Shipment_Notification__c: false,
                    ECOM_isActive__c: true
                };

                // Add the new preference record to the main emailData array for saving
                this.emailDataWithoutErpAddress = [...this.emailDataWithoutErpAddress, newPref];
                dataUpdated = true;
            }

            if (dataUpdated) {
                this.isOptOutCartEmailChanged = true;
                this.emailDataChange = true;
                this.changesDetected = true;
            } else {
                this.isOptOutCartEmailChanged = false;
            }
            this.checkForChanges();
        }

    }//RWPS-3306 END

    onContactSave() {
        // Check for Country Code Selection
        const allValid = [
            ...this.template.querySelectorAll('.update-phone-input')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid){
            if ((this.contactPhoneUpdate || this.isOptOutCartEmailChanged) && !this.isPhoneBlank) {   //RWPS-3306
                this.showSpinner = true;
                //update phone related fields
                let contact = {
                    Id : this.contactData?.Id,
                    Phone:this.contactData?.Phone,
                    ECOM_Country_Phone_Code__c:this.contactData?.ECOM_Country_Phone_Code__c,
                    ECOM_Phone_Extension__c : this.contactData?.ECOM_Phone_Extension__c
                }
                let user = {
                    Id : this.loggedinUser?.Id,
                    Phone:this.contactData?.Phone,
                    ECOM_Country_Phone_Code__c:this.contactData?.ECOM_Country_Phone_Code__c,
                    ECOM_Phone_Extension__c : this.contactData?.ECOM_Phone_Extension__c
                }
                // Update Contact
                updateContact({con: contact}).then((result)=>{
                    this.copyContactData = {...this.contactData, Phone:this.contactData?.Phone,ECOM_Country_Phone_Code__c:this.contactData?.ECOM_Country_Phone_Code__c};
                    this.loggedinUser = {...this.loggedinUser, Phone:this.contactData?.Phone,ECOM_Country_Phone_Code__c:this.contactData?.ECOM_Country_Phone_Code__c};
                    // Update User
                    updateUser({ updatedUserData: user }).then((result)=>{
                        this.isPhoneBlank = false;
                        this.isCountryCodeBlank = false;
                        this.showPhoneSaveButton = false;
                        this.onChangesSubmittedModalOpen();
                        this.onPhoneModalClose();
                        this.showSpinner = false;
                    })
                    .catch((error) => {
                        this.showSpinner = false;
                    });
                })
                .catch((error) => {
                    this.showSpinner = false;
                });



            }
        }
    }

    onShippingModalOpen(){
        this.isChangeShippingModalOpen = true;
        this.openModal('shipping');//RWPS-3764
        sendPostMessage('hidden');
    }

    onShippingModalClose(){
        this.isChangeShippingModalOpen = false;
        this.closeModal('shipping');//RWPS-3764
        sendPostMessage('auto');
    }

    changeShippingInfo(event){

        // Check data in Attach Receipient
        if(event.target.dataset.id === 'attention-recipient-id' ){
            this.contactData = {...this.contactData, ECOM_Attention_Recipient__c: event.target.value};
            this.isShippingChange = true;
        }

        // Check data in Special Instructions
        if(event.target.dataset.id === 'special-instructions-id' ){
            this.contactData = {...this.contactData, ECOM_Special_Instructions__c: event.target.value};
            this.isShippingChange = true;
        }

        // Check data in Delivery Details
        if(event.target.dataset.id === 'delivery-details-id' ){
            this.contactData = {...this.contactData, ECOM_Delivery_Details__c: event.target.value};
            this.isShippingChange = true;
        }
    }

    onSaveShippingInfo(){
        if(this.isShippingChange === true){
            this.showSpinner = true;
            let contact = {
                Id : this.contactData?.Id,
                ECOM_Special_Instructions__c:this.contactData?.ECOM_Special_Instructions__c,
                ECOM_Delivery_Details__c:this.contactData?.ECOM_Delivery_Details__c,
                ECOM_Attention_Recipient__c : this.contactData?.ECOM_Attention_Recipient__c
            }
            updateContact({con: contact}).then((result)=>{
                this.copyContactData = {...this.contactData, ECOM_Special_Instructions__c:this.contactData?.ECOM_Special_Instructions__c,ECOM_Delivery_Details__c:this.contactData?.ECOM_Delivery_Details__c,ECOM_Attention_Recipient__c:this.contactData?.ECOM_Attention_Recipient__c};
                this.onChangesSubmittedModalOpen();
                this.onShippingModalClose();
                this.isShippingChange = false;
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showSpinner = false;
            });
        }else {
            this.onNoChangesModalOpen();
            this.onShippingModalClose();
        }
    }

    // handleEmailPreferenceModalClose(event){
    //     this.getEmailPref();
    //     sendPostMessage('auto');
    // }
    handleScrollToTop() {
        const parentContainer = this.template.querySelector('.background');
        parentContainer.scrollIntoView({behavior: "smooth"});
    }
   /* New changes ends*/









    userData;
    copyUserData;
    userNameNeedUpdate = false;
    contactInfoNeedUpdate = false;
    showInlineSaveButton = false;
    showErrorModal = false;
    isChangePhoneModalOpen = false;
    contactPhoneUpdate = false;
    isChangeShippingModalOpen = false;
    deliveryDetails;
    attentionRecipient;
    spInstructions;
    spInstructionsPicklist = [];
    isShippingChange = false;
    contactRecTypeId;
    isChangeEmailNotiModalOpen = false;
    emailData;
    copyEmailData;
    deleteEmailList = [];
    emailDataChange = false;
    isEmailBlank = false;
    isEmailNotValid = false;
    isEmailCheckboxBlank = false;
    isEmailInlineCheckboxBlank = false;
    emailcheckboxError = false;
    showEmailSaveButton = false;
    acctId;


    isChangedSubmittedModalOpen = false;
    isNoChangesModalOpen = false;
    isSmallScreen = false;
    isPhoneBlank = false;
    showPhoneSaveButton = false;
    shippingSpecialInstruction;
    showCheckoutEmailModal = false;

    get modalOpenStyling(){
        let stylingClass = 'body';
        if(this.isChangePhoneModalOpen || this.isChangePasswordModalOpen || this.isChangeShippingModalOpen || this.isChangeEmailNotiModalOpen || this.isNoChangesModalOpen || this.showErrorModal){
            stylingClass = 'body ecom-modal-open';
        }
        return stylingClass;
    }

    get modalScreenSizing(){
        return this.device.isMobile ? "slds-modal slds-fade-in-open slds-modal_full" : "slds-modal slds-fade-in-open";
    }

    // USER INFORMATION CHANGE
    // @wire(getUser)
    // wiredUserData({ error, data }) {
    //     if(this.device.isMobile || FORM_FACTOR === 'Small'){
    //         this.isSmallScreen = true;
    //     }

    //     if (data) {
    //         this.userData = data.User;
    //         // Copy for HTML To not be updated in real time per QA - row 61
    //         this.copyUserData = data.User;
    //         //console.log('this.userData: ' + JSON.stringify(this.userData))

    //         // Flatten to show in HTML
    //         this.acctId = data.User.AccountId;

    //         // Flatten for changing data and saving
    //         this.contactData = this.userData.Contact;
    //         // Copy for HTML To not be updated in real time per QA - row 61
    //         this.copyContactData = this.userData.Contact;
    //         //console.log('### this.contactData: ' + JSON.stringify(this.contactData))
    //         this.shippingSpecialInstruction = this.contactData.ECOM_Special_Instructions__c;

    //     } else if (error) {
    //         console.log('error ' + JSON.stringify(error));
    //     }

    //     // get Email Preferences
    //     this.getEmailPref();

    // }

    showHoverIcon(event) {
        const img = event.target;
        const hoverIconSrc = img.getAttribute('data-hover-icon-src');
        img.src = hoverIconSrc;
    }

    showOriginalIcon(event) {
        const img = event.target;
        const originalIconSrc = img.getAttribute('data-icon-src');
        img.src = originalIconSrc;
    }

    handleUserOnChange(event) {
        // Check data in User FirstName
        if(event.target.dataset.id === 'fName-Id' ){
            var newFirst = event.target.value;
            this.userData = {...this.userData, FirstName: newFirst};
            this.userNameNeedUpdate = true;

            // Update Contact Info at the Same time
            this.contactData = {...this.contactData, FirstName: newFirst};
            this.contactInfoNeedUpdate = true;
        }

        // Check data in User LastName
        if(event.target.dataset.id === 'lName-Id' ){
            var newLast = event.target.value;
            this.userData = {...this.userData, LastName: newLast};
            this.userNameNeedUpdate = true;
            // Update Contact Info at the Same time
            this.contactData = {...this.contactData, LastName: newLast};
            this.contactInfoNeedUpdate = true;
        }

        this.checkForChanges();
    }

    checkForChanges(){
        if(this.userNameNeedUpdate || this.contactInfoNeedUpdate || this.emailDataChange || this.deleteEmailList.length || this.isOptOutCartEmailChanged){//RWPS-3306
            this.showInlineSaveButton = true;
        } else {
            this.showInlineSaveButton = false;
        }

    }



    onChangesSubmittedModalOpen(){
        //this.isChangedSubmittedModalOpen = true;
    }

    onChangesSubmittedModalClose(){
        this.isChangedSubmittedModalOpen = false;
        // refresh page after save
       // window.location.reload();
    }

    onNoChangesModalOpen(){
        this.isNoChangesModalOpen = true;
        this.openModal('noChanges');//RWPS-4153
        sendPostMessage('hidden');
    }

    onNoChangesModalClose(){
        this.isNoChangesModalOpen = false;
        //RWPS-4153 Start
        if (this.originalTriggerElement) {
            this.originalTriggerElement.focus();
            this.originalTriggerElement = null; 
        }//RWPS-4153 End
        sendPostMessage('auto');
    }

    onCloseErrorModal(){
        this.showErrorModal = false;
        this.closeModal('error');//RWPS-3764
        sendPostMessage('auto');
    }


    checkForPasswordRequirements(event){
        if(event.target.dataset.id === 'pwordBox-masked-Id' || event.target.dataset.id === 'pwordBox-unmasked-Id' ){
            this.newPassword = event.target.value;
            this.checkStrength(this.newPassword);
            if(this.newPassword === "" || this.newPassword === null){
                this.isPass1Blank = true;
                this.pwrdStrength='Weak';
                this.clearPasswordStatus();

                // Hide Save button in case something changed
                this.showPasswordSaveButton = false;
            }else {
                this.isPass1Blank = false;
                if((this.isPass2Blank === false && this.isPass1Blank === false) && (this.newPassword === this.newPassword2)){
                    this.isPassMatch = true;
                    if(this.pwrdStrength === "Strong"){
                        // Show clickable Save button
                        this.showPasswordSaveButton = true;
                    }
                } else{
                    // Display Mismatch message
                    this.isPassMatch = false;

                    // Hide Save button in case something changed
                    this.showPasswordSaveButton = false;
                }

            }




        }
        if(event.target.dataset.id === 'pwordBox2-masked-Id' || event.target.dataset.id === 'pwordBox2-unmasked-Id'  ){
            this.newPassword2 = event.target.value;
            if(this.newPassword2 === "" || this.newPassword2 === null){
                this.isPass2Blank = true;
                this.isPassMatch = true;
            }else {
                this.isPass2Blank = false;
                if((this.isPass2Blank === false && this.isPass1Blank === false) && (this.newPassword === this.newPassword2)){
                    this.isPassMatch = true;
                    if(this.pwrdStrength === "Strong"){
                        // Show clickable Save button
                        this.showPasswordSaveButton = true;
                    }
                } else{
                    // Display Mismatch message
                    this.isPassMatch = false;

                    // Hide Save button in case something changed
                    this.showPasswordSaveButton = false;
                }
            }

        }

    }

    maskPassword(){
        if(this.isPassMasked === false){
            // if already unmasked, mask it and set to true
            if(this.template.querySelector('[data-id="pwordBox-unmasked-Id"]')){
                this.newPassword = this.template.querySelector('[data-id="pwordBox-unmasked-Id"]').value;
                this.isPassMasked = true;
            }
        } else if(this.isPassMasked === true) {
            // if already masked, unmask it and set to false
            if(this.template.querySelector('[data-id="pwordBox-masked-Id"]')){
                this.newPassword =  this.template.querySelector('[data-id="pwordBox-masked-Id"]').value;
                this.isPassMasked = false;
            }
        }
    }

    maskPasswordbox2(){
        if(this.isPassMasked2 === false){
            // if already unmasked, mask it and set to true
           if(this.template.querySelector('[data-id="pwordBox2-unmasked-Id"]')){
               this.newPassword2 = this.template.querySelector('[data-id="pwordBox2-unmasked-Id"]').value;
               this.isPassMasked2  = true;
           }
       } else if(this.isPassMasked2 === true){
            // if already masked, unmask it and set to false
           if(this.template.querySelector('[data-id="pwordBox2-masked-Id"]')){
               this.newPassword2 =  this.template.querySelector('[data-id="pwordBox2-masked-Id"]').value;
               this.isPassMasked2 = false;
           }
       }
    }



    updatePassword(){
        this.showSpinner = true;
        this.messageType = 'success';
        updateUserPassword({ passwordString: this.newPassword}).then((result) => {
           this.showSpinner = false;
           if(result.success){
                this.showMessage = true;
                this.message = 'Changes saved successfully.';
           }
           else{
                this.showMessage = true;
                this.message = 'Please choose a Password that is different from your 3 recent passwords.';
                this.messageType = 'error';
           }
           this.handleScrollToTop();
           this.messageType = 'success';
        })
        .catch((error) => {
            this.showSpinner = false;
        });
    }
    popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-fall-into-ground ecom-popover';
    showPopover(evt){
          this.showTooltip = true;
          this.popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-rise-from-ground ecom-popover';
        }

    hidePopover(){
        this.showTooltip = false;
        this.popoverClass ='slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-fall-into-ground ecom-popover'
    }

    // images = {
    //     helpimg: ssrc_ECOM_Theme + '/img/checkouttooltip.png',
    // }



    // EMAIL PREFERENCES
    getEmailPref(){
        this.showSpinner = true;
        getEmailPreferences({ acctId: this.acctId})
            .then((result) => {
             //RWPS-3306 START
            // Divide into two lists
            this.emailData = result.filter(
                pref => pref.ERP_Address__c && pref.ERP_Address__c.trim() !== ''
            );

            this.emailDataWithoutErpAddress = result.filter(x =>!x.ERP_Address__c || x.ERP_Address__c.trim() === '');
            if (this.emailDataWithoutErpAddress.length > 0) {
                let emailRecord = this.emailDataWithoutErpAddress;
                let optOutPref = false;

                for (let i = 0; i < emailRecord.length; i++) {
                    if (
                        emailRecord[i]['ECOM_Contact__c'] === this.contactData?.Id && emailRecord[i]['ECOM_Email__c'] === this.loggedInUserEmail
                    ) {
                        optOutPref = emailRecord[i]['Ecom_Opt_Out_from_Cart_Emails__c'];
                        break;
                    }
                }

                this.isCartReminder = !optOutPref;
            } else {
                this.isCartReminder = true;
            }//RWPS-3306 END
           // Copy for HTML To not be updated in real time per QA - row 61
           this.copyEmailData = [...this.emailData]; // RWPS-3306, RWPS-5402, RWPS-6920
           this.showSpinner = false;
        })
        .catch((error) => {
            this.showSpinner = false;
        });

    }

    onEmailOrderChange(event){
        this.changesDetected = true;
        //RWPS-5402 Start
        let id = event.target.dataset.id;//RWPS-6920
        let checked = event.target.checked;//RWPS-6920

        let emailRecord = this.emailData.find(item => item.Id === id);

        if (emailRecord) {
            emailRecord.ECOM_Order_Confirmation__c = checked;//RWPS-6920
            this.emailData = [...this.emailData];
        } else {//RWPS-6920 start
            emailRecord = this.emailDataWithoutErpAddress.find(item => item.Id === id);
            if (emailRecord) {
                emailRecord.ECOM_Order_Confirmation__c = checked;//RWPS-6920 end
                this.emailDataWithoutErpAddress = [...this.emailDataWithoutErpAddress];
            }
        }
        this.copyEmailData = [...this.emailData];//RWPS-6920
        //RWPS-5402 End
        let cbDataId = '[data-id="' + event.target.dataset.id + '"]'
        let checkboxById = [...this.template.querySelectorAll(cbDataId)]
        let target;
        if(this.isSmallScreen){
            target = 'div.checkboxMessageSmall' + cbDataId;
        } else {
            target = 'div.checkboxMessage' + cbDataId;
        }

        let containerError = this.template.querySelector(target);

        if(!event.target.checked){
            let countTrue = 0;
            for (let i = 0; i < checkboxById.length; i++) {

                if(checkboxById[i].checked){
                    countTrue++;
                }
            }
            if(countTrue < 1){
                if(this.isSmallScreen){
                    containerError.innerHTML = CONTAINER_HTML_SMALL;
                } else {
                    containerError.innerHTML = CONTAINER_HTML;
                }
                this.mailcheckboxError = true;
                this.emailDataChange = false;
                this.checkForChanges();
            } else {
                containerError.innerHTML = CONTAINER_HTML_BLANK;
                this.emailDataChange = true;
                this.emailcheckboxError = false;
                this.checkForChanges();
            }
        } else {
            containerError.innerHTML = CONTAINER_HTML_BLANK;
            this.emailDataChange = true;
            this.emailcheckboxError = false;
            this.checkForChanges();
        }
    }

    onEmailShipChange(event){
        this.changesDetected = true;
        //RWPS-5402 Start
        let emailRecord = this.emailData.find(item => item.Id === event.target.dataset.id);
        if (!emailRecord) {
            emailRecord = this.emailDataWithoutErpAddress.find(item => item.Id === event.target.dataset.id);
        }

        if (emailRecord) {
            emailRecord.ECOM_Shipment_Notification__c = event.target.checked;
            this.emailData = [...this.emailData];
            this.emailDataWithoutErpAddress = [...this.emailDataWithoutErpAddress];
            this.copyEmailData = [...this.emailData]; // Only ERP records in UI - RWPS-6920
        }
        //RWPS-5402 End
        let cbDataId = '[data-id="' + event.target.dataset.id + '"]'
        let checkboxById = [...this.template.querySelectorAll(cbDataId)]
        let target;
        if(this.isSmallScreen){
            target = 'div.checkboxMessageSmall' + cbDataId;
        } else {
            target = 'div.checkboxMessage' + cbDataId;
        }
        let containerError = this.template.querySelector(target);

        if(!event.target.checked){
            var countTrue = 0;
            for (let i = 0; i < checkboxById.length; i++) {

                if(checkboxById[i].checked){
                    countTrue++;
                }
            }
            if(countTrue < 1){
                containerError.innerHTML = CONTAINER_HTML;
                //this.showInlineSaveButton = false;
                this.emailDataChange = false;
                this.emailcheckboxError = true;
                this.checkForChanges();
            } else {
                containerError.innerHTML = CONTAINER_HTML_BLANK;
                this.emailDataChange = true;
                this.emailcheckboxError = false;
                this.checkForChanges();
            }
        } else {
            containerError.innerHTML = CONTAINER_HTML_BLANK;
            this.emailDataChange = true;
            this.emailcheckboxError = false;
            this.checkForChanges();
        }

    }



    onEmailDelete(event){
        this.changesDetected = true;
        this.emailDeleted = true;  // RWPS-2562 added flag  to delete email correctly
        //this.emailDelete = true;
        //RWPS-5402 Start
        const emailId = event.target.dataset.id;
        var delItem = {Id: emailId};
        this.deleteEmailList.push(delItem);
        this.emailData = this.emailData.filter(item => item.Id !== emailId);
        this.emailDataWithoutErpAddress = this.emailDataWithoutErpAddress.filter(item => item.Id !== emailId);
        this.copyEmailData = [...this.emailData];//RWPS-6920
        //RWPS-5402 End
        //RWPS-3764 start
        const wasLast = this.copyEmailData.length === 1;
        setTimeout(() => {
            if (wasLast) {
                const cartReminderToggle = this.template.querySelector(
                    'input[data-id="OptOutCartEmail"]'
                );
                if (cartReminderToggle) {
                    cartReminderToggle.focus();
                }
            } else {
                const allIcons = this.template.querySelectorAll('.ecom-qo-deleteitem-btn');
                if (allIcons.length > 0) {
                    allIcons[0].focus();
                }
            }
        }, 0);//RWPS-3764 end
    }

    onEmailNotiModalOpen(){
        this.isChangeEmailNotiModalOpen = true;
        this.openModal('emailnoti');//RWPS-3764
        sendPostMessage('hidden');
    }

    onEmailNotiModalClose(){
        this.isChangeEmailNotiModalOpen = false;
        this.closeModal('emailnoti');//RWPS-3764
        sendPostMessage('auto');
    }


    addEmailSave(){
        // Email Preference Changes
        upsertEmailPreferences({changesList: JSON.stringify(this.emailData) }).then((result)=>{
            this.getEmailPref();
        })
        .catch((error) => {
        });
        this.isEmailBlank = false;
        this.isEmailNotValid = false;
        this.isEmailCheckboxBlank = false;
        this.showEmailSaveButton = false;
        // close modal
        this.onChangesSubmittedModalOpen();
        this.onEmailNotiModalClose();
    }

    // Checkout Email Modal

    handleAddEmail(event){
        //RWPS-4087 start
        if (event.type === 'click' ||  (event.type === 'keydown' && (event.key === 'Enter' || event.key === ' '))) {
            event.preventDefault(); //RWPS-4087 end
            this.template.querySelector('c-ecom_checkout-email-notification-modal')?.openModal();
        }
    }

    newEmailAddressRows = [];
    handleEmailPreferenceModalClose(event){
        sendPostMessage('auto');
    }
    handleEmailPreferencesAdded(event){
        sendPostMessage('auto');
        this.newEmailAddressRows = event.detail.emailAddressRows;
        // Get Contact & Acct Id to add to new record.
        let contactId = this.contactData.Id;
        //var acctId = this.userData.AccountId;
        let erpAddressId = this.contactData.Default_Ship_to_ERP_Address__c;
        this.newEmailAddressRows.forEach(e => {
            // create data and add to variable array
        let newRecord = {ERP_Address__c:erpAddressId, ECOM_Contact__c: contactId,
            ECOM_Order_Confirmation__c: e.ECOM_Order_Confirmation__c , ECOM_Shipment_Notification__c: e.ECOM_Shipment_Notification__c,
            ECOM_Email__c: e.ECOM_Email__c , Ecom_Opt_Out_from_Cart_Emails__c: false};//Rwps-3306
        this.emailData.push(newRecord);
        })

        // save the data
        if(this.emailData.length > 0 ){
            this.addEmailSave();
        }
    }
    //RWPS-2722 start
    handleEmailPrefChange(event) {
        const value = event.target.value.trim();
        this.emailValue = value;
        this.isEmailInvalid = false;

        if (!this.validateEmail(value)) {
            this.isEmailInvalid = true;
        }
    }
    validateEmail(email) {
        const regex = /^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/;
        return regex.test(email);
    }//RWPS-2722 end
    //RWPS-3764 start
    handleCheckboxKeyup(event) {
        if (event.key === 'Enter') {
          event.target.checked = !event.target.checked;
          if (event.target.dataset.label === 'ECOM_Order_Confirmation__c') {
            this.onEmailOrderChange(event);
          } else if (event.target.dataset.label === 'ECOM_Shipment_Notification__c') {
            this.onEmailShipChange(event);
          }
        }
    }

    handleButtonKeyup(event) {
        if (event.key === 'Enter' || event.key === ' ') {
          this.onEmailDelete(event);
        }
      }
    handleKeyDelete(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.onEmailDelete(event);
        }
    }
    handleKeyOpenPhoneModal(event) {
        if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            this.lastFocusedElement = event.currentTarget;//RWPS-4087
            this.onPhoneModalOpen();
        }
    }

    // RWPS-4153 Start
    handleClickOpenPhoneModal(event) {
    this.lastFocusedElement = event.currentTarget; 
    this.onPhoneModalOpen();
    }// RWPS-4153 End

    handleKeyOpenPasswordModal(event) {
        if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            this.lastFocusedElement = event.currentTarget;//RWPS-4087
            this.changePasswordModalOpen();
        }
    }

    // RWPS-4153 Start
    handleClickOpenPasswordModal(event) {
    this.lastFocusedElement = event.currentTarget; 
    this.changePasswordModalOpen(); 
    }// RWPS-4153 End

    handleKeyOpenShippingModal(event) {
        if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            this.lastFocusedElement = event.currentTarget;//RWPS-4087
            this.originalTriggerElement = event.currentTarget;//RWPS-4153
            this.onShippingModalOpen();
        }
    }

    // RWPS-4153 Start
    handleClickOpenShippingModal(event) {
    this.lastFocusedElement = event.currentTarget; 
    this.originalTriggerElement = event.currentTarget;
    this.onShippingModalOpen(); 
    }// RWPS-4153 End

    // RWPS-4153 Start
    handleKeyDownOk(event) { 
        if (event.key === "Enter" || event.key === " " || event.key === "Escape") {
            event.preventDefault();
            this.onNoChangesModalClose();
        }
    }//RWPS-4153 End


    trapFocus(event) {
        const modal = this.template.querySelector('[role="dialog"]');
        if (!modal) return;                                                                 
    
        const focusableElements = modal.querySelectorAll(
            'a[href], area[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), [tabindex]:not([tabindex="-1"])'
        );
        const firstEl = focusableElements[0];
        const lastEl = focusableElements[focusableElements.length - 1];
    
        if (event.key === 'Tab') {
            if (focusableElements.length === 0) return;
    
            if (event.shiftKey) {
                if (document.activeElement === firstEl || modal === document.activeElement) {
                    event.preventDefault();
                    lastEl.focus();
                }
            } else {
                if (document.activeElement === lastEl) {
                    event.preventDefault();
                    firstEl.focus();
                }
            }
        }
    }
    
    openModal(modalType) {   
    this.bodyScroll = 'body-no-overflow slds-align_absolute-center slds-p-right_medium';
    this.hasFocusedModal = false;

    if(modalType !== 'error')
    {
        this[`is${this.capitalize(modalType)}ModalOpen`] = true;
    }
    else{
        this.showErrorModal = true;
    }

    setTimeout(() => {
        const modal = this.template.querySelector('[role="dialog"]');
        if (modal && !this.hasFocusedModal) {
            const firstFocusable = modal.querySelector(
                'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
            );
            firstFocusable?.focus();
            this.hasFocusedModal = true;
        }
    }, 0);

    // Trap focus
    this.handleFocusTrapBound = this.trapFocus.bind(this);
    window.addEventListener('keydown', this.handleFocusTrapBound);
    sendPostMessage('hidden');
    }

    closeModal(modalType) {
        if(modalType !== 'error')
        {
            this[`is${this.capitalize(modalType)}ModalOpen`] = false;//RWPS-4087
        }
        else{
            this.showErrorModal = false;//RWPS-4087
        }
    
        if (this.handleFocusTrapBound) {
            window.removeEventListener('keydown', this.handleFocusTrapBound);
            this.handleFocusTrapBound = null;
        }
        this.hasFocusedModal = false;
        sendPostMessage('auto');
        //RWPS-4087 start
        if (this.lastFocusedElement) {
            this.lastFocusedElement.focus();
            this.lastFocusedElement = null; 
        }//RWPS-4087 end
    }

    capitalize(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    }//RWPS-3764 end  
    //RWPS-4087
    handleKeyDownSaveContact(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            if(this.showSpinner)
            {
                return;
            }
            event.target.click();
        } 
    }
    //RWPS-4087 end
    
}