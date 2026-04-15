import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class Lwc_colproc_findrecord extends LightningElement {

    @api inputValueList;
    @api outputValueList;
    @api targetField;
    @api targetValue;
    get jsonInputValueList() {
        return this.inputValueList
            ? JSON.stringify(this.inputValueList)
            : '';
    }
    renderedCallback() {
        this.outputValueList=[];
        
        console.log('this.inputValueList',JSON.stringify(this.inputValueList));
        if(this.inputValueList != undefined && this.inputValueList != '') {
            this.outputValueList=this.inputValueList.filter( m => m[Object.keys(m).find(key => key.toLowerCase() === this.targetField.toLowerCase())].toLowerCase() ==this.targetValue.toLowerCase());
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