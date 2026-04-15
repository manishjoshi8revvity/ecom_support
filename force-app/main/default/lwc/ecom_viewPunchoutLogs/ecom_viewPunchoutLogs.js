import { LightningElement,api } from 'lwc';
import LOCALE from "@salesforce/i18n/locale";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//import apex
import getPunchoutLogs from '@salesforce/apex/ECOM_ApplicationLogsController.getLatestPosrPoomLogs';
import getPunchoutLogsForDates from '@salesforce/apex/ECOM_ApplicationLogsController.getLogsForDates';

//import labels
import LBL_ECOM_LOG_VIEWER_HEADER from '@salesforce/label/c.ECOM_LogViewerHeader';//VRa Punchout changes
import LBL_ECOM_SEARCH_SETTINGS from '@salesforce/label/c.ECOM_SearchSettings';//VRa Punchout changes
import LBL_ECOM_VIEW_LOGS from '@salesforce/label/c.ECOM_ViewLogs';//VRa Punchout changes
import LBL_ECOM_LATEST from '@salesforce/label/c.ECOM_Latest';//VRa Punchout changes
import LBL_ECOM_FOR_DATES from '@salesforce/label/c.ECOM_ForDates';//VRa Punchout changes
import LBL_ECOM_SELECT_SEARCH_SETTING from '@salesforce/label/c.ECOM_SelectSearchSetting';//VRa Punchout changes
import LBL_ECOM_SELECT_START_DATE from '@salesforce/label/c.ECOM_SelectStartDate';//VRa Punchout changes
import LBL_ECOM_SELECT_END_DATE from '@salesforce/label/c.ECOM_SelectEndDate';//VRa Punchout changes
import LBL_ECOM_DATE from '@salesforce/label/c.ECOM_Date';//VRa Punchout changes
import LBL_ECOM_LOGIN_NAME from '@salesforce/label/c.ECOM_LoginName';//VRa Punchout changes
import LBL_ECOM_ORGANIZATION_NAME from '@salesforce/label/c.ECOM_OrganizationName';//VRa Punchout changes
import LBL_ECOM_OPERATION_TYPE from '@salesforce/label/c.ECOM_OperationType';//VRa Punchout changes
import LBL_ECOM_REQUEST_DATA from '@salesforce/label/c.ECOM_RequestData';//VRa Punchout changes
import LBL_ECOM_VIEW_DATA from '@salesforce/label/c.ECOM_ViewData';//VRa Punchout changes
import LBL_ECOM_NO_RECORDS_TO_DISPLAY from '@salesforce/label/c.ECOM_NoRecordsToDisplay';//VRa Punchout changes
import LBL_ECOM_ERROR from '@salesforce/label/c.ECOM_Error';//VRa Punchout changes
import LBL_ECOM_START_AND_END_DATES_REQUIRED from '@salesforce/label/c.ECOM_StartAndEndDatesRequired';//VRa Punchout changes
import LBL_ECOM_SEARCH from '@salesforce/label/c.ECOM_Search';//VRa Punchout changes
import LBL_ECOM_STATUS from '@salesforce/label/c.ECOM_LogStatus';//GAr Punchout changes
import LBL_ECOM_REFRESH from '@salesforce/label/c.ECOM_Refresh';

//import modal
import jsonModal from 'c/ecom_viewRequestDataModal';


//js imports
//import { SYSTEM_LABELS, SYSTEM_CONSTANTS, APEX_ACTIONS, parseJSON, stringifyJSON, parseJSONWOStringify } from 'c/ecom_util';


//data table columns
//constants
const SYSTEM_CONSTANTS = {
    ACTION_RESET : 'reset',
    LATEST_500: 'latest_500',
    FOR_DATES: 'for_dates',
}
const columns = [
    { label: LBL_ECOM_DATE, fieldName: 'createdDate',type: 'date',sortable: true,typeAttributes: {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true
    },
        hideDefaultActions: true},
    { label: LBL_ECOM_LOGIN_NAME, fieldName: 'loginUserName', sortable: true,hideDefaultActions: true },
    { label: LBL_ECOM_ORGANIZATION_NAME, fieldName: 'organizationName' , sortable: true, hideDefaultActions: true},
    // { label: 'Transaction Code', fieldName: 'transactionCode' , sortable: true, hideDefaultActions: true},
    { label: LBL_ECOM_OPERATION_TYPE, fieldName: 'logType' , sortable: true, hideDefaultActions: true},
    { label: LBL_ECOM_STATUS, fieldName: 'status' , sortable: true, hideDefaultActions: true},
    { label: LBL_ECOM_REQUEST_DATA, type: 'button', typeAttributes: {
        label: LBL_ECOM_VIEW_DATA,
        disabled: false
    }},
];

const OPTIONS = {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: true
};

export default class Ecom_viewPunchoutLogs extends LightningElement {

    /**Component Properties - begin */
    //apis
    @api recordsToDisplay = 150;
    @api recordsPerPageDefault = '50,100,150,200';

    //objects
    requestData ={};

    //arrays
    primaryFetchedList = [];
    calculatedFetchedList = [];
    currentDataTable=[];
    currentPageData =[]; //TODO: add this to use pagination

    //boolean 
    showLoader = false;
    displayModal = false;
    isInitialPageLoadComplete = false;

    //text
    selectedRadioValue = SYSTEM_CONSTANTS.LATEST_500;
    fromDate = '';
    toDate = '';

    //integer
    currentPage = 0;
    totalRecordCount = 0;
    currentRecordsPerPage = 50;

    //sorting
    sortBy;
    sortDirection;

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    defaultSort(){
        this.sortData('createdDate', 'desc');
    }

    sortData(fieldname, direction) {
        this.currentPage=1;
        let parseData;
        if(this.refs.searchBox.value && this.refs.searchBox.value.length > 0){
            parseData = JSON.parse(JSON.stringify(this.calculatedFetchedList));
        }
        else{
            parseData = JSON.parse(JSON.stringify(this.primaryFetchedList));
        }
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        const start = (this.currentPage-1)*this.recordsToDisplay;
        const end = this.recordsToDisplay*this.currentPage;
        if(this.refs.searchBox.value && this.refs.searchBox.value.length > 0){
            this.calculatedFetchedList = parseData;
            this.currentDataTable = this.calculatedFetchedList.slice(start,end);
        } else {
            this.primaryFetchedList = parseData;
            this.currentDataTable = this.primaryFetchedList.slice(start, end);
        }
    }  

    /**Component Properties - End */

    /**Labels -begin */
    system_labels = {
        LOG_VIEWER_HEADER: LBL_ECOM_LOG_VIEWER_HEADER,
        SEARCH_SETTINGS: LBL_ECOM_SEARCH_SETTINGS,
        VIEW_LOGS: LBL_ECOM_VIEW_LOGS,
        FOR_DATES: LBL_ECOM_FOR_DATES,
        LATEST: LBL_ECOM_LATEST,
        SELECT_SEARCH_SETTING: LBL_ECOM_SELECT_SEARCH_SETTING,
        SELECT_START_DATE: LBL_ECOM_SELECT_START_DATE,
        SELECT_END_DATE: LBL_ECOM_SELECT_END_DATE,
        DATE: LBL_ECOM_DATE,
        SEARCH: LBL_ECOM_SEARCH,
        NO_RECORDS_TO_DISPLAY: LBL_ECOM_NO_RECORDS_TO_DISPLAY,
        LBL_ERROR: LBL_ECOM_ERROR,
        START_AND_END_DATES_REQUIRED: LBL_ECOM_START_AND_END_DATES_REQUIRED,
        REFRESH: LBL_ECOM_REFRESH
    };
    /**Labels -end */

    /** Getters setters - begin*/
    get isLogsAvailable(){
        let isAvaiable = false;
        if(this.primaryFetchedList && this.primaryFetchedList.length>0){
            isAvaiable = true;
        }
        return isAvaiable;
    }

    get radioOptions(){
        return [
            {label: this.system_labels.LATEST, value: SYSTEM_CONSTANTS.LATEST_500},
            {label: this.system_labels.FOR_DATES, value: SYSTEM_CONSTANTS.FOR_DATES},
        ]
    }

    get isDisplayDateFields(){
        let displayFields = false;
        if(this.selectedRadioValue == SYSTEM_CONSTANTS.FOR_DATES){
            displayFields = true;
        }
        return displayFields;
    }

    get dataTableColumns(){
        return columns;
    }

    get currentDataTableData(){
        return this.currentDataTable;
    }

    get isDisplayNoRecords(){
        let displayMessage = false;
        if((!this.currentDataTable || this.currentDataTable.length <= 0) && this.isInitialPageLoadComplete){
            displayMessage= true;
        }
        return displayMessage;
    }

    get showPagination(){
        let isShowPagination = false;
        if(this.totalRecordCount>0 && this.totalRecordCount > parseInt(this.recordsToDisplay)){
            isShowPagination = true;
        }

        return isShowPagination;
    }

    get pageOptions(){
        let currPageOptions = this.recordsPerPageDefault.split(',');
        let parsedPageOptions = [];
        if(currPageOptions && currPageOptions.length > 0){
            currPageOptions.forEach(item => {
                const record = {'label':item, 'value':item};
                parsedPageOptions.push(record);
            })
        }
        //console.log('parsedPageOptions',parsedPageOptions);//Remove after DEV
        return parsedPageOptions;
    }

    /** Getters setters - end */

    connectedCallback(){
        //let currPageOptions = this.recordsPerPageDefault.split(',');
        this.fetchLatestLogs();
        //this.handleCustomPagination();
    }

    /**Custom functions - begin */

    //fetch logs 
    fetchLatestLogs(){
        this.showLoader = true;
        getPunchoutLogs().then(result => {
            
            if(result && result?.success && result?.responseData && result?.responseData?.length >1){
                this.primaryFetchedList = result?.responseData;
                this.totalRecordCount=this.primaryFetchedList.length;
                
                this.currentDataTable = this?.primaryFetchedList;
                this.calculatedFetchedList = this.primaryFetchedList;
                
                this.isInitialPageLoadComplete = true;
                this.handleCustomPagination(null);
                this.defaultSort();
                this.showLoader = false;
                
            } else {
                //handle no logs
                this.showLoader = false;
            }
        }).catch(err => {
            this.showLoader = false;
            //console.log('err:: ', err.message);//Remove after DEV
        })
    }

    //refresh list of logs
    refreshLogs(){
        this.fetchLatestLogs();
    }

    //search logs for dates
    searchLogs(){
        this.showLoader = true;
        this.fromDate = this.refs.from_date.value;
        this.toDate = this.refs.to_date.value;
        
        try{
            if(this.fromDate == '' && this.toDate == ''){
                this.displayToast(this.system_labels.LBL_ERROR,this.system_labels.LBL_ERROR.toLowerCase(), this.system_labels.START_AND_END_DATES_REQUIRED);
                this.showLoader=false;
                return;
            }
        }catch(err){
            //do not console log
        }
        
        getPunchoutLogsForDates({
            fromDate: this.fromDate,
            toDate: this.toDate
        }).then(result => {
            
            if(result && result.success && result.responseData && result.responseData.length > 0){
                this.currentPage=1;
                this.primaryFetchedList = result.responseData;
                this.totalRecordCount=this.primaryFetchedList.length;
                const start = (this.currentPage-1)*this.recordsToDisplay;
                const end = this.recordsToDisplay*this.currentPage;
                this.currentDataTable = this.primaryFetchedList.slice(start, end);
                //show toast or message
                this.showLoader = false;
            } else {
                this.primaryFetchedList = [];
                this.totalRecordCount=0;
                this.currentDataTable=[];
                //show toast or message
                this.showLoader = false;
            }
        }).catch(err =>{
            this.showLoader = false;
        })
    }


    //handle search type change
    handleSearchFilter(event){
        this.currentPage=1;
        const searchValue = String(event.target.value).toLowerCase();
        let filteredData =[];
        if(searchValue && searchValue != ''){
            this.primaryFetchedList.forEach(x => {
                const newDateStr = new Date(x.createdDate).toLocaleString(LOCALE, OPTIONS);
                if(x && x.logType && x.logType.toLowerCase().includes(searchValue) ||
                (newDateStr && newDateStr.toLowerCase().includes(searchValue)) ||
                (x && x.organizationName && x.organizationName.toLowerCase().includes(searchValue)) ||
                (x && x.loginUserName && x.loginUserName.toLowerCase().includes(searchValue)) ||
                (x && x.status && x.status.toLowerCase().includes(searchValue))
                ){
                    filteredData.push(x);
                }
            });
            filteredData = [... new Set(filteredData)];
        } else {
            filteredData = this.primaryFetchedList;
        }
        this.currentDataTable = filteredData;
        if(this.currentDataTable && this.currentDataTable.length>0){
            this.totalRecordCount = this.currentDataTable.length;
            this.calculatedFetchedList = this.currentDataTable;
            this.handleCustomPagination(null);
        } else {
            this.totalRecordCount = 0;
            this.calculatedFetchedList = [];
        }
    }


    //handle search setting change
    handleSearchChange(event){
        let currValue = event.target.value;
        this.selectedRadioValue = currValue;
        if(this.selectedRadioValue==SYSTEM_CONSTANTS.LATEST_500){
            this.currentPage=1;
            this.fetchLatestLogs();
        }
    }

    openJsonDataModal(event){
        try{
            let rowId = event.detail.row.logId;
            let rowData = this.currentDataTable.find(x => x.logId == event.detail.row.logId);
            if(rowData.logType == 'POOM Response'){
                jsonModal.open({
                    size: 'large',
                    content: rowData.supportData,
                    modalHeading: rowData.logType,
                    cxml: true
                }); 
            }
            else{
                jsonModal.open({
                    size: 'large',
                    content: rowData.supportData,
                    modalHeading: rowData.logType,
                    cxml: false
                }); 
            }
        }catch(err){
            
        }
    }

    displayToast(title,type,message){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(evt);
    }


    //handle custom pagination

    customPageNumber(event){
        let pageNumber = JSON.parse(JSON.stringify(event.detail.pageNumber));

    }

    handleCustomPagination(event){
        let pageNumber = this.currentPage > 0 ? this.currentPage : 1;
        if(event && event.detail && event.detail.pageNumber){
            pageNumber = parseInt(event.detail.pageNumber);
        }
        this.currentPage = parseInt(pageNumber);
        const start = (this.currentPage-1)*this.recordsToDisplay;
        const end = this.recordsToDisplay*this.currentPage;
        
        if(this.refs.searchBox.value && this.refs.searchBox.value.length > 0){
            this.currentDataTable = this.calculatedFetchedList.slice(start,end);
        } else {
            this.currentDataTable = this.primaryFetchedList.slice(start, end);
        }
        
    }

    handleNumberOfRecordsChange(event){
        this.recordsToDisplay = event.target.value;
    }

    /**Custom functions - end */
}