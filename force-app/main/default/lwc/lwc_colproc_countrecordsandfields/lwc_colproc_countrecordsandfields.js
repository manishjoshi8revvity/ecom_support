import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class Lwc_colproc_countrecordsandfields extends LightningElement {
@api inputcollection;
@api fieldname;
@api fieldvalue;
@api totalnumber;
@api matchednumber;
previousvalues;
_debounceTimer;

handleOnChange(event){
    //  this.searchvalue = event.target.value;
    this._debounceHandler();

   }
    get reactiveValue() { 
        // * Return reactive attributes as a string to be used in tracking
        return JSON.stringify(this.inputcollection) + this.fieldname+this.fieldvalue ;
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
    console.log(this.inputcollection);
    console.log(this.fieldname);
    console.log(this.fieldvalue);
    
       if (this.reactiveValue && this.reactiveValue != this.previousvalues) {
           this._callsyncmethod();
       }
   }
   _callsyncmethod(){
    console.log(JSON.stringify(this.inputcollection) +JSON.stringify(this.fieldname)+JSON.stringify(this.fieldvalue));
    if(this.inputcollection && this.fieldname){
  this.totalnumber=this.inputcollection.length;
  console.log('total length',this.totalnumber);
  this.matchednumber=this.inputcollection.filter( m => m[Object.keys(m).find(key => key.toLowerCase() === this.fieldname.toLowerCase())] ==this.fieldvalue ).length;
  console.log('Matched length',this.matchednumber);
  this.previousvalues=JSON.stringify(this.inputcollection) + this.fieldname+this.fieldvalue ;
this.dispatchEvent(new FlowAttributeChangeEvent('totalnumber', JSON.stringify(this.totalnumber)));
this.dispatchEvent(new FlowAttributeChangeEvent('matchednumber', JSON.stringify(this.matchednumber)));
}
   }
}