import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class lwc_colProc_mapCollection extends LightningElement {

    @api inputValueList;
    @api keyValuePairs;
    @api outputValueList;
    get reactiveValue() {
        return this.inputValueList != undefined 
            ? JSON.stringify(this.inputValueList)
            : '';
    }
    renderedCallback() {
        this.outputValueList=[];
        if(this.inputValueList != undefined && this.inputValueList != '' && this.keyValuePairs != undefined && this.keyValuePairs != ''){

        
        var keyValue = {...JSON.parse(this.keyValuePairs)};
        let InputListarry = [...this.inputValueList];
        let outputListarry = [];
        InputListarry.forEach((element) => 
        {
            if(element[Object.keys(keyValue)[0]] == keyValue[Object.keys(keyValue)[0]])
            {
             console.log('element',JSON.stringify(keyValue[Object.keys(keyValue)[1]]));
             
             //element[Object.keys(keyValue)[1]] = keyValue[Object.keys(keyValue)[1]];
            // element[Object.keys(keyValue)[1]] = 'INR';

             element = { ...element, ...keyValue };
             console.log('element2',JSON.stringify(element));
             outputListarry.push(element);
             
            }else{
                outputListarry.push(element);
            }

        }
        );
        //console.log('inputValueList',JSON.stringify(this.inputValueList));
        this.outputValueList = outputListarry;
        console.log('outputValueList',JSON.stringify(this.outputValueList));
        const selectedEvent = new FlowAttributeChangeEvent('outputValueList', this.outputValueList);

           // console.log('selectedEvent outputValueList 49',JSON.stringify(selectedEvent));

            this.dispatchEvent(selectedEvent);

    }
        
        /*console.log('keyValuePairs',JSON.stringify(this.keyValuePairs));
        console.log('keyValuePairs',JSON.stringify(this.keyValuePairs));
        console.log('keyValuePairs',JSON.stringify(this.keyValuePairs));
        console.log('this.inputValueList',JSON.stringify(this.inputValueList));*/
      /* if(this.inputValueList != undefined && this.inputValueList != '' && this.keyValuePairs != undefined && this.keyValuePairs != '') {
            
            let key = Object.keys(this.inputValueList);
            let getvalue = Object.values(this.inputValueList);
            let arraycollectionoutput = key + getvalue;
            this.outputValueList=arraycollectionoutput;
            console.log('this.outputValueList',JSON.stringify(this.outputValueList));
            this.dispatchEvent(new FlowAttributeChangeEvent('outputValueList', this.outputValueList));
        } */
    }
 
    handleOnChange(event) {
        console.log();
    }      
}