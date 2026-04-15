import { LightningElement,api,track,wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getRecordCollections from '@salesforce/apex/UTIL_colProc_getRecordsFromIds.getRecordCollections';
export default class Lwc_colProc_getRecordsFromIds extends LightningElement {
    @api IdObjectAPI;
    @api inputValueList;
    @api Outputrecordlist;
    @api error;
    @api RecordFields;
    @wire(getRecordCollections, {IdObjectAPI: '$IdObjectAPI',inputValueList: '$inputValueList',RecordFields:'$RecordFields'})
wiredRecords({ error, data }) {
    console.log('Inside JS');
    
    if (data) {
      console.log('Inside IF JS');
      this.Outputrecordlist = data;
      console.log(JSON.stringify(this.Outputrecordlist));
      this.error = '';
      const selectedEvent = new FlowAttributeChangeEvent('Outputrecordlist', this.Outputrecordlist);
      console.log('Outputrecordlist ',JSON.stringify(selectedEvent));
      this.dispatchEvent(selectedEvent);
    } else if (error) {
      console.log('Inside ELSE IF JS');
      this.error = error;
      this.Outputrecordlist = '';
    }
  }
    
}