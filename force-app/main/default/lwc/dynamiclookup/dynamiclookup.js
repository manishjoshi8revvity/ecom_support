import { LightningElement,track,api} from 'lwc';
import getuserList from '@salesforce/apex/BULK_Transfer_Controller.fetchuserinfo';
import getgroupList from '@salesforce/apex/BULK_Transfer_Controller.fetchgroupinfo';
export default class Dynamiclookup extends LightningElement {
    @track isopenslds=false;
    @track allUsersFinal=[];
    @track allUsers=[];
    @track usersearchkey;
    @api objectnameit;
    @api ownertypeit='user';
    @track queues=[];
    @api itemname;
    error;
    connectedCallback(){
        getuserList()
        .then(result => {
            this.allUsers = result;
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
        });
    }
    
// start here
@api
handleSearchqueue(objectstring) {
  console.log('child method called',objectstring);
  if(objectstring == undefined){
       console.log('Please select Object');
  }else{
  getgroupList({ sobjectname: objectstring })
      .then((result) => {
          this.queues = result;
          this.error = undefined;
      })
      .catch((error) => {
          this.error = error;
          this.queues = undefined;
      });
    }
}

// end here    
    searchinguser (event){
      console.log('itemname==',this.itemname);
      var finaldata;
      if(this.objectnameit !=undefined && this.ownertypeit !='user'){
        finaldata =this.queues ;
      }else{
        finaldata =this.allUsers ;
      }
        var fieldsearch ='Name';
        const searchKey = event.target.value; 
       console.log(JSON.stringify(searchKey));if(searchKey != undefined && searchKey != ''){
         finaldata = finaldata.filter(o => Object.keys(o).some(k => k == fieldsearch &&  o[k].toString().toLowerCase().includes(searchKey.toLowerCase())));  
         this.isopenslds=true;
         this.allUsersFinal=finaldata.slice(0,100);   
         console.log('allUsersFinal',JSON.stringify(this.allUsersFinal));
        }
        else{
            
            var xVar =[];
          this.allUsersFinal=xVar;  
          this.isopenslds=false;
        }
    }

    get tabClass() { 
        return this.isopenslds ? 'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid slds-is-open' : 'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid slds-is-close';
      }
      selectuser (event){
        var getSelectRecord = event.currentTarget.dataset.value;
        console.log('getSelectRecord===',getSelectRecord);
        console.log('getSelectRecord===',JSON.stringify(this.allUsersFinal));
        if(getSelectRecord != undefined){
          this.selectedUser=getSelectRecord;
          console.log(JSON.stringify(this.allUsersFinal.filter(o => o.Id == getSelectRecord))); 
          var selectedusser=this.allUsersFinal.filter(o => o.Id == getSelectRecord);
          const selectedEvent = new CustomEvent('selected', { detail: selectedusser });
          this.dispatchEvent(selectedEvent);
          this.allUsersFinal=[]; 
            this.isopenslds=false;
        }
		}
}