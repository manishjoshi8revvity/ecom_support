import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class Lwc_colproc_calculate extends LightningElement {
    @api inputcollection;
    @api fieldname;
    @api operator;
    @api output;
    previousvalues;
    _debounceTimer;

    handleOnChange(event){
        //  this.searchvalue = event.target.value;
        this._debounceHandler();
    
       }
       get reactiveValue() { 
        // * Return reactive attributes as a string to be used in tracking
        return JSON.stringify(this.inputcollection) + this.fieldname+this.operator ;
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
    
       if (this.reactiveValue && this.reactiveValue != this.previousvalues) {
           this.output=0;
        if(this.inputcollection !=undefined && this.inputcollection.length !=0 && this.fieldname !=undefined && this.operator !=undefined){
            this._callsyncmethod();
        }else{
            this.dispatchEvent(new FlowAttributeChangeEvent('output', this.output));
        }
         
       }
   }
   _callsyncmethod(){
   
    let arrayofstring=  this.inputcollection.map(value => value[this.fieldname]);
    if(this.operator !=undefined && this.operator.toLowerCase()=='add'){
        let sum =arrayofstring.reduce((partialresult, a) => Number(partialresult) + Number(a));
        this.output=sum;
    }else if(this.operator !=undefined && this.operator.toLowerCase()=='multiply'){
        arrayofstring = arrayofstring.filter(k => k);
        let multiply =arrayofstring.reduce((partialresult, a) => Number(partialresult) * Number(a));
        this.output=multiply;
    }else if(this.operator !=undefined && this.operator.toLowerCase()=='average'){
        arrayofstring = arrayofstring.filter(k => k);
        let sumthis =arrayofstring.reduce((partialresult, a) => Number(partialresult) + Number(a));
        this.output=sumthis/arrayofstring.length;
    }
    this.previousvalues=JSON.stringify(this.inputcollection) + this.fieldname+this.operator ;
    this.dispatchEvent(new FlowAttributeChangeEvent('output', this.output));
   }
}