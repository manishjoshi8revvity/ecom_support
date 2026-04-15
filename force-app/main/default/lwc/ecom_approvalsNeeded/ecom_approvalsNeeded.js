import { LightningElement, track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getOrderApprovalDetails from "@salesforce/apex/ECOM_OrderController.getOrderApprovalDetails";
import ECOM_OrderPendingForApproval from '@salesforce/label/c.ECOM_OrderPendingForApproval';
import ECOM_OrderApproved from '@salesforce/label/c.ECOM_OrderApproved';
import ECOM_OrderRejected from '@salesforce/label/c.ECOM_OrderRejected';
import ECOM_OrderApprovalNeeded from '@salesforce/label/c.ECOM_OrderApprovalNeeded';
import ECOM_OrderNumber from '@salesforce/label/c.ECOM_OrderNumber';
import ECOM_ApproveOrder from '@salesforce/label/c.ECOM_ApproveOrder';
import ECOM_RejectOrder from '@salesforce/label/c.ECOM_RejectOrder';
import ECOM_ApproveOrderSubHeader from '@salesforce/label/c.ECOM_ApproveOrderSubHeader';
import ECOM_RejectOrderSubHeader from '@salesforce/label/c.ECOM_RejectOrderSubHeader';
import ECOM_ApproveOrderComment from '@salesforce/label/c.ECOM_ApproveOrderComment';
import ECOM_Approval_No_Pending_Review_Orders from '@salesforce/label/c.ECOM_Approval_No_Pending_Review_Orders';
import ECOM_Approval_No_Approved_Orders from '@salesforce/label/c.ECOM_Approval_No_Approved_Orders';
import ECOM_Approval_No_Rejected_Orders from '@salesforce/label/c.ECOM_Approval_No_Rejected_Orders';
import ECOM_ApproveOrderPlaceHolder from '@salesforce/label/c.ECOM_ApproveOrderPlaceHolder';
import ECOM_Cancel from '@salesforce/label/c.ECOM_Cancel';
import ECOM_Approve from '@salesforce/label/c.ECOM_Approve';
import ECOM_Reject from '@salesforce/label/c.ECOM_Reject';
import updateOrderStatus from "@salesforce/apex/ECOM_OrderController.updateOrderStatus";





export default class Ecom_approvalsNeeded extends LightningElement {

    @track
    approvalOrders=[];
    @track
    approvedOrders=[];
    @track
    rejectedOrders=[];

    showSpinner = false;
    
    @track
    ordersToDisplay =[];

    @track
    currentOrders =[];

    isLoadMoreEnabled = false;

    @track tab1class = 'activeTab tab1';
    @track tab2class = 'inactiveTab';
    @track tab3class = 'inactiveTab tab3';

    labels = {
        ECOM_OrderPendingForApproval,
        ECOM_OrderApproved,
        ECOM_OrderRejected,
        ECOM_OrderApprovalNeeded,
        ECOM_OrderNumber,
        ECOM_ApproveOrder,
        ECOM_RejectOrder,
        ECOM_ApproveOrderSubHeader,
        ECOM_RejectOrderSubHeader,
        ECOM_ApproveOrderComment,
        ECOM_ApproveOrderPlaceHolder,
        ECOM_Cancel,
        ECOM_Approve,
        ECOM_Reject,
        ECOM_Approval_No_Pending_Review_Orders,
        ECOM_Approval_No_Approved_Orders,
        ECOM_Approval_No_Rejected_Orders
    };

    currencyDisplayAs='code';

    defaultListSize = 5;
    nextLoadCount = 0;
    fromRecords = 0;
    totalOrders = 0;
    toRecords = 0;
    currentPageNumber = 1;
    selectedTab = 'tab1';
    isTab1Selected = false;
    isTab2Selected = false;
    isTab3Selected = false;

    popUpHeader = '';
    popUpSubText = '';
    popUpText = '';
    popUpPlaceHolder ='';
    popupButtonText = '';
    showPopUp =false;
    disableButton = true;
    approvalRejectionReason ='';

    selectedOrderId ='';

    type ='';
    message = '';
    showError = false;
    timeSpan = 0;

    get isOrdersAvailable(){
        return this.ordersToDisplay.length > 0;
    }

    connectedCallback()
    {
        this.initData();
        this.loadBasedOnDeviceType();
    }

    initData()
    {
        this.showSpinner = true;
        getOrderApprovalDetails()
        .then(result=>{
            if(result.Success) {
                console.log('result::', result);
                this.approvalOrders = result.orderPendingForApproval;
                this.totalOrders = result.orderPendingForApproval.length;
                if(this.totalOrders>0)
                {
                    this.currentOrders = JSON.parse(JSON.stringify(this.approvalOrders));
                    if(this.totalOrders>this.defaultListSize)
                    {
                        this.toRecords = this.defaultListSize;
                        this.nextLoadCount = this.defaultListSize;
                        this.ordersToDisplay = this.currentOrders.slice(0,this.defaultListSize);
                        this.isLoadMoreEnabled = true;
                    }
                    else
                    {
                        this.toRecords = this.totalOrders;
                        this.ordersToDisplay = this.currentOrders;
                    }
                } else {
                    this.toRecords = 0;
                    this.ordersToDisplay = [];
                    this.isLoadMoreEnabled = false; 
                }
                this.approvedOrders = result.approvedOrders;
                this.rejectedOrders=result.rejectedOrders;
                this.isTab1Selected = true;
                this.showSpinner =false;
                /*this.type ='';
                this.message = '';
                this.showError = false;
                this.timeSpan = 0;*/
            }

        }).catch(error=>{
            this.showSpinner = false;
        });
    }

    //Tab UI fix - Gaurang - 19 July 2024
    loadBasedOnDeviceType(){
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
            this.mainSectionCSS = 'slds-grid slds-wrap slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12'
        }
        else{
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-medium-size_1-of-12';
            this.mainSectionCSS = 'slds-grid slds-wrap slds-size_12-of-12 slds-large-size_8-of-12 slds-medium-size_8-of-12 slds-small-size_12-of-12';
        }
    }

    handleTabClick(event) {
        const tabClicked = event.target.dataset.tab;
        this.selectedTab = tabClicked;
        if(this.selectedTab === 'tab1')
        {
            this.tab1class = 'activeTab tab1';
            this.tab2class = 'inactiveTab';
            this.tab3class = 'inactiveTab tab3'
            this.isTab1Selected =true;
            this.isTab2Selected =false;
            this.isTab3Selected =false;
            this.currentOrders = JSON.parse(JSON.stringify(this.approvalOrders));
        }
        else if (this.selectedTab === 'tab2'){
            this.tab1class = 'inactiveTab tab1';
            this.tab2class = 'activeTab';
            this.tab3class = 'inactiveTab tab3'
            this.isTab1Selected =false;
            this.isTab2Selected =true;
            this.isTab3Selected =false;
            this.currentOrders = JSON.parse(JSON.stringify(this.approvedOrders));
        }
        else{
            this.tab1class = 'inactiveTab tab1';
            this.tab2class = 'inactiveTab';
            this.tab3class = 'activeTab tab3'
            this.isTab1Selected =false;
            this.isTab2Selected =false;
            this.isTab3Selected =true;
            this.currentOrders = JSON.parse(JSON.stringify(this.rejectedOrders));
        }
        this.setPaginationValues(this.currentOrders);
    }

    setPaginationValues(listOfOrders)
    {
        this.totalOrders = listOfOrders.length;
        if(this.totalOrders>0)
        {
            if(this.totalOrders>this.defaultListSize)
            {
                this.toRecords = this.defaultListSize;
                this.nextLoadCount = this.defaultListSize;
                this.ordersToDisplay = listOfOrders.slice(0,this.defaultListSize);
                this.currentPageNumber = 1;
                this.isLoadMoreEnabled = true;
            }
            else
            {
                this.toRecords = this.totalOrders;
                this.ordersToDisplay = listOfOrders;
                this.isLoadMoreEnabled = false;
            }
        }
        else
        {
            this.toRecords = 0;
            this.ordersToDisplay = [];
            this.isLoadMoreEnabled = false; 
        }
        this.fromRecords = 0;
    }

    pageChanged(event) {
        let pageNumber = JSON.parse(JSON.stringify(event.detail.pageNumber));
        this.currentPageNumber = parseInt(pageNumber);
        const start = (this.currentPageNumber-1)*this.defaultListSize;
        const end = this.defaultListSize*this.currentPageNumber;
        this.fromRecords = start==0 ? start : start+1;
        this.toRecords = end>this.totalOrders ? this.totalOrders : end ; 
        this.ordersToDisplay = this.currentOrders.slice(start, end);
    }

    handleApproveOrderAction(event)
    {
        this.selectedOrderId = event.currentTarget.dataset.id;
        console.log('this.selectedOrderId : '+this.selectedOrderId);
        this.popUpHeader = ECOM_ApproveOrder;
        this.popUpSubText = ECOM_ApproveOrderSubHeader;
        this.popUpText = ECOM_ApproveOrderComment;
        this.popUpPlaceHolder =ECOM_ApproveOrderPlaceHolder;
        this.popupButtonText = ECOM_Approve;
        this.showPopUp =true;
    }

    handleRejectOrderAction(event)
    {
        this.selectedOrderId = event.currentTarget.dataset.id;
        console.log('this.selectedOrderId : '+this.selectedOrderId);
        this.popUpHeader = ECOM_RejectOrder;
        this.popUpSubText = ECOM_RejectOrderSubHeader;
        this.popUpText = ECOM_ApproveOrderComment;
        this.popUpPlaceHolder =ECOM_ApproveOrderPlaceHolder;
        this.popupButtonText = ECOM_Reject;
        this.showPopUp =true; 
    }

    closePopup(event)
    {
        this.showPopUp = false;
        this.disableButton = true;
        this.approvalRejectionReason ='';
    }

    handleApprovalRejectionReason(event)
    {
        var val = event.target.value;
        this.approvalRejectionReason =val;
        this.disableButton = val?false:true;
    }

    handleApproveRejectOrder(event)
    {
        var status='';
        if(this.popupButtonText == ECOM_Reject)
        {
            status = 'Rejected';
            this.message = 'Order Rejected.';
            this.type='success';
        }
        else if(this.popupButtonText == ECOM_Approve)
        {
            status = 'Approved';
            this.message='Order Approved.'
            this.type='success';
        }
        this.showSpinner = true;
        updateOrderStatus({orderId:this.selectedOrderId,status:status,comments:this.approvalRejectionReason})
        .then(result=>{
            if(result.Success) {
                this.showError = true;
                this.closePopup();
                this.initData();
            } else {
                if(result?.showError == true && result?.message != null){
                    this.message = result.message;
                    this.type = 'error';
                    this.showError = true;
                    this.closePopup();
                    this.initData();
                }
            }
            this.showSpinner = false;
        }).catch(error=>{

        });
        this.showSpinner = true;
    }

}