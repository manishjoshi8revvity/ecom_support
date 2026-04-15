import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class lwc_colProc_joinCollection extends LightningElement {

    @api inputValueListfirst;
    @api inputValueListsecond;
    @api outputValueList;
    get reactiveValue() {
        return this.inputValueListfirst != undefined && this.inputValueListsecond != undefined
            ? JSON.stringify(this.inputValueListfirst) + JSON.stringify(this.inputValueListsecond)
            : '';
    }
    renderedCallback() {
        this.outputValueList=[];
        
        console.log('this.inputValueListfirst',JSON.stringify(this.inputValueListfirst) + JSON.stringify(this.inputValueListsecond));
        if(this.inputValueListfirst != undefined && this.inputValueListfirst != '' && this.inputValueListsecond != undefined && this.inputValueListsecond != '') {
            
            this.outputValueList=[...this.inputValueListfirst,...this.inputValueListsecond];
            console.log('this.outputValueList',JSON.stringify(this.outputValueList));
            this.dispatchEvent(new FlowAttributeChangeEvent('outputValueList', this.outputValueList));
        }
    }
 
    handleOnChange(event) {
        console.log();
    }      
}