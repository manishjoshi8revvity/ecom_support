import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class Lwc_colproc_copy extends LightningElement {

    @api inputValueList;
    @api outputValueList;

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
            //arrlist.push(this.inputValueList[0]);
            this.outputValueList=this.inputValueList;
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