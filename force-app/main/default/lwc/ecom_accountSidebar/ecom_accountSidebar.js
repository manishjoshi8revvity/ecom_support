import { LightningElement, api, track, wire } from 'lwc';
import { publish,MessageContext, createMessageContext} from 'lightning/messageService';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';
import DASHBOARD_NAVIGATE_TO from '@salesforce/messageChannel/Dashboard__c';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import getApprovalCount  from '@salesforce/apex/ECOM_OrderController.getApprovalCount';
import siteId from "@salesforce/site/Id";//VRa 8 Jul 24 logout rework
import getHomeUrl from '@salesforce/apex/ECOM_CustomLoginController.getCMSUrl';//VRa 8 Jul 24 logout rework
import checkIfCurrentUserIsPunchoutUser from '@salesforce/apex/ECOM_OrderHistoryController.checkIfCurrentUserIsPunchoutUser'; // RWPS-4196

//label imports
import ECOM_140004  from '@salesforce/label/c.ECOM_140004';
import ECOM_OrderApprovalNeeded  from '@salesforce/label/c.ECOM_OrderApprovalNeeded';
import ECOM_DownloadPDF from '@salesforce/label/c.ECOM_DownloadPDF';
import ECOM_ClickHere from '@salesforce/label/c.ECOM_ClickHere';

//jsimports
import { getUserConfigData,setToSessionStorage, getFromSessionStorage, SYSTEM_CONSTANTS , SYSTEM_LABELS, stringifyJSON, parseJSON} from 'c/ecom_punchoutUtil';

// RWPS-592 Begin
import {getCDLId, logoutUserAndRedirect} from 'c/ecom_util';
// RWPS-592 End
//RWPS-4759 - Start
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import Dealer_Type__c from '@salesforce/schema/User.Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Dealer_Type__c'; //RWPS-4759
//RWPS-4759 - End

const NAVIGATE_TO_CONTACTUS = 'ContactUs';
const CMS_NAVIGATION = 'CMSNavigation';
const PREFERRED_LANGUAGE_PREFIX = 'PreferredLanguage'; //VRa 8 Jul 24 logout rework
const STORED_LOCALE = 'storedLocale'; //VRa 8 Jul 24 logout rework
const DEALER_IDENTIFIER = '10. ECOM'; //RWPS-4759
export default class Ecom_accountSidebar extends NavigationMixin(LightningElement) {
    @track selectedValue = '';
    @track selectedLabel = '';

    //ECOM-112 - garora@rafter.one - 12 May 2024 - to set any change in value from parent cmps - starts
    @api
    set parentLabel(val){
        this._selectedLabel = val;
        this.selectedLabel = this.parentLabel;
    }
    
    get parentLabel(){
        return this._selectedLabel;
    }
    //ECOM-112 - garora@rafter.one - 12 May 2024 - to set any change in value from parent cmps - starts
    isPunchoutUser = false;//VRa: punchout changes
    isInitialPageLoad = true;//VRa: punchout changes
    customerCareModal = false//GAr: punchout changes

    userNavigationConfig={}//VRa: punchout changes

    isRedirectUrl = false;
    isRenderCallbackExecuted = false;
    images = {
        dashboard:sres_ECOM_CartIcons + '/img/dashboard.png',
        logout:sres_ECOM_CartIcons + '/img/logout.png',
        back:sres_ECOM_CartIcons+'/img/back.png',
        activedashboard: sres_ECOM_CartIcons+'/img/activedashboard.png'
    }

    _options;

    system_labels = SYSTEM_LABELS//VRa: punchout changes
    @wire(MessageContext)
    messageContext;

    @track isDealer = false //RWPS-4759

    //RWPS-4759 START
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [Dealer_Type__c]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error ;
        } else if (data) {
            this.isDealer = data?.fields?.Contact?.value?.fields?.Default_Ship_to_ERP_Address__r?.value?.fields?.Master_Address__r?.value?.fields?.Dealer_Type__c.value === DEALER_IDENTIFIER ? true : false ; //RWPS-4759
        }
    }
    //RWPS-4759 END

    showOrderApproval = false;
    device = {
        isMobile : FORM_FACTOR==='Small' || FORM_FACTOR==='Medium',
        isDesktop : FORM_FACTOR==='Large'
    }
    @track
    dashboardImg = this.images.activedashboard;
    context = createMessageContext();
    contentDocumentMap;
    renderSideBar = false; // RWPS-4196

    //VRa: Punchout changes - Begin
    get options() {
    let conditionalOptions = [];
        if(this.userNavigationConfig){
            conditionalOptions.push({ label: 'Dashboard', value: 'dashboard' });
            if(this.userNavigationConfig['viewProfileSettingPage']) {conditionalOptions.push({ label: 'Profile & Settings', value: 'profileandsettings' })};
            if(this.userNavigationConfig['viewAccountPage']) conditionalOptions.push({ label: 'Accounts', value: 'accounts' });
            conditionalOptions.push({ label: 'Orders', value: 'orders' });
            conditionalOptions.push({ label: 'Favorites', value: 'favorites' });
            if(this.userNavigationConfig['viewFrequentlyPurchased']) conditionalOptions.push({ label: 'Frequently Purchased', value: 'frequentlyPurchased' });
            if(this.userNavigationConfig['viewQuickOrder']) conditionalOptions.push({ label: 'Quick Order', value: 'quickorder' });
            conditionalOptions.push({ label: 'Customer Care', value: 'contactus' });
            if(this.userNavigationConfig['viewLogout']) conditionalOptions.push({ label: 'Logout', value: 'logout' });
        } else {
            conditionalOptions = [
                { label: 'Dashboard', value: 'dashboard' },
                { label: 'Profile & Settings', value: 'profileandsettings' },
                { label: 'Accounts', value: 'accounts' },
                { label: 'Orders', value: 'orders' },
                { label: 'Favorites', value: 'favorites' },
                { label: 'Quick Order', value: 'quickorder' },
                { label: 'Customer Care', value: 'contactus' },
                { label: 'Logout', value: 'logout' },
    
            ];
        }
        if(this.showOrderApproval)
        {
            // Note : update index if new option added before approvalNeeded
            conditionalOptions.splice(4, 0, { label: this.labels.ECOM_OrderApprovalNeeded,value:'approvalNeeded'});
        }
        return conditionalOptions;
    }

    set options(value)
    {
        this._options = value;
    }

    labels = {
        ECOM_140004,
        ECOM_OrderApprovalNeeded,
        ECOM_DownloadPDF,
        ECOM_ClickHere
    };

    get isViewProfileAndSetting(){
        let isView = true;
        if(this.userNavigationConfig){
            isView = this.userNavigationConfig['viewProfileSettingPage'];
        }
        return isView;
    }

    get isViewAccount(){
        let isView = true;
        if(this.userNavigationConfig){
            isView = this.userNavigationConfig['viewAccountPage'];
        }
        return isView;
    }

    get isViewFrequentlyPurchased(){
        let isView = true;
        if(this.userNavigationConfig){
            isView = this.userNavigationConfig['viewFrequentlyPurchased'];
        }
        return isView;
    }

    get isViewQuickOrder(){
        let isView = true;
        if(this.userNavigationConfig){
            isView = this.userNavigationConfig['viewQuickOrder'];
        }
        return isView;
    }

    get isViewFrequentlyPurchasedProducts(){
        let isView = true;
        if(this.userNavigationConfig){
            isView = this.userNavigationConfig['viewFrequentlyPurchased'];
        }
        return isView;
    }

    get isViewLogout(){
        let isView = true;
        if(this.userNavigationConfig){
            isView = this.userNavigationConfig['viewLogout'];
        }
        return isView;
    }

    get orderLabelStyling(){
        let applyStyingString = 'ecom-account-sb-label dashboard-menu-font no-underline sidebar-link';//RWPS-3764
        if(this.checkUserNavigationFlag('viewOrderPage') && this.checkUserNavigationFlag('isPunchoutUser')){
            applyStyingString = 'ecom-sidebar-label dashboard-menu-font no-underline sidebar-link';//RWPS-3764
        }
        return applyStyingString;
    }

    get customerCareStyling(){
        let applyStyingString = 'ecom-pt-32 ecom-pb-32 ecom-gray-border-t ecom-full-width';
        if(this.checkUserNavigationFlag('isPunchoutUser')){
            applyStyingString = 'ecom-pt-32 ecom-gray-border-t ecom-full-width';
        }
        return applyStyingString;
    }

    checkUserNavigationFlag(parameter){
        let flag = true;
        if(this.userNavigationConfig){
            flag = this.userNavigationConfig[parameter];
        }
        return flag;
    }

    //VRa: Punchout changes - end

    get pageMapping(){
        return [
            {name:'Dashboard__c',value: 'dashboard',state:''},
            {name:'Profile_and_Settings__c',value: 'profileandsettings' ,state:''},
            { name:'Dashboard__c',value: 'accounts' ,state:'accountEdit'},
            { name:'Order_History__c',value: 'orders' ,state:''},
            { name:'Favorites__c',value: 'favorites' ,state:''},
            {name:'QuickOrder__c',value: 'quickorder',state:''},
            {name:'approvalNeeded__c',value: 'approvalNeeded',state:''}
        ] ;
    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            let pageName = currentPageReference?.attributes?.name;
            let accountEdit = currentPageReference?.state?.accountEdit===null ? 'accountEdit' :'';
            const selectedOption = this.pageMapping.find(opt => opt.name === pageName && opt.state ===accountEdit);
            this.selectedLabel =  selectedOption?.value || this.selectedLabel  || ''; //ECOM-112 - garora@rafter.one - 12 May 2024 - added this.selectedLabel to prevent override of value from parent
        }
    }
    // Handle the selection change event
    handleSelectionChange(event) {
        this.selectedValue = event.detail.value;

        // Find the selected option and set the selected label
        const selectedOption = this.options.find(opt => opt.value === this.selectedValue);
        this.selectedLabel = selectedOption ? selectedOption.label : '';

        // Redirect based on the selected value
        switch (this.selectedValue) {
            case 'dashboard':
                this.handleDashboardClick();
                break;
            case 'profileandsettings':
                this.onProfileAndSettings();
                break;
            case 'accounts':
                this.handleAccountClick();
                break;
            case 'orders':
                this.handleRecentOrderClick();
                break;
            case 'approvalNeeded':
                this.handleApprovalNeeded();
                break;
            case 'favorites':
                this.handleFavoritesClick();
                break;
            //VRa: punchout changes - begin
            case 'frequentlyPurchased':
                this.handleFrequentlyPurchasedClick();
                break;
            //VRa: punchout changes - End
            case 'quickorder':
                this.handleQuickOrderClick();
                break;  
            case 'contactus':
                this.navigateToContactUsPage();
                break;     
            case 'logout':
                this.handleLogout();
                break;  
            default:
                break;
        }
    }
    handleDashboardClick(event){
        if(this.isRedirectUrl){
            this.restrictUserToNavigate();
            return;
        }
        let url = window.location.href;
        let baseUrl =  url.split('/');
        let finalUrl = baseUrl[0]+'/dashboard';
        window.location.href = finalUrl;
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleLogout(){

        //VRa 8 Jul 24 logout rework:begin
        let logoutDelay = 1000;

        getHomeUrl().then(result => {

            if(result && result.success){
                let logoutUrl = window.location.origin + '/secur/logout.jsp';
                logoutUserAndRedirect(logoutDelay, logoutUrl, result.responseData.Logout, PREFERRED_LANGUAGE_PREFIX + siteId, STORED_LOCALE);
            }
        }).catch(error => {
        })
        //VRa 8 Jul 24 logout rework:end
    }
    connectedCallback(){

        // RWPS-4196 - START
        checkIfCurrentUserIsPunchoutUser({
        }).then((userResult) => {

            // RWPS-4196 - Moved the existing logic to run after the checkIfCurrentUserIsPunchoutUser is executed.
            let userConfig = getUserConfigData();
            this.loadBasedOnDeviceType();
            if(userConfig){
                this.userNavigationConfig = userConfig;
                this.isPunchoutUser = this.userNavigationConfig['isPunchoutUser'];
                this.renderSideBar = true; // RWPS-4196
            }
            //VRa - Punchout changes 1.5 Feb 8 : Phase 2.0 TODO. These configurations needs to be pulled from metadata after login architecture rework
            else { 

                // RWPS-4196 - If userConfig is empty check and see if user is punchout user or web user from the server call response.
                this.setAttributesForUserConfig(userResult, userConfig);
                this.renderSideBar = true; // RWPS-4196
            }
            //VRa - Punchout changes 1.5 Feb 8 : End

            this.dashboardImg=this.images.activedashboard;

            if(this.template.querySelector("span[data-id='dashboard']")){
                this.dashboardImg=this.images.activedashboard;
            }
            if(this.template.querySelector("div[data-id='accounts']")){
                this.dashboardImg=this.images.dashboard;
            }
            this.areOrderApprovalsNeeded();
            this.getUrlParams();
            // RWPS-592 calls submethod to get content document link map
            this.getContentDocumentLinkId(); 
        }).catch((error) => {
            console.error(error);
        });
        // RWPS-4196 - END
    }

    // RWPS-4196 - Method responsible for setting up the userNavigationConfig variables
    setAttributesForUserConfig(userResult, userConfig) {
        if (userResult) {
            userConfig = {
                viewProfileSettingPage: false,
                viewDashboard: false,
                viewAccountPage: false,
                viewOrderPage: true,
                viewRecentOrders: false,
                viewFavourites: true,
                viewFrequentlyPurchased: true,
                viewQuickOrder: true,
                viewLogout: false,
                storeForwardingUrl: '/createsession',
                isPunchoutUser: true
            }
            this.isPunchoutUser = true;
            this.userNavigationConfig = userConfig;
        } else {
            userConfig = {
                viewProfileSettingPage: true,
                viewDashboard: true,
                viewAccountPage: true,
                viewOrderPage: true,
                viewRecentOrders: true,
                viewFavourites: true,
                viewFrequentlyPurchased: false,
                viewQuickOrder: true,
                viewLogout: true,
                storeForwardingUrl: ''
            }
            this.isPunchoutUser = false;
            this.userNavigationConfig = userConfig;
        }
    }

    //Tab UI fix - Gaurang - 17 July 2024
    loadBasedOnDeviceType(){
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if(FORM_FACTOR=='Medium' || width==1025){
            this.device.isMobile = true;
            this.device.isDesktop = false;
        }
    }

    areOrderApprovalsNeeded()
    {
        getApprovalCount()
        .then(result=>{
            if(result.Success && result.orderCount>0)
            {
                this.showOrderApproval = true;
                if(window.location.href.indexOf("approvalNeeded") > -1){
                    this.selectedLabel = this.labels.ECOM_OrderApprovalNeeded;
                    this.publishPageViewEvent(this.labels.ECOM_OrderApprovalNeeded);
                }
                this._options = [];
                if(window.location.href.indexOf("approvalNeeded") > -1){
                    let comRef = this;
                    setTimeout(() => {
                        comRef.template.querySelector("div[data-id='approvalNeeded']")?.classList?.add("ecom-brand-font");
                        //comRef.template.querySelector("div[data-id='approvalNeeded']")?.classList?.remove("ecom-brand-font");
                        comRef.dashboardImg=this.images.dashboard;
                        comRef.publishPageViewEvent('approvalNeeded');
                    }, 300);
                }
            }
            else
            {
                this.showOrderApproval = false;
            }
        }).catch(error=>{
            this.showOrderApproval = false;

        });
    }

    getUrlParams(){
        if(window.location.href.includes("?")){
            let params;
            params = window.location.href.split("?")[1];
            if(params.includes('&')){
                let paramValues = params.split('&');
                this.redirectUrls(paramValues);
            }
        }
    }

    redirectUrls(paramValues){
        for(let param of paramValues){
            if(param.includes('url')){
                this.isRedirectUrl = true;
            }
        }
    }

    onProfileAndSettings(event){
        if(this.isRedirectUrl){
            this.restrictUserToNavigate();
            return;
        }
       const payload = { 
            navigate: 'profile_settings'
        };
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/profile-and-settings` 
            },
        });
        publish(this.context, DASHBOARD_NAVIGATE_TO, payload);
    }

    handleRecentOrderClick(event){
        if(event){
            event.target.classList.add("ecom-brand-font");
        }
        if(this.isRedirectUrl){
            this.restrictUserToNavigate();
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/orderHistory` 
            },
        });
    }

    handleFavoritesClick(){
        if(this.isRedirectUrl){
            this.restrictUserToNavigate();
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/favorites'
            },
        });
    }

    handleApprovalNeeded(){
        if(this.isRedirectUrl){
            this.restrictUserToNavigate();
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/approvalNeeded'
            },
        });
    }

    handleAccountClick(){
        let url = window.location.href;
        let baseUrl =  url.split('/');
        let finalUrl = baseUrl[0]+'/dashboard?accountEdit';
        window.location.href = finalUrl;

    }

    handleFrequentlyPurchasedClick(){
        const payload = { 
            navigate: 'frequentlyPurchased'
        };
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/frequentlyPurchased'
            },
        });
        publish(this.context, DASHBOARD_NAVIGATE_TO, payload);
    }

    handleQuickOrderClick(){
        if(this.isRedirectUrl){
            this.restrictUserToNavigate();
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/quickorder'
            },
        });
    }
    
    renderedCallback(){
        if (this.isRenderCallbackExecuted){
            return;
        }
        this.isRenderCallbackExecuted = true;
    
        if(this.device.isDesktop){
            //RWPS-3764 start
            const path = window.location.href;
        
            const links = this.template.querySelectorAll('[data-id]');
            links.forEach(link => link.classList.remove('ecom-brand-font'));
        
            let highlightId;
        
            if (path.includes('dashboard?accountEdit') || path.includes('accountEdit')) {
                highlightId = 'accounts';
                this.publishPageViewEvent('Accounts');
            } else if (path.includes('profile-and-settings')) {
                highlightId = 'profile';
                this.publishPageViewEvent('Profile And Settings');
            } else if (path.includes('orderHistory')) {
                highlightId = 'orders';
                this.publishPageViewEvent('Order History');
            } else if (path.includes('favorites')) {
                highlightId = 'fav';
                this.publishPageViewEvent('Favorites');
            } else if (path.includes('quickorder')) {
                highlightId = 'quickorders';
                this.publishPageViewEvent('Quick Order');
            } else if (path.includes('frequentlyPurchased')) {
                highlightId = 'frequentlypurchased';
                this.publishPageViewEvent('Frequently Purchased');
            } else if (path.includes('approvalNeeded')) {
                highlightId = 'approvalNeeded';
                this.publishPageViewEvent('Order Approval Needed');
            } else if (path.includes('dashboard')) {
                highlightId = 'dashboard';
                this.publishPageViewEvent('Dashboard');
            }
        
            if (highlightId) {
                const activeLink = this.template.querySelector(`[data-id="${highlightId}"]`);
                activeLink?.classList.add('ecom-brand-font');
            }
        
            this.dashboardImg = ['dashboard', 'accountEdit'].some(key => path.includes(key))
                ? (highlightId === 'dashboard' ? this.images.activedashboard : this.images.dashboard)
                : this.images.dashboard;
            //RWPS-3764  end             

        }
        if(this.device.isMobile){
            if(window.location.href.indexOf("dashboard") > -1 && !(window.location.href.indexOf("dashboard?accountEdit") > -1)){
                this.selectedLabel = "Dashboard"
                this.publishPageViewEvent('Dashboard');
            }
            if(window.location.href.indexOf("profile-and-settings") > -1){
                this.selectedLabel = "Profile & Settings"
                this.publishPageViewEvent('Profile And Settings');
            }
            if(window.location.href.indexOf("orderHistory") > -1){
                this.selectedLabel = "Orders"
                this.publishPageViewEvent('Order History');
            }
            if(window.location.href.indexOf("favorites") > -1){
                this.selectedLabel = "Favorites"
                this.publishPageViewEvent('Favorites');
            }
            if(window.location.href.indexOf("quickorder") > -1){
                this.selectedLabel = "Quick Order"
                this.publishPageViewEvent('Quick Order');
            }
            if(window.location.href.indexOf("dashboard?accountEdit") > -1){
                this.selectedLabel = "Accounts"
                this.publishPageViewEvent('Accounts');
            }
            if(window.location.href.indexOf("frequentlyPurchased") > -1){
                this.selectedLabel = "Frequently Purchased"
                this.publishPageViewEvent('Frequently Purchased');
            }
            if(window.location.href.indexOf("approvalNeeded") > -1){
                this.selectedLabel = this.labels.ECOM_OrderApprovalNeeded;
                this.publishPageViewEvent(this.labels.ECOM_OrderApprovalNeeded);
            }
        }
    }

    restrictUserToNavigate(){
        const payload = { 
            navigate: 'isNewUser'
        };
        publish(this.context, DASHBOARD_NAVIGATE_TO, payload)
        return;
    }

    navigateToContactUsPage(){
        if(this.checkUserNavigationFlag('isPunchoutUser')){
            this.customerCareModal=true;
        }
        else{
            let payLoad = {message: NAVIGATE_TO_CONTACTUS,
                type: CMS_NAVIGATION,
                partNumber:'',
                url:''
            };
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        }
    }

    closeCCModal(){
        this.customerCareModal=false;
    }

    publishPageViewEvent(tab) {
    //gtm file take time to load from static resource
        let comRef = this;
        setTimeout(() => {
            let payLoad = {
                data  : {
                    tabView : tab,
                    event:'Pageview',
                    page:'My Account',
                },
                type: 'DataLayer',
                page:'My Account',
            };
            publish(comRef.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
        }, 1500);

    }

    // <!-- RWPS-592 Begin-->
    handlePDFDownload(event){
        this.openPDF();
    }
    openPDF(){
        if(this.contentDocumentMap!==undefined && 
                this.contentDocumentMap['contentDocumentId']!==undefined){
            let storeUrl = this.contentDocumentMap['orgUrl'];
            let slug = '/sfc/servlet.shepherd/document/download/'
            let outer = '?operationContext=S1'
            let url = storeUrl  + slug + this.contentDocumentMap['contentDocumentId'] + outer;
            if(this.contentDocumentMap['contentDocumentId']!==undefined)
            {
                 window.open(url, '_blank').focus();
            }
            else{
                this.template.querySelector('c-ecom_show-Toast').showToast('Not available', 'error');
            }
        }
    }

    get isCDLAvailable(){
        let available = false;
        if(this.contentDocumentMap!==undefined && this.contentDocumentMap['contentDocumentId']!==undefined){
            available = true;
        }
        return available;
    }
    // fetch content document link map
    getContentDocumentLinkId(){
        getCDLId()
        .then((result)=>
        {
            this.contentDocumentMap = result;       
        })
    }
    // <!-- RWPS-592 End-->
}