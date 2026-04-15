import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class Lwc_colproc_removerecordfromcollec extends LightningElement {
    
        @api inputValueList;
        @api outputValueList;
        @api removeIndex;
        get jsonInputValueList() {
            return this.inputValueList
                ? JSON.stringify(this.inputValueList)
                : '';
        }
        renderedCallback() {
            let indexPosition;
            if(this.removeIndex == undefined && this.inputValueList){
                indexPosition = this.inputValueList.length + 1;
                console.log('inside else if');
            }
            else {
                indexPosition = this.removeIndex;
                console.log('inside else');
            }
            
            this.outputValueList=[];
            
            console.log('this.inputValueList',JSON.stringify(this.inputValueList));
            console.log('this.removeIndex' + indexPosition);
            if(this.inputValueList != undefined && this.inputValueList != ''){
                console.log('this.removeIndex' + indexPosition);
                this.outputValueList=this.inputValueList.slice(0, indexPosition).concat(this.inputValueList.slice(indexPosition+1))
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