import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import compareRecordsWithStrings from '@salesforce/apex/UTIL_colProc_findCommRecordwString.compareRecordsWithStrings';
export default class Lwc_colproc_findcommrecordwstring extends LightningElement {

    @api sourceRecordCollection;
    @api targetStringCollection;
    @api sourceUniqueRecordCollection;
    @api commonRecordCollection;
    @api targetUniqueStringCollection;
    @api targetUniqueStrings;
    @api targetField;
    previousValue;

    get jsonInputValueList() {
        return JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetStringCollection) + this.targetField;
    }
    
    renderedCallback() {

        if(((this.sourceRecordCollection != undefined && this.targetStringCollection != undefined) 
        || (this.sourceRecordCollection == undefined && this.targetStringCollection != undefined)
        || (this.sourceRecordCollection != undefined && this.targetStringCollection == undefined))
            && this.jsonInputValueList != this.previousValue) {
            console.log('inside render');
            compareRecordsWithStrings({sourceRecordCollection: this.sourceRecordCollection,targetStringCollection: this.targetStringCollection,fieldAPI:this.targetField})
            .then((result) => {
                console.log('1 ' + JSON.stringify(result[0].targetUniqueStringCollection));
                console.log('2 ' + JSON.stringify(result[0].targetUniqueStringCollection.toString()));
                console.log('3 ' + result[0].targetUniqueStringCollection);
                
                this.commonRecordCollection=result[0].commonRecordCollection;
                this.sourceUniqueRecordCollection=result[0].sourceUniqueRecordCollection;
                this.targetUniqueStringCollection=result[0].targetUniqueStringCollection;
                this.targetUniqueStrings = result[0].targetUniqueStringCollection;
                console.log('4 ' + this.targetUniqueStrings.toString());
                this.previousValue = JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetStringCollection) + this.targetField;
                this.dispatchEvent(new FlowAttributeChangeEvent('commonRecordCollection', this.commonRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('sourceUniqueRecordCollection', this.sourceUniqueRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('targetUniqueStringCollection', this.targetUniqueStringCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('targetUniqueStrings', this.targetUniqueStrings.toString()));
            })
            .catch((error) =>{
                console.log('Error');
                this.previousValue = JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetStringCollection) + this.targetField;
                this.commonRecordCollection=[];
                this.sourceUniqueRecordCollection=[];
                this.targetUniqueStringCollection=[];
                this.dispatchEvent(new FlowAttributeChangeEvent('commonRecordCollection', this.commonRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('sourceUniqueRecordCollection', this.sourceUniqueRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('targetUniqueStringCollection', this.targetUniqueStringCollection));
            })
        }
        else{
            console.log('inside else');
            this.previousValue = JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetStringCollection) + this.targetField;
                this.commonRecordCollection=[];
                this.sourceUniqueRecordCollection=[];
                this.targetUniqueRecordCollection=[];
                this.dispatchEvent(new FlowAttributeChangeEvent('commonRecordCollection', this.commonRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('sourceUniqueRecordCollection', this.sourceUniqueRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('targetUniqueStringCollection', this.targetUniqueStringCollection));
        }
        
    }
 
    handleOnChange(event) {
        console.log();
    }      
}