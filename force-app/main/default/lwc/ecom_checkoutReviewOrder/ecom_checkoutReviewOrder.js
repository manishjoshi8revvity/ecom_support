import { LightningElement,track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import getEmailPreferences from '@salesforce/apex/ECOM_CheckoutController.getEmailPreferences';
import createOrUpdateEmailPreferences from '@salesforce/apex/ECOM_CheckoutController.createOrUpdateEmailPreferences';
import FORM_FACTOR from '@salesforce/client/formFactor';

import ECOM_EmailAddresses from '@salesforce/label/c.ECOM_EmailAddresses';
import ECOM_AdditionalEmailAddresses from '@salesforce/label/c.ECOM_AdditionalEmailAddresses';
import ECOM_Remove from '@salesforce/label/c.ECOM_Remove';
import ECOM_AddAnotherEmailAddress from '@salesforce/label/c.ECOM_AddAnotherEmailAddress';
import ECOM_SaveAndContinue from '@salesforce/label/c.ECOM_SaveAndContinue';

export default class Ecom_checkoutReviewOrder extends NavigationMixin(LightningElement) {
    labels = {
        ECOM_EmailAddresses,
        ECOM_AdditionalEmailAddresses,
        ECOM_Remove,
        ECOM_AddAnotherEmailAddress,
        ECOM_SaveAndContinue
    };

    @api effectiveAccountId;
    @api isReviewReadMode;
    @api isReviewEditMode;
    @api paymetDataMap;
    @api cartId;
    showSpinner = false;
    _newEmailPrefIndex = 0;
    @track
    images = {
        visaimg: ssrc_ECOM_Theme + '/img/visa.png',
        helpimg: ssrc_ECOM_Theme + '/img/checkouttooltip.png',
    }
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }
    @track isPlaceOrderBtnDisabled = true;
    @track isNewUserListAvailable = false;
    @track newEmailAddressRows = [];
    @track updatedEmailAddressRows = [];
    @track existingEmailAddressRows = [];
    @track accountLvlEmailAddressRows = [];
    @track emailPrefUpdate;
    @track isUpdate = false;
    @track isAdd = false;
    @track renderModal = false;
    @track formattedEmails = [];

    //RWPS-5436 - Start
    @api
    isTestingUser;

    @api
    orgDetails;

    @api
    configurationDetails;
    //RWPS-5436 - End

    @track
    existingEmailsCollection; //RWPS-5892

    get emailIdList() {
        return this.accountLvlEmailAddressRows.map(emailRow => emailRow.ECOM_Email__c).join(', ');
    }

    //RWPS-5436
    get isTestingMode() {
        return (this.orgDetails && this.orgDetails[0] && this.orgDetails[0].IsSandbox && this.orgDetails[0].IsSandbox == true && this.isTestingUser == true) || (this.isTestingUser == true) ? true : false;
    }

    connectedCallback(){
        //RWPS-5436 - Start
        if (this.isTestingMode == true && this.configurationDetails?.orderEmailIDsForTestUser && this.configurationDetails?.orderEmailIDsForTestUser != '') {
            let testingEmailData = { detail: { emailAddressRows: [ {
                "index": 0,
                "isEmailInvalid": false,
                "errorMessage": "",
                "ECOM_Account__c": "",
                "ECOM_Contact__c": "",
                "ECOM_Email__c": this.configurationDetails.orderEmailIDsForTestUser,
                "ECOM_Order_Confirmation__c": true,
                "ECOM_Send_Invoice__c": true,
                "ECOM_Shipment_Notification__c": true,
                "ECOM_isActive__c": true,
                "ERP_Address__c": "",
                "Ecom_Opt_Out_from_Cart_Emails__c": false,
                "Id" : "", //RWPS-5436
                "Name" : "testingEmail" //RWPS-5436
            } ] } };
            this.handleEmailPreferencesAdded(testingEmailData);
        }
        //RWPS-5436 - End

        if(this.effectiveAccountId){
            getEmailPreferences({
                effectiveAccountId: this.effectiveAccountId
            }).then((result) => {
                    if(result){
                        if(result.Status == 'Success'){
                            this.accountLvlEmailAddressRows = result?.ListEmailPrefAccountLvl;
                            this.existingEmailAddressRows = result?.ListEmailPrefContactLvl;
                            this.existingEmailsCollection = result?.ListEmailPrefContactLvl; //RWPS-5892
                            //RWPS-5436 - logic to remove duplicate test emails (if already exists) - Start
                            if (this.isTestingMode == true && this.configurationDetails?.orderEmailIDsForTestUser && this.configurationDetails?.orderEmailIDsForTestUser != '') {
                                let existingEmailAddress = result?.ListEmailPrefContactLvl;
                                let uniqueEmailAddress = [];
                                for (let index = 0; index < existingEmailAddress.length; index++) {
                                    //RWPS-5892 : Modified the logic to check for includes instead of exact match
                                    if(existingEmailAddress[index]?.ECOM_Email__c?.toLowerCase()?.includes(this.configurationDetails?.orderEmailIDsForTestUser?.toLowerCase()) == false) {
                                        uniqueEmailAddress.push(existingEmailAddress[index]);
                                    }
                                }
                                this.existingEmailAddressRows = uniqueEmailAddress;
                            }
                            //RWPS-5436 - End
                            this.formatEmailRows(this.existingEmailAddressRows);
                        }
                    }
                })
                .catch((error) => {
                    console.log('error =>'+JSON.stringify(error));
                });
        }
    }

    handleAddEmail(){
        this.template.querySelector('c-ecom_checkout-email-notification-modal')?.openModal();
    }

    handleEmailPreferencesAdded(event){
        let emailRowsToFormat = [];
        let addedEmailRows = event.detail.emailAddressRows;
        for(let key in addedEmailRows){
            let newEmailRow = addedEmailRows[key];
            newEmailRow['emailPrefRowindex'] = this._newEmailPrefIndex.toString();
            let stringifiedRow = JSON.stringify(newEmailRow);
            let parsedRow = JSON.parse(stringifiedRow);
            emailRowsToFormat.push(parsedRow);
            this.newEmailAddressRows.push(parsedRow);
            this.existingEmailAddressRows.push(parsedRow);
            this._newEmailPrefIndex++;
        }
        this.formatEmailRows(emailRowsToFormat);
    }

    formatEmailRows(emailAddressRows){
        for(let i in emailAddressRows){
            let notificationTypes = '';
            if(emailAddressRows[i].ECOM_Order_Confirmation__c){
                notificationTypes += 'Order Confirmation+';
            }
            if(emailAddressRows[i].ECOM_Shipment_Notification__c){
                notificationTypes += 'Shipment Notification';
            }
            notificationTypes = notificationTypes.replace(/\+$/, '');
            notificationTypes = notificationTypes.replaceAll('+', ' & ');
            let formattedEmailRecord = {'id':emailAddressRows[i].Id,'emailPrefRowindex':emailAddressRows[i].emailPrefRowindex,'email': emailAddressRows[i].ECOM_Email__c, 'notificationTypes': notificationTypes};
            if(this.isUpdate){
                let formattedEmailRows = [formattedEmailRecord];
                this.formattedEmails = this.formattedEmails.map(obj => formattedEmailRows.find(o => o.id === obj.id) || obj);
            }
            else{
                this.formattedEmails.push(formattedEmailRecord);
            }

            this.isNewUserListAvailable = this.formattedEmails.length > 0 ? true :false;
            this.isUpdate = false;
        }

        //RWPS-5436 - Logic to add test email if not already exists for sandbox to check duplicate emails - Start
        if (this.isTestingMode == true && this.configurationDetails?.orderEmailIDsForTestUser && this.configurationDetails?.orderEmailIDsForTestUser != '') {
            if (this.existingEmailAddressRows) {
                let testingEmailExists = false;
                for (let index = 0; index < this.existingEmailAddressRows.length; index++) {
                    if(this.existingEmailAddressRows[index]?.ECOM_Email__c?.toLowerCase() == this.configurationDetails?.orderEmailIDsForTestUser?.toLowerCase()) {
                        testingEmailExists = true;
                    }
                }
                if (testingEmailExists == false) {
                    this.existingEmailAddressRows.push({
                        "index": 0,
                        "isEmailInvalid": false,
                        "errorMessage": "",
                        "ECOM_Account__c": "",
                        "ECOM_Contact__c": "",
                        "ECOM_Email__c": this.configurationDetails.orderEmailIDsForTestUser,
                        "ECOM_Order_Confirmation__c": true,
                        "ECOM_Send_Invoice__c": true,
                        "ECOM_Shipment_Notification__c": true,
                        "ECOM_isActive__c": true,
                        "ERP_Address__c": "",
                        "Ecom_Opt_Out_from_Cart_Emails__c": false,
                        "Id" : "",
                        "Name" : "testingEmail"
                    });
                }
            }
        }
        //RWPS-5436 - End
    }

    removeEmailPrefList = [];
    handleRemoveEmailPref(event){
        let index = event.target.dataset.index;
        this.formattedEmails.splice(index, 1);
        this.formattedEmails = [...this.formattedEmails];

        let removeEmailPref = {Id: event.target.dataset.id};
        if(removeEmailPref.Id){
            this.removeEmailPrefList.push(removeEmailPref);
        }

        if(event.target.dataset.rowindex){
            let rowIndex = this.newEmailAddressRows.findIndex(item => item.emailPrefRowindex === event.target.dataset.rowindex);
            //delete this.newEmailAddressRows[rowIndex];
            this.newEmailAddressRows.splice(rowIndex, 1);
            this.newEmailAddressRows = [...this.newEmailAddressRows];
            let existingRowIndex = this.existingEmailAddressRows.findIndex(item => item.emailPrefRowindex === event.target.dataset.rowindex);
            this.existingEmailAddressRows.splice(existingRowIndex, 1);
            this.existingEmailAddressRows = [...this.existingEmailAddressRows];
        }
    }

    handleSaveEmailPref(){
        this.showSpinner = true;

        if(this.newEmailAddressRows.length || this.removeEmailPrefList.length){

            //RWPS-5892 : Logic to check whether testing email is already present & removing it if already present to avoid duplication - Start
            if (this.isTestingMode == true && this.existingEmailsCollection && this.existingEmailsCollection.length > 0 && this.configurationDetails?.orderEmailIDsForTestUser && this.configurationDetails?.orderEmailIDsForTestUser != '') {
                let testingEmailExists = false;
                for (let index = 0; index < this.existingEmailsCollection.length; index++) {
                    //RWPS-5892 : Modified the logic to check for includes instead of exact match
                    if (this.existingEmailsCollection[index]?.ECOM_Email__c?.toLowerCase()?.includes(this.configurationDetails?.orderEmailIDsForTestUser?.toLowerCase())) {
                        testingEmailExists = true;
                    }
                }
                if (testingEmailExists == true) {
                    let tempNewEmailAddressRows =  this.newEmailAddressRows? JSON.parse(JSON.stringify(this.newEmailAddressRows)) : [];
                    let filteredNewEmailAddressRows = [];
                    for (let index = 0; index < tempNewEmailAddressRows.length; index++) {
                        if(tempNewEmailAddressRows[index]?.ECOM_Email__c?.toLowerCase() != this.configurationDetails?.orderEmailIDsForTestUser?.toLowerCase()) {
                            filteredNewEmailAddressRows.push(tempNewEmailAddressRows[index]);
                        }
                    }
                    if (filteredNewEmailAddressRows && filteredNewEmailAddressRows.length > 0) {
                        this.newEmailAddressRows = filteredNewEmailAddressRows;
                    } else {
                        this.newEmailAddressRows = [];
                    }
                }
            }
            //RWPS-5892 - End
            //validate first before saving
            createOrUpdateEmailPreferences({
                newEmailAddressRows: JSON.stringify(this.newEmailAddressRows),
                removeEmailPrefList: JSON.stringify(this.removeEmailPrefList)
            }).then((result) => {
                    if(result){
                        if(result.Status == 'Success'){
                            this.showSpinner = false;
                            this.newEmailAddressRows = [];
                        }
                    }
            })
            .catch((error) => {
            });
        }
        this.moveToNextSection();
    }
    moveToNextSection(){
        this.showSpinner = false;
        this.dispatchEvent(
            new CustomEvent('showinvoicesection', {
                detail: {
                    moveToNextSection: true
                }
            })
        );   
    }

}