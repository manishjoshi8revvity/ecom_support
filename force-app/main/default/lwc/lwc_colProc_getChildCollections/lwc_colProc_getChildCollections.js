import { LightningElement,api,track,wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getChildCollections from '@salesforce/apex/UTIL_colProc_getChildCollections.getChildCollections';
export default class Lwc_colProc_getChildCollections extends LightningElement {
@api ChildObjectType;
@api Parentfieldapi;
@api ParentrecordId;
@api ChildFields;
@api FilterCriteria;
@api childrecordlist;
@api ChildObjectAPI;
@api error;

get _FilterCriteria(){
   return  this.FilterCriteria != undefined ? this.FilterCriteria : '';
}
@wire(getChildCollections, {ChildObjectType: '$ChildObjectAPI',Parentfieldapi: '$Parentfieldapi',FilterCriteria:'$_FilterCriteria',ChildFields: '$ChildFields',ParentrecordId:'$ParentrecordId'})
wiredChild({ error, data }) {
    console.log('Inside JS');
    if (data) {
      console.log('Inside IF JS');
      this.childrecordlist = data;
      console.log(JSON.stringify(this.childrecordlist));
      this.error = undefined;
      const selectedEvent = new FlowAttributeChangeEvent('childrecordlist', this.childrecordlist);
      console.log('childrecordlist ',JSON.stringify(selectedEvent));
      this.dispatchEvent(selectedEvent);
    } else if (error) {
      console.log('Inside ELSE IF JS');
      this.error = error;
      this.childrecordlist = undefined;
    }
  }
  
 
  handleOnChange(){
    console.log();
  }

}