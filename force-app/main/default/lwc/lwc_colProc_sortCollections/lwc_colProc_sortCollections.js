import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class Lwc_colProc_sortCollections extends LightningElement {
    @api inputValueList;
    @api outputValueList;
    @api SortKey;
    @api Order;
    PreviousOrder;
    IsDesc= false;
    get reactive(){
        return this.Order!=this.PreviousOrder?true:false ;
     }       
    //Function To Sort
    sortByProperty(){
        if(this.Order=="DESC"){
            this.IsDesc=true;  
        }
        console.log('SortKey  '+this.SortKey);
        let arr=[...this.inputValueList];
        let property=this.SortKey;
        let sortby=this.IsDesc;
        arr.sort( function( a, b ){
            
            var c = a[property] != undefined ? a[property].toString() : '';
            var d = b[property] != undefined ? b[property].toString() : '';
            console.log('c  '+JSON.stringify(c));
            console.log('d  '+JSON.stringify(d));
            if ( c == d ) 
            return 0;
            return sortby
            ? d > c ? 1 : -1
            : d < c ? 1 : -1 ;
        } );
        this.inputValueList=arr;        
        this.PreviousOrder=this.Order;
    }
    renderedCallback() {
        this.outputValueList=[];
        
        console.log('this.inputValueList',JSON.stringify(this.inputValueList));
        if(this.inputValueList != undefined && this.inputValueList != '') {
            console.log('Before Sort');
            if(this.reactive){
                this.sortByProperty();
            }
            console.log('After Sort');
            this.outputValueList=this.inputValueList;
            console.log('outputValueList',JSON.stringify(this.outputValueList));
            const selectedEvent = new FlowAttributeChangeEvent('outputValueList', this.outputValueList);
            console.log('selectedEvent outputValueList ',JSON.stringify(selectedEvent));
            this.dispatchEvent(selectedEvent);

        }
    }
 
    handleOnChange(event) {
        console.log();
    }

}