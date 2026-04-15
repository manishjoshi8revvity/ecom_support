import { LightningElement ,api,track} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
// import getunpivotresult from '@salesforce/apex/UTIL_unpivot_soql.fetch_unpivot_soql';
import getsoqlresult from '@salesforce/apex/UTIL_unpivot_soql.fetch_data';
const columns = [
    {
        label: 'Entity',
        fieldName: 'Entity',
        type: 'text',
        sortable: true
    },
    {
        label: 'Attribute',
        fieldName: 'Attribute',
        type: 'text',
        sortable: true
    },
    {
        label: 'Value',
        fieldName: 'Value',
        type: 'text',
        sortable: true
    }
];
export default class Lwc_unpivot_soql extends LightningElement {
    @track columns = columns;
    @track options=[{'label':'--None-','value':null},{'label':'Entity','value':'Entity'},{'label':'Attribute','value':'Attribute'},{'label':'Value','value':'Value'}];
    @track error;
    value = '';
    @track initialdata;
    @track fetcheddatasize=0;
    @track unpivottablesize=0;
    @track searchKey='';
    @track selectedobj;
    @api groupfieldapi='No field Provided';
    @api soqlstring='No SOQL Provided';
    @api tablelabel='Unpivot Table';
    @track unpivotresult;
    @track sortBy;
    @track sortDirection;
    @track isLoaded=true;
    _debounceTimer;
    previousvalues='';
    _title = "Sample Title";
    message = "Sample Message";
    variant = "error";
    get reactiveValue() { 
        // * Return reactive attributes as a string to be used in tracking
        return JSON.stringify(this.soqlstring) + JSON.stringify(this.groupfieldapi) ;
    }
    handleChange(event){
      //  this.searchvalue = event.target.value;
      this._debounceHandler();

     }
     showNotification() {
      const evt = new ShowToastEvent({
        title: this._title,
        message: this.message,
        variant: this.variant,
      });
      console.log(JSON.stringify(evt));
      this.dispatchEvent(evt);
    }
     // Debounce the processing of the reactive changes
 _debounceHandler() {
    this._debounceTimer && clearTimeout(this._debounceTimer);
    if (this.reactiveValue){
        this._debounceTimer = setTimeout(() => this.__callsyncmethod(), 300);
    }    
 }
 handleChange(event){
    this.previousvalues=this.reactiveValue;
   this.unpivotresult=this.initialdata;
    this.selectedobj =event.target.value;
    console.log('selectedobj',selectedobj);
 //   let selectedoption = this.options.filter(k => k.value==selectedobj);
   
 }
 handleBlur(event){
    this.previousvalues=this.reactiveValue;
   this.unpivotresult=this.initialdata;
    let searchstring=event.target.value;
    this.unpivotresult = this.unpivotresult.filter(o => Object.keys(o).some(k => k.toLowerCase() == this.selectedobj.toLowerCase() &&  o[k].toString().toLowerCase().includes(searchstring.toLowerCase())));
  
 }
   // On rendering, check for a value or change in value of reactive attribute(s) and execute the handler
   renderedCallback() {
    console.log('render call');
    
       if (this.reactiveValue && this.reactiveValue != this.previousvalues) {
         //  this._callsyncmethod();
         this.fetchSoqlrecords();
       }
   }
   fetchSoqlrecords(){
    getsoqlresult({group_field: this.groupfieldapi ,query_String: this.soqlstring})
    .then((result) => {
        const out  = result.sObject_List.map( obj => Object.entries(obj).map(([k, v]) => {
            if(k != result.group_field)
            return ({'Entity':obj[result.group_field], 'Attribute' :k, 'Value': v });}));
        
   //  console.log(JSON.stringify(out.flat().filter(x => x)));
   
      this.unpivotresult=out.flat().filter(x => x);
      this.initialdata=this.unpivotresult;
      this.fetcheddatasize=result.sObject_List.length;
      this.unpivottablesize=this.unpivotresult.length; 
     // this.tablelabel =this.tablelabel +'Total : ('+this.unpivottablesize+ ') From Fetched Rows: ('+ this.fetcheddatasize +')'; 
     // console.log(JSON.stringify(result));
      this.isLoaded=false;
      this.previousvalues=this.reactiveValue;
      this.error=undefined;
    })
    .catch((error) =>{
      console.log('Error');
      this.unpivotresult=undefined;
      this.error=error;
      this.isLoaded=false;
      this.previousvalues=this.reactiveValue;
        this.title='Error';
        this.message='Error while fetching data:'+error;
        this.variant='error';
      this.showNotification();
    })
   // this.dispatchEvent(new FlowAttributeChangeEvent('totalnumber', JSON.stringify(this.totalnumber)));
 }
 /*_callsyncmethod(){
    getunpivotresult({group_field: this.groupfieldapi ,query_String: this.soqlstring})
    .then((result) => {
      this.unpivotresult=result;
      this.initialdata=result;
     // console.log(JSON.stringify(result));
      this.isLoaded=false;
      this.previousvalues=this.reactiveValue;
      this.error=undefined;
    })
    .catch((error) =>{
      console.log('Error');
      this.unpivotresult=undefined;
      this.error=error;
      this.isLoaded=false;
      this.previousvalues=this.reactiveValue;
        this.title='Error';
        this.message='Error while fetching data:'+error;
        this.variant='error';
      this.showNotification();
    })
   // this.dispatchEvent(new FlowAttributeChangeEvent('totalnumber', JSON.stringify(this.totalnumber)));
 } */
 doSorting(event) {
    this.isLoaded=true;
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortData(this.sortBy, this.sortDirection);
    this.isLoaded=false;
}

sortData(fieldname, direction) {
   
    let parseData = JSON.parse(JSON.stringify(this.unpivotresult));
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
    this.unpivotresult = parseData;
    this.previousvalues=this.reactiveValue;
    
}    
}