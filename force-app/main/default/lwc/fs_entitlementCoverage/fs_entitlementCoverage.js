/**
 * Created by frankvanloon on 4/24/24.
 */

import { LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import getEntitlementCoverage from '@salesforce/apex/FS_ServiceContractManager.getEntitlementCoverage';

export default class EntitlementCoverage extends LightningElement {

    @api recordId;
    @track coverage;
    @track showCoverageBlocks = false;

    @wire(getEntitlementCoverage, { recordId: "$recordId"} )
        wiredCoverages({ error, data }) {
            if (data) {
                try {
                    console.log('Entitlement Coverage ran successfully. recordId: ' + this.recordId);
                    console.log('getEntitlementCoverage data: ' + JSON.stringify(data, null, 2));

                    // Convert Ids into relative URLs
                    const addForwardSlash = a => '/' + a;

                    const result = data.map(o => ({ ...o,
                        coveredProductId: addForwardSlash(o.coveredProductId),
                        serviceMaintenanceContractId: addForwardSlash(o.serviceMaintenanceContractId),
                        installedProductId: addForwardSlash(o.installedProductId),
                     }));

                    this.coverage = result;

                    console.log('this.coverage: ' + JSON.stringify(this.coverage, null, 2));

                    if (this.coverage.length > 0) {
                        this.showCoverageBlocks = true;
                    }

                } catch(e){
                    //error when handling result
                    console.error('getEntitlementCoverage Result Error: ', JSON.stringify(error));
                    const evt = new ShowToastEvent({ title: 'Entitlement Coverage Error', message: 'Error: ' + error.body?.message + ' -- ' + error.body?.stackTrace, variant: 'error', mode: 'sticky'});
                    this.dispatchEvent(evt);
                }
            } else if (error) {
                //error with value provisioning
                console.error('Entitlement Coverage Provisioning Error: ', JSON.stringify(error));
                const evt = new ShowToastEvent({ title: 'Entitlement Coverage Provisioning Error', message: 'Error: ' + error.body?.message + ' -- ' + error.body?.stackTrace, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            }
        }

}