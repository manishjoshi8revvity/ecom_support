import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class Lwc_colproc_extractstringswdedupe extends LightningElement {
    @api inputcollection;
    @api fieldname;
    @api dedupevalue =false;
    @api fieldvaluecollection;
    @api fieldvaluestring;
    previousvalues;
    _debounceTimer;


    
handleOnChange(event){
    //  this.searchvalue = event.target.value;
    this._debounceHandler();

   }
   get reactiveValue() { 
    // * Return reactive attributes as a string to be used in tracking
    return JSON.stringify(this.inputcollection) + this.fieldname+this.dedupevalue ;
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
    console.log(this.dedupevalue);
    
       if (this.reactiveValue && this.reactiveValue != this.previousvalues) {
           this._callsyncmethod();
       }
   }
   _callsyncmethod(){
    if(this.inputcollection && this.fieldname){
        let arrayofstring=  this.inputcollection.map(value => value[this.fieldname]);
        console.log('this.dedupevalue'+this.dedupevalue);
        if(this.dedupevalue){
            this.fieldvaluecollection=[...new Set(arrayofstring)];
        }else{
            this.fieldvaluecollection=arrayofstring;
        }
       
       this.fieldvaluestring=this.fieldvaluecollection.toString();
       console.log('this.fieldvaluecollection',this.fieldvaluecollection);
       console.log('this.fieldvaluestring',this.fieldvaluestring);
    this.previousvalues=JSON.stringify(this.inputcollection) + this.fieldname+this.dedupevalue ;
    this.dispatchEvent(new FlowAttributeChangeEvent('fieldvaluecollection', this.fieldvaluecollection));
    this.dispatchEvent(new FlowAttributeChangeEvent('fieldvaluestring', this.fieldvaluestring));
   }
}
}