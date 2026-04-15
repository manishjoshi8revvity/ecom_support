import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class Lwc_colproc_insertrecord extends LightningElement {
 /*   @api inputValue; */
    @api indexValue;
    @api inputValueList;
    @api outputValueList;
    @api inputValue;
   /* get jsonInputValue() {
        return this.inputValue
            ? JSON.stringify(this.inputValue, null, 2)
            : '';
    } */
    get jsonInputValueList() {
        return this.inputValueList
            ? JSON.stringify(this.inputValueList)
            : '';
    }
    handlerecords(event){
        console.log("handlrecord");
    }
 renderedCallback(){
    console.log('renderedCallback');
    if(this.inputValueList != undefined && this.indexValue != undefined && this.indexValue != undefined){

    this.outputValueList=[];
     let arrlist=[];
     arrlist = [...this.inputValueList];
     let indexVl = this.indexValue;
     let intputVl = {...this.inputValue};
     console.log(indexVl+ intputVl);
     arrlist.splice(indexVl,0,intputVl);
     console.log('arrlist'+ arrlist);
     this.outputValueList=arrlist;
     this.dispatchEvent(new FlowAttributeChangeEvent('outputValueList', this.outputValueList));
    }
 }
 /*handlerecords(event){
        console.log('firstrecordset==',this.firstrecordset);
        console.log(event.target.value);
        console.log('size==' ,this.inputValueList);
        console.log('handlerecords',JSON.stringify( this.inputValueList[event.target.value]));
    }
    handleOnChange(){
        console.log('test', this.inputValueList.size());
    } */
}