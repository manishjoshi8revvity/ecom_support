import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getOutputFromTwoRecCollections from '@salesforce/apex/UTIL_colProc_findCommonRecords.compareRecords';
export default class Lwc_colproc_findcommonrecords extends LightningElement {

    @api sourceRecordCollection;
    @api targetRecordCollection;
    @api sourceUniqueRecordCollection;
    @api commonRecordCollection;
    @api targetUniqueRecordCollection;
    @api uncommonRecordCollection;
    @api targetField;
    previousValue;
    
    get jsonInputValueList() {
        return JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetRecordCollection) + this.targetField;
    }
    
    renderedCallback() {
        console.log('inside render ' + this.targetRecordCollection);
        if(((this.sourceRecordCollection != undefined && this.targetRecordCollection != undefined) 
        || (this.sourceRecordCollection == undefined && this.targetRecordCollection != undefined)
        || (this.sourceRecordCollection != undefined && this.targetRecordCollection == undefined))
            && this.jsonInputValueList != this.previousValue) {
            console.log('inside render if');
            getOutputFromTwoRecCollections({sourceRecordCollection: this.sourceRecordCollection,targetRecordCollection: this.targetRecordCollection,fieldAPI:this.targetField})
            .then((result) => {
                console.log('result' + JSON.stringify(result[0].commonRecordCollection));
                this.commonRecordCollection=result[0].commonRecordCollection;
                this.sourceUniqueRecordCollection=result[0].sourceUniqueRecordCollection;
                this.targetUniqueRecordCollection=result[0].targetUniqueRecordCollection;
                this.uncommonRecordCollection=result[0].uncommonRecordCollection;
                this.previousValue = JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetRecordCollection) + this.targetField;
                this.dispatchEvent(new FlowAttributeChangeEvent('commonRecordCollection', this.commonRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('sourceUniqueRecordCollection', this.sourceUniqueRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('targetUniqueRecordCollection', this.targetUniqueRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('uncommonRecordCollection', this.uncommonRecordCollection));
            })
            .catch((error) =>{
                console.log('Error');
                this.previousValue = JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetRecordCollection) + this.targetField;
                this.commonRecordCollection=[];
                this.sourceUniqueRecordCollection=[];
                this.targetUniqueRecordCollection=[];
                this.dispatchEvent(new FlowAttributeChangeEvent('commonRecordCollection', this.commonRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('sourceUniqueRecordCollection', this.sourceUniqueRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('targetUniqueRecordCollection', this.targetUniqueRecordCollection));
                this.dispatchEvent(new FlowAttributeChangeEvent('uncommonRecordCollection', this.uncommonRecordCollection));
            })
        }
        else{
            console.log('inside else');
            this.previousValue = JSON.stringify(this.sourceRecordCollection) + JSON.stringify(this.targetRecordCollection) + this.targetField;
            this.commonRecordCollection=[];
            this.sourceUniqueRecordCollection=[];
            this.targetUniqueRecordCollection=[];
            this.dispatchEvent(new FlowAttributeChangeEvent('commonRecordCollection', this.commonRecordCollection));
            this.dispatchEvent(new FlowAttributeChangeEvent('sourceUniqueRecordCollection', this.sourceUniqueRecordCollection));
            this.dispatchEvent(new FlowAttributeChangeEvent('targetUniqueRecordCollection', this.targetUniqueRecordCollection));
            this.dispatchEvent(new FlowAttributeChangeEvent('uncommonRecordCollection', this.uncommonRecordCollection));
        }
        
    }
 
    handleOnChange(event) {
        console.log();
    }      
}