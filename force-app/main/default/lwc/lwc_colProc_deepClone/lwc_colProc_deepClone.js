import { LightningElement ,api,wire} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import deepClone from '@salesforce/apex/UTIL_colProc_deepClone.deepClone';
export default class lwc_colProc_deepClone extends LightningElement {

    @api inputRecord;
    @api outputRecord;
    @api error;
   renderedCallback() {

		deepClone({currentObj:this.inputRecord})
			   .then(result => {
				   if(result){
					   console.log(result);
					   console.log('Inside IF JS');
					   this.outputRecord = result;
                       console.log(JSON.stringify(this.outputRecord));
					   this.error = '';
					   const selectedEvent = new FlowAttributeChangeEvent('outputRecord', this.outputRecord);
					   console.log('outputRecord event  ',JSON.stringify(selectedEvent));
					   this.dispatchEvent(selectedEvent);
				   }
			   })
			   .catch(error => {
				   console.log('Error: ', error);
				   this.error = error;
				   this.outputRecord = '';
			   });
   }

    handleOnChange(event) {
      console.log();
    }      
}