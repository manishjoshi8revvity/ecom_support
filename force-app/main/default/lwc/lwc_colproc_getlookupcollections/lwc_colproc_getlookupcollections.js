import { LightningElement ,api,track} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getParentCollections from '@salesforce/apex/UTIL_colProc_getLookupCollections.fetchSobject';
export default class lwc_colproc_getlookupcollections extends LightningElement {

    @api lookupcollection;
    @api inputcollection;
    @api lookupobjectname;
    @api lookupfieldname;
    @api lookuprecordfieldscsv;
    @track parentids;
    previousvalues='';
    _title = "Sample Title";
    message = "Sample Message";
    variant = "error";
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
   get reactiveValue() { 
      // * Return reactive attributes as a string to be used in tracking
      return JSON.stringify(this.inputcollection) + this.lookupfieldname ;
  }
 // Debounce the processing of the reactive changes
 _debounceHandler() {
   this._debounceTimer && clearTimeout(this._debounceTimer);
   if (this.reactiveValue){
       this._debounceTimer = setTimeout(() => this.__callsyncmethod(), 300);
   }    
} 
  // On rendering, check for a value or change in value of reactive attribute(s) and execute the handler
  renderedCallback() {
   console.log('render call');
   
      if (this.reactiveValue && this.reactiveValue != this.previousvalues) {
          this._callsyncmethod();
      }
  }
      _callsyncmethod(){
        if(this.inputcollection && this.lookupfieldname){
//console.log('parentIds==> ',JSON.stringify(this.inputcollection.map((key) => { return key[this.lookupfieldname].replace (/"/g,''); })));
     // this.parentids=this.inputcollection.map((key) => { return key[this.lookupfieldname].replace (/"/g,''); });
     this.parentids=this.inputcollection.map((key) => { return   key[Object.keys(key).find(ke => ke.toLowerCase() === this.lookupfieldname.toLowerCase())].replace (/"/g,'')});
    
      if(this.parentids==undefined){
        this._title = "Lookup Records";
        this.message = "No Lookup records Found";
        this.variant = "error";
        this.showNotification();
       }else{
        getParentCollections({parentrecordsid: this.parentids ,commaseparatedfield: this.lookuprecordfieldscsv,objectapi:this.lookupobjectname})
      .then((result) => {
        this.lookupcollection=result;
        this.error=undefined;
        this.previousvalues=JSON.stringify(this.inputcollection) + this.lookupfieldname;
        const selectedEvent = new FlowAttributeChangeEvent('lookupcollection', this.lookupcollection);
        console.log('final',JSON.stringify(selectedEvent));
        this.dispatchEvent(selectedEvent);
      })
      .catch((error) =>{
        console.log('Error');
        this.showNotification();
      })
    }
  }else{
    console.log('No result');
  }
}

  

}