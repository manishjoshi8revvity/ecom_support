import { LightningElement, wire, track } from 'lwc';
import getUserData from '@salesforce/apex/ECOM_ContactInfoController.getUserData';
import updateUserData from '@salesforce/apex/ECOM_ContactInfoController.updateUserData';

export default class Ecom_contactInfo extends LightningElement {
    
    @track userData;
    @track showErrorMsg;
    updatedData={};
    message;
    type;
    show;
    @wire(getUserData)
    wiredData({ error, data }) {
        if (data) {
           this.userData = data;
          
           this.updatedData["Id"] = data.Id;
        } else if (error) {
            console.log('error ' + JSON.stringify(error));
        }
    }

    handleonChange(evt){
        if(evt.target.dataset.id === 'fName-Id' ){
            this.updatedData["FirstName"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'lName-Id' ){
            this.updatedData["LastName"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'country-Id' ){
            this.updatedData["Country"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'acctNumber-Id' ){
            this.updatedData["AccountId"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'company-Id' ){
            this.updatedData["CompanyName"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'street-Id' ){
            this.updatedData["Street"] = evt.target.value;
        }
        // if(evt.target.dataset.id === 'Address2-Id' ){
        //     this.updatedData.Address = evt.target.value;
        // }
        if(evt.target.dataset.id === 'city-Id' ){
            this.updatedData["City"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'state-Id' ){
            this.updatedData["State"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'zipcode-Id' ){
            this.updatedData["PostalCode"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'mobilephone-Id' ){
            this.updatedData["MobilePhone"] = evt.target.value;
        }
        if(evt.target.dataset.id === 'fax-Id' ){
            this.updatedData["Fax"] = evt.target.value;
        }
    }

    handleSaveChanges(){
        this.showErrorMsg = false;
        if(this.updatedData.Country == "" || this.updatedData.CompanyName == "" || 
            this.updatedData.Street == "" || this.updatedData.City == "" || 
            this.updatedData.State == "" || this.updatedData.PostalCode == "" ){
                this.showErrorMsg = true;
        }
       
        if(!this.showErrorMsg){
            updateUserData({
                modifiedUserData: this.updatedData
            })
            .then(result=>{
                if(result){
                    this.showMessage(
                    'Contact info updated successfully.',
                    'success',
                    true
                    );
                }else{	
                    this.showMessage(
                        'Error in updating data.',
                        'error',
                        true
                        );
                }
            })
            .catch(error=>{
                this.showMessage(
                    'Error in updating data.',
                    'error',
                    true
                    );
                console.log(error);
            });
        }
    }

    showMessage(message,type,show){
        this.message = message;
        this.type = type;
        this.show = show;
    }
    handleUpdateMessage(){
        this.message = '';
        this.type = '';
        this.show = false;
    }
}