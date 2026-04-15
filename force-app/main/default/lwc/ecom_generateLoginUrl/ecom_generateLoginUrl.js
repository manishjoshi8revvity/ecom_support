import { LightningElement } from 'lwc';

//apex imports
import getPunchoutAccounts from '@salesforce/apex/ECOM_AccountsController.getPunchoutAccounts';
//import loginTestUser from '@salesforce/apex/ECOM_PunchoutLoginController.loginTestPunchoutUserForAccountId';
import validateTestUser from '@salesforce/apex/ECOM_PunchoutLoginController.validateTestUserForAccountId';
import loginTestUser from '@salesforce/apex/ECOM_PunchoutLoginController.calloutToLoginTestUser';

//js imports
import {  SYSTEM_CONSTANTS,parseJSON } from 'c/ecom_punchoutUtil';

//labels
import LBL_PUNCHOUT_URL_GENERATOR from '@salesforce/label/c.ECOM_Punchout_Url_Generator';
import LBL_CUSTOMER_ATTRIBUTES from '@salesforce/label/c.ECOM_Customer_Attributes';
import LBL_CHOOSE_A_COMPANY from '@salesforce/label/c.ECOM_ChooseACompany';
import LBL_SELECTED_COMPANY from '@salesforce/label/c.ECOM_SelectedCompany';
import LBL_EMAILUSERNAME from '@salesforce/label/c.ECOM_EmailUsername';
import LBL_FIRSTNAME from '@salesforce/label/c.ECOM_FirstName';
import LBL_LASTNAME from '@salesforce/label/c.ECOM_LastName';
import LBL_USEPRODQARECORDS from '@salesforce/label/c.ECOM_UseProdQARecords';
import LBL_GENERATEDURL from '@salesforce/label/c.ECOM_GeneratedUrl';
import LBL_LOGIN from '@salesforce/label/c.ECOM_Login';
import LBL_RESET from '@salesforce/label/c.ECOM_Reset';
import LBL_GENERATE_URL from '@salesforce/label/c.ECOM_GenerateUrl';
import LBL_GENERATE_URL_FAILED from '@salesforce/label/c.ECOM_GenerateLoginURLFailed';
import LBL_SELECT_ACCOUNT_FOR_LOGIN from '@salesforce/label/c.ECOM_SelectAnAccountForTestLogin';

export default class Ecom_generateLoginUrl extends LightningElement {

    //export reused constants
    SYSTEM_CONSTANTS = {
        ACTION_LOGIN : 'login',
        ACTION_RESET : 'reset',
        ACTION_GENERATEURL : 'generate',
        ERROR: 'error'
    }

    //label
    system_labels = {
        PUNCHOUT_URL_GENERATOR: LBL_PUNCHOUT_URL_GENERATOR,
        CUSTOMER_ATTRIBUTES: LBL_CUSTOMER_ATTRIBUTES,
        CHOOSE_A_COMPANY: LBL_CHOOSE_A_COMPANY,
        SELECTED_COMPANY: LBL_SELECTED_COMPANY,
        EMAIL_USERNAME: LBL_EMAILUSERNAME,
        FIRSTNAME: LBL_FIRSTNAME,
        LASTNAME: LBL_LASTNAME,
        USE_PRODQA_RECORDS: LBL_USEPRODQARECORDS,
        GENERATED_URL: LBL_GENERATEDURL,
        LOGIN: LBL_LOGIN,
        RESET: LBL_RESET,
        GENERATE_URL: LBL_GENERATE_URL,
        GENERATE_URL_FAILED: LBL_GENERATE_URL_FAILED,
        SELECT_ACCOUNT_FOR_LOGIN: LBL_SELECT_ACCOUNT_FOR_LOGIN
    };

    //component properties

    //array
    fetchedFilteredAccounts = [];
    searchResults = [];
    primaryList = [];
    noPunchoutAccounts = [{
        label:'No Punchout Accounts Found',
        value:'No Punchout Accounts Found'
    }]

    //boolean
    displaySearchResults = false;
    showLoader = false;
    showErrorPane = false;
    isPrimaryListFetched = false;
    
    //strings
    selectedListboxValue = '';
    selectedAccount = '';
    errorMessage = '';
    generatedUrl = '';
    
    //ints
    errorCloseTimeout=10000;
    
    get currentResult(){
        return this.primaryList;
    }

    get generateUrlButtonVisibility(){
        let generateButtonVisible = true;
        if(this.generatedUrl && this.generatedUrl != ''){
            generateButtonVisible = false;
        }

        return generateButtonVisible;
    }

    get sortedFetchedFilteredAccounts(){
        if(this.fetchedFilteredAccounts && this.fetchedFilteredAccounts.length >0){
            this.fetchedFilteredAccounts.sort((a,b) => {
                const labelA = a.label.toUpperCase();
                const labelB = b.label.toUpperCase();
                if(labelA < labelB) {return -1;} 
                if(labelA < labelB) {return 1;}

                return 0; //both are equal
            });
        }
        return this.fetchedFilteredAccounts;
    }

    data_targets = [
        'choosecompany', 
        'username', 
        'firstname',
        'lastname',
        'generatedurl'
    ]

    connectedCallback(){
        this.getPunchoutAccounts();
    }

    getPunchoutAccounts(){
        this.showLoader = true;
        getPunchoutAccounts().then(result => {
            console.log('result', result);//Remove after DEV
            if(result && result.success && result.responseData){
                this.fetchedFilteredAccounts = result.responseData;
                this.showLoader = false;
            } else {
                this.fetchedFilteredAccounts = this.noPunchoutAccounts;
                this.showLoader = false;
            }
        }).catch(err => {
            console.log('err::', err.message);//Remove after DEV
        })
    }

    handleAccountSelected(event){
        console.log('event.target.value:: ', event.target.value);//Remove after DEV
        console.log('event.target.label:: ', event.target.label);//Remove after DEV
        this.refs.generatedurl.value = '';
        this.generatedUrl = '';
        this.selectedAccount = event.target.value;
        this.clearErrorState();//RWPS-7363
    }

    //handle button actions
    handleButtonAction(event){
        let actionName = event.currentTarget.dataset.targetId;
        console.log('actionName::', actionName);//Remove after DEV
        console.log('SYSTEM_CONSTANTS.ACTION_GENERATEURL:: ', this.SYSTEM_CONSTANTS.ACTION_GENERATEURL);//Remove after DEV
        if(actionName == this.SYSTEM_CONSTANTS.ACTION_LOGIN){
            this.handleLoginAction();
        } else if(actionName == this.SYSTEM_CONSTANTS.ACTION_RESET){
            this.handleResetAction();
        } else  if(actionName == this.SYSTEM_CONSTANTS.ACTION_GENERATEURL){
            this.generateLoginUrl();
        }
        
    }

    generateLoginUrl(){
        this.clearErrorState();//RWPS-7363
        this.showLoader = true;
        console.log('generateLoginUrl called', this.selectedAccount );//Remove after DEV

        if(this.selectedAccount ){
            validateTestUser({
                accountId : this.selectedAccount
            }).then(result => {
                console.log('result:: ', result);//Remove after DEV
                if(result && result.success ){
                    console.log('result:: ', result);//Remove after DEV
                    this.proceedToLoginTestUser(result);
                } else {
                    //show error message
                    this.showLoader = false;
                    this.displayErrorMessage(this.system_labels.GENERATE_URL_FAILED);
                }
            }).catch(err =>{
                this.showLoader = false;
                console.log('err:: ', err.message);//Remove after DEV
            })
        } else {
            this.showLoader = false;
            //TODO:display inline toast about missing account
            this.displayErrorMessage(this.system_labels.SELECT_ACCOUNT_FOR_LOGIN);
        }
    }
    
    handleLoginAction(){
        window.open(this.generatedUrl, '_blank');
    }

    proceedToLoginTestUser(responseMap){

        console.log('calloutLoginTestUser:: ', parseJSON(responseMap));//Remove after DEV
        loginTestUser({
            requestMap : responseMap
        }).then(result => {
            console.log('loginTestUser.result:: ', result);//Remove after DEV
            if(result && result.success){
                this.clearErrorState();//RWPS-7363
                this.refs.generatedurl.value = result.responseData;
                this.generatedUrl = result.responseData;
                this.showLoader = false;
            } else {
                this.showLoader = false;
                //todo: show error message
                this.displayErrorMessage(this.system_labels.GENERATE_URL_FAILED);
            }
        }).catch(error => {
            console.log('error:: ', error);//Remove after DEV
        });
    }

    //reset all fields
    handleResetAction(){
        this.refs.selectedAccount.value = ''
        this.selectedAccountNumber = '';
        this.refs.generatedurl.value = '';
        this.generatedUrl = '';   
    }

    displayErrorMessage(message){
        this.showErrorPane = true;
        this.errorMessage= message;
    }

    hanldeMessageAction(event){
        this.showErrorPane = false;
    }
    clearErrorState(){ //RWPS-7363
    this.showErrorPane = false;
    this.errorMessage = '';
    }  
}