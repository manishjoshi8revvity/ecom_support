import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class Lwc_colproc_deduperecords extends LightningElement {

    @api inputValueList;
    @api outputValueList;
    @api fieldToDedupeOn;
    deDupedValuesSet=new Set();
    
    renderedCallback() {
        this.outputValueList=[];
        
        //console.log('this.inputValueList',JSON.stringify(this.inputValueList));
        if(this.inputValueList != undefined && this.inputValueList != '') {
            
            var dedupedfield=this.fieldToDedupeOn;
            var arr=this.inputValueList;    
            
            //Extract fieldToDedupeOn values in set
            for (const key in arr) {
                //console.log('arr[key].dedupedfield',JSON.stringify(arr[key][dedupedfield]));
                var d=arr[key][dedupedfield];
                this.deDupedValuesSet.add(d);
            }
            var arrdedupedValueset=this.deDupedValuesSet;
            var IsUnique;
            console.log('deDupedValuesSet line 28 ',this.deDupedValuesSet);

            for (var val of arrdedupedValueset) {
                
                this.IsUnique=true;
                console.log('val line 32  '+val); 
                
                for (const key1 in arr) {
                    //console.log('arr[key].dedupedfield',JSON.stringify(arr[key][dedupedfield]));
                    if(arr[key1][dedupedfield]==val){
                        IsUnique=false; 
                        this.outputValueList.push(arr[key1]);
                        break;
                    }
                    
                }

              }
              

            console.log('outputValueList line 47',JSON.stringify(this.outputValueList));
            const selectedEvent = new FlowAttributeChangeEvent('outputValueList', this.outputValueList);
            console.log('selectedEvent outputValueList 49',JSON.stringify(selectedEvent));
            this.dispatchEvent(selectedEvent);

        }
    }
 
    handleOnChange(event) {
        console.log();
    }

}