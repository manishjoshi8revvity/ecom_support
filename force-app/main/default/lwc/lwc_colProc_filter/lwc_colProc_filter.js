import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class lwc_colProc_filter extends LightningElement {

    @api inputvaluelist;
    @api outputvaluelist;
    @api fieldapisearch;
    @api searchvalue;
    previousvalues='';
    handleChange(event){
      //  this.searchvalue = event.target.value;
      this._debounceHandler();

     }

   get reactiveValue() { 
      // * Return reactive attributes as a string to be used in tracking
      return JSON.stringify(this.inputvaluelist) + this.searchvalue ;
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
         console.log('test');
         // o => Object.keys(o).some(k => k == fieldsearch &&  o[k].toString().toLowerCase().includes(searchKey.toLowerCase()))
/*let arraycollectionoutput = this.inputvaluelist.filter(k => {
   console.log('keys==',k[this.fieldapisearch]);
   return k[this.fieldapisearch].toLowerCase() ==this.searchvalue.toLowerCase();
});*/
let arraycollectionoutput = this.inputvaluelist.filter(o => Object.keys(o).some(k => k.toLowerCase() == this.fieldapisearch.toLowerCase() &&  o[k].toString().toLowerCase().includes(this.searchvalue.toLowerCase())));
console.log('arraycollectionoutput',JSON.stringify(arraycollectionoutput));
this.outputvaluelist=arraycollectionoutput;
this.previousvalues=JSON.stringify(this.inputvaluelist) + this.searchvalue;
const selectedEvent = new FlowAttributeChangeEvent('outputvaluelist', this.outputvaluelist);
console.log('final',JSON.stringify(selectedEvent));
this.dispatchEvent(selectedEvent);

      }
     
  

}