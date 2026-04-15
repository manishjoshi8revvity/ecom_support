import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class Lwc_colproc_firstnrecordsfromcollec extends LightningElement {

    @api inputValueList;
    @api outputValueList;
    @api recordCount;
    get jsonInputValueList() {
        return this.inputValueList
            ? JSON.stringify(this.inputValueList)
            : '';
    }
    renderedCallback() {
        this.outputValueList=[];
        
        console.log('this.inputValueList',JSON.stringify(this.inputValueList));
        if(this.inputValueList != undefined && this.inputValueList != '') {
            //let arrlist=[];
            this.outputValueList=this.inputValueList.slice(0, this.recordCount);
            console.log('this.outputValueList',JSON.stringify(this.outputValueList));
        }
        else{
            console.log('inside else');
            this.outputValueList=[];
        }
        this.dispatchEvent(new FlowAttributeChangeEvent('outputValueList', this.outputValueList));
    }
 
    handleOnChange(event) {
        console.log();
    }      
}