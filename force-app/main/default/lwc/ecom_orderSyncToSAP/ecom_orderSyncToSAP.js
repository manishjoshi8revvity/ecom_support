import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import syncOrderToSAP from '@salesforce/apex/ECOM_OrderSyncToSAPController.syncOrderToSAP';


export default class Ecom_orderSyncToSAP extends LightningElement {
    /*@api recordId;
    showSpinner = false;
    @api invoke() {
        console.log("From Action OrderSynctoSAP");
        console.log("record Id == " +this.recordId);
        this.showSpinner=true;
        syncOrderToSAP({
            recordId: this.recordId
        }).then((result) => {
            console.log(' result == '+result);
            if(result.Status == 'Success'){
                this.showSpinner = false;
                this.handleShowSuccess();
            }
        }).catch((error) => {
            const errorMessage = error.body.message;
            console.log(' errorMessage == '+ errorMessage);
            this.showSpinner = false;
            this.handleShowFailure();
        });
      }
      */
      @api
      get recordId() {
          return this._recordId;
      }
      set recordId(value) {
          this._recordId = value;
          if (this._recordId) {
              this.callApex();
          }
      }
  
      _recordId;
      showSpinner = true;
      callApex() {
        syncOrderToSAP({recordId: this.recordId})
            .then((result) => {
                notifyRecordUpdateAvailable([{recordId: this.recordId}])
                if (result != true && result != "true") {
                    this.handleShowSuccess();
                    /*this.showToastMessage(1, result);
                } else {
                    this.showToastMessage(2,"The report was successfully downloaded" );
                    eval("$A.get('e.force:refreshView').fire();");
                }*/
                // call close quickAction
                this.closeAction();
                }
            })
            .catch((error) => {
                console.log(error);
                this.handleShowFailure();
            })
            .finally(() => {
                this.showSpinner = false;
                
            });
    
        }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

   handleShowSuccess(){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Order record sent to SAP!',
                variant: 'success'
            })
        );
    }
    handleShowFailure(){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Order record failed to send to SAP!',
                variant: 'error'
            })
        );
    }
}