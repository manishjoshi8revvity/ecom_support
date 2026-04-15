import { LightningElement, track } from 'lwc';
import fetchsobjectlist from '@salesforce/apex/BULK_Transfer_Controller.fetchsobjectname';
import fetchfieldinfo from '@salesforce/apex/BULK_Transfer_Controller.fetchobjectandfld';
import fetchSobject from '@salesforce/apex/BULK_Transfer_Controller.fetchObjectRecords';
import updateSobject from '@salesforce/apex/BULK_Transfer_Controller.UpdateRecords';
//import createSFDCLogrec from '@salesforce/apex/BULK_Transfer_Controller.createSFDCLog';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ContactMobile from '@salesforce/schema/Case.ContactMobile';
export default class bulk_Transfer_Tool extends LightningElement {
    @track selectedobjtMap;
    @track slectedRecordObc;
    value = '';
    @track defaultOptions ;
    @track options=[];
    @track listOptions;
    @track columns;
    @track listSObjectRecords;
    @track selecteduser;
    @track UpdatedUser;
    @track isLoading=true;
    @track isfilter=true;
    @track commasepartedstring=[];
    @track searchkey;
    @track recordlist;
    @track initialrecordlist;
    @track filterrecordlist;
    @track selectedrecords=0;
    @track sortBy;
    @track sortDirection;
    // pagination variables----
    @track totalRecords;
    @track pageNo;
    @track totalPages;
    @track recordsperpage=500;
    @track startRecord;
    @track endRecord;
    @track end=false;
    toasttitle;
    toastMessage;
    variant;
    map1;
    @track usergroupvalue = 'user';
    @track newusergroupvalue = 'user';
    @track objectnameit;
    selectedobjstr;

    handleChangeusergrp(event) {
        this.selecteduser=null;
        console.log(event.target.value);
        this.usergroupvalue=event.target.value;
        this.objectnameit=this.selectedobjstr;
        console.log('usergroupvalue===',this.usergroupvalue);
        console.log('objectnameit===',this.objectnameit);
        if(this.usergroupvalue !=undefined && this.usergroupvalue=='queue' && this.objectnameit !=undefined){

            this.template.querySelector("[data-id='1']").handleSearchqueue(this.objectnameit);
        }else if(this.usergroupvalue !=undefined && this.usergroupvalue=='queue' && this.objectnameit ==undefined){
            this.usergroupvalue = 'user';
            this.toasttitle='Object Selection';
            this.toastMessage='Please select Object first for Queue Selection';
            this.variant='warning';
            this.showToast();
        }
    
    }
    newhandleChangeusergrp(event) {
        console.log(event.target.value);
        this.newusergroupvalue=event.target.value;
        this.objectnameit=this.selectedobjstr;
        console.log('newusergroupvalue===',this.newusergroupvalue);
        console.log('objectnameit===',this.objectnameit);
        if(this.newusergroupvalue !=undefined && this.newusergroupvalue=='queue' && this.objectnameit !=undefined){

            this.template.querySelector("[data-id='2']").handleSearchqueue(this.objectnameit);
        }else if(this.newusergroupvalue !=undefined && this.newusergroupvalue=='queue' && this.objectnameit ==undefined){
            this.newusergroupvalue = 'user';
            this.toasttitle='Object Selection';
            this.toastMessage='Please select Object first for Queue Selection';
            this.variant='warning';
            this.showToast();
        }
    
    }

    get usergroup() {
        return [
            { label: 'User', value: 'user' },
            { label: 'Queue', value: 'queue'},
        ];
    }
    get newusergroup() {
        return [
            { label: 'User', value: 'user' },
            { label: 'Queue', value: 'queue'},
        ];
    }
    connectedCallback(){
        this.isLoading=true;
        this.isfilter=true;
        fetchsobjectlist()
        .then(result => {
            var opt=[];
            if(result){
                console.log('result',JSON.stringify(result));
                result.forEach(element => 
                    opt.push({'label':element.labelIt,'value':element.apiIt,'typeIt':element.typeIt}));
                    this.options=opt;
                    console.log(JSON.stringify(this.options));
                    this.isLoading=false;
            }
            
        })
        .catch(error => {
            this.error = error;
        });
       
       }

    handleChange(event){
        this.usergroupvalue = 'user';
        this.newusergroupvalue = 'user';
        this.UpdatedUser=undefined;
    console.log('this.usergroupvalue',this.usergroupvalue);
        this.isLoading=true;
       this.listOptions=[];
        const selectedobj =event.target.value;
        console.log('options===', JSON.stringify(this.options.filter(k => k.value==selectedobj)));
        console.log('Selected object',JSON.stringify(selectedobj));
        this.value=selectedobj;
        let selectedoption = this.options.filter(k => k.value==selectedobj);

        if(this.options != undefined && this.options.length !=0 && selectedoption !=undefined && selectedoption.length ==1){
            this.selectedobjtMap=selectedoption[0];
        }
        console.log('this.selectedobjtMap==',JSON.stringify(this.selectedobjtMap));
        if(selectedobj != undefined){
            this.selectedobjstr =selectedobj;
            this.listSObjectRecords=null;
            fetchfieldinfo({varObjName : selectedobj})
            .then(result => {
                console.log('objectselection just after',JSON.stringify(result));
                var listofFieldOptions =[];
                if(result){
                    result.forEach(element => {
                        if(element.typeIt =='DATE' || element.typeIt=='DATETIME'){
                       listofFieldOptions.push({'label':element.labelIt,'value':element.apiIt,'type':element.typeIt,'isdate':true,'sortable': "true"});
                       }else{
                        listofFieldOptions.push({'label':element.labelIt,'value':element.apiIt,'type':element.typeIt,'isdate':false,'sortable': "true"});
                          
                       }});
                         this.listOptions=listofFieldOptions;
                        console.log('list option',JSON.stringify(this.listOptions));
                        this.isLoading=false;
                        
                }else{
                    this.isLoading=false; 
                }
                
                })
            .catch(error => {
                 console.log('error=='+JSON.stringify(error));
            })
        }
        
      }
      flattenObject(ob) {
        var toReturn = {};
    
        for (var i in ob) {
            if (!ob.hasOwnProperty(i)) continue;
    
            if ((typeof ob[i]) == 'object' && ob[i] !== null) {
                var flatObject = this.flattenObject(ob[i]);
                for (var x in flatObject) {
                    if (!flatObject.hasOwnProperty(x)) continue;
    
                    toReturn[i + '.' + x] = flatObject[x];
                }
            } else {
                toReturn[i] = ob[i];
            }
        }
        return toReturn;
    }
   
        filterrow(event){
    const searchkeystr=event.target.value;
    const apiIt = event.target.dataset.id;
    var datefield='';
    if(event.target.dataset.name != undefined){
        datefield =event.target.dataset.name;
    }
    var inp=this.template.querySelectorAll(".inpppp");
    console.log('apiIt==',JSON.stringify(apiIt));
    var Keyit=[];
    var valuesit=[];
    this.listSObjectRecords=this.initialrecordlist;
  if(this.map1 == undefined){
        this.map1 = new Map();
      }
      
      if(searchkeystr== '' || searchkeystr==undefined){
        this.map1.delete(datefield+apiIt.toLowerCase());
        }else{
            this.map1.set(datefield+apiIt.toLowerCase(), searchkeystr);
        }
        for (const [key, value] of this.map1.entries()) {
        if(key.startsWith('From')){
            const newkey=key.replace('From','');
          //  key= key.replace('From','');
           this.listSObjectRecords = this.listSObjectRecords.filter(o => Object.keys(o).some(k => k.toLowerCase() == newkey.toLowerCase() &&  o[k] >= value));
       }else if(key.startsWith('To')){
        const newkey= key.replace('To','');
            this.listSObjectRecords = this.listSObjectRecords.filter(o => Object.keys(o).some(k => k.toLowerCase() == newkey.toLowerCase() &&  o[k] <= value));
       }else if(value.includes(';') ){
        this.listSObjectRecords = this.listSObjectRecords.filter(o => Object.keys(o).some(k => k.toLowerCase() == key.toLowerCase() &&  value.toLowerCase().split(';').some(str => o[k].toString().toLowerCase().includes(str))));
        }else{
  
            this.listSObjectRecords = this.listSObjectRecords.filter(o => Object.keys(o).some(k => k.toLowerCase() == key.toLowerCase() &&  o[k].toString().toLowerCase().includes(value.toLowerCase())));
  
        }
       }
       this.recordlist=this.listSObjectRecords;
        this.setRecordsToDisplay();
      /* console.log('map1',JSON.stringify(Array.from(this.map1.entries()).reduce((obj, [key, value]) => {
            obj[key] = value;
            return obj;
          }, {}))); */
     }
      fetchdata(){
         console.log('before bakc end call'+this.commasepartedstring);
         var userIdstr;
         if(this.selecteduser != undefined){
            userIdstr=this.selecteduser.Id;
         }
          this.isLoading=true;
          fetchSobject({objnamest:this.value, limitst:'20000',OwnerIdstr:userIdstr})
        .then(result => {
       console.log('data result'+JSON.stringify(result));
        if(result.fldpropertieslist != undefined){
            var finalfieldprop=[];
            for (let element of result.fldpropertieslist) {
                if(element.fldapi=='Name'){
                    finalfieldprop.push({'label':element.fldlab,'fieldName':'recordlink','type':'url','sortable': "true",typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}});
                  }
                else{
                    finalfieldprop.push({'label':element.fldlab,'fieldName':element.fldapi,'type':element.fldtype,'sortable': "true"});
                   }
                }
              // result.fldpropertieslist.forEach(element => 
              //  finalfieldprop.push({'label':element.fldlab,'fieldName':element.fldapi,'type':element.fldtype,'sortable': "true"}));
                this.columns=finalfieldprop;
           }

        if(this.columns != undefined && result.SObjectRecords != undefined){
            var objlist=[];
           // result.SObjectRecords.forEach((obj)=>objlist.push(flatten(obj)));
            for(let ob of result.SObjectRecords){
                console.log('before');
                if(ob.Id !=undefined){
                   ob.recordlink ='/'+ ob.Id;
                }
                objlist.push(this.flattenObject(ob));
                
            }
            console.log('after=',objlist);
           console.log(JSON.stringify('objlist=====',objlist));
         //  this.listSObjectRecords=objlist;
           this.recordlist=objlist;
           this.initialrecordlist=objlist;
           this.setRecordsToDisplay();
           this.map1 =null;
           this.totalRecords=result.SObjectRecords.length;
           
        }
        
        this.isLoading=false;
      //  this.isfilter=false;
        })
        .catch(error => {
            console.log('error=='+JSON.stringify(error));
       })
       
        }
        selectedRecordId;
        handleValueSelcted(event) {
            this.selectedRecordId = event.detail;
            console.log(this.selectedRecordId);
        }
        validateLookupField() {
            this.template.querySelector('c-customlookup').isValid();
         }
         userSelected(event) {
            const userdetail = event.detail;
            console.log('selected Owner first',userdetail[0]);
            const tar = event.target;
          const id = tar.getAttribute("data-id");
            if(id==1){
                this.selecteduser = userdetail[0];      
            }
            if(id==2 && userdetail[0].Id.startsWith('005') && userdetail[0].IsActive){
              this.UpdatedUser=userdetail[0];
            }else if(id==2 && userdetail[0].Id.startsWith('00G')){
                this.UpdatedUser=userdetail[0];
            }else if(id==2 && userdetail[0].IsActive==false){
                this.toasttitle='Inactive User Selection';
                this.toastMessage='Please select Active User.';
                this.variant='error';
                this.showToast();
            }
            console.log('selected user',JSON.stringify(this.selecteduser));
            console.log('Updated user',JSON.stringify(this.UpdatedUser));
            
        }
        countrow(){
            this.slectedRecordObc=null;
            var el = this.template.querySelector('lightning-datatable');
            var selected =[];
            selected=el.getSelectedRows();
            let permittedValues=[];
            console.log('selected===',JSON.stringify(selected));
            console.log('selectedobjtMap===',JSON.stringify(this.selectedobjtMap));
            this.selectedrecords= selected.length;
            console.log(' this.selectedrecords===',JSON.stringify(this.selectedrecords));
            if(this.selectedobjtMap != undefined && this.selectedobjtMap.typeIt !=undefined && this.selectedobjtMap.typeIt=='AllMatch' && this.selectedrecords !=0){
              permittedValues =  new Set(selected.map(value => value.Owned_by_Company__c));
              console.log('permittedValues',permittedValues);
            }else if(this.selectedobjtMap.typeIt !=undefined && this.selectedobjtMap.typeIt=='Non-Grow'){
                permittedValues =  new Set(selected.filter(value => value.GROW_Employee_Email__c ==undefined).map(val =>val.Owned_by_Company__c));
            }
            console.log('permittedValues found',JSON.stringify([...permittedValues]));
            console.log('this.selectedobjtMap.typeIt',this.selectedobjtMap.typeIt);
            if(permittedValues != undefined && permittedValues.size >1 && this.selectedobjtMap.typeIt !='Non-Grow'){
             console.log('misMatch found',JSON.stringify(selected));
             this.template.querySelector('lightning-datatable').selectedRows=[];
             // alert('Please selelect row to Update Record.');
             this.toasttitle='MisMatched OBC Record Selection';
             this.toastMessage='Please select Same OBC Record to transfer.';
             this.variant='error';
             this.showToast();
            }else if(permittedValues != undefined && permittedValues.size ==1){
            this.slectedRecordObc=[...permittedValues][0];
            }
        console.log('this.slectedRecordObc==',this.slectedRecordObc);
        }
        handleselectedrow(){
            var el = this.template.querySelector('lightning-datatable');
            console.log(el);
            var selected =[];
            selected=el.getSelectedRows();
            console.log('selected',JSON.stringify(selected));
            console.log('this.UpdatedUser',JSON.stringify(this.UpdatedUser));
            console.log('slectedRecordObc',JSON.stringify(this.slectedRecordObc));
            let sameOBCRec;
            if(this.UpdatedUser !=undefined && selected.length >0){
                let updatedownerobc= this.UpdatedUser.Owned_by_Company__c !=undefined ? this.UpdatedUser.Owned_by_Company__c : this.UpdatedUser.Owned_By_Company;
                 sameOBCRec=selected.filter(obj => obj.Owned_by_Company__c != updatedownerobc);
            }
             if(selected == undefined || selected.length==0){
                
               // alert('Please selelect row to Update Record.');
                this.toasttitle='Row Selection';
                this.toastMessage='Please select row to transfer Record.';
                this.variant='error';
                this.showToast();
            }else if(this.UpdatedUser == undefined){
            //alert('Please selelect User to Update Record.');
            this.toasttitle='Select New Owner';
            this.toastMessage='Please select New Owner to transfer Record.';
            this.variant='error';
            this.showToast();
            }else if(this.slectedRecordObc != undefined && sameOBCRec != undefined && sameOBCRec.length >0){
                
                    this.toasttitle='New Owner Selection';
                    this.toastMessage='Please select New Owner of Same OBC to transfer Record.';
                    this.variant='error';
                    this.showToast();
            }else{
                this.isLoading=true;
				var restr='';
                console.log('this.map1.entries()==');
            if(this.map1 != undefined && this.map1.entries() != undefined){
                restr=JSON.stringify(Array.from(this.map1.entries()).reduce((obj, [key, value]) => {
                    obj[key] = value;
                    return obj;
                  }, {}));
            }
            let selectedUser= this.selecteduser != undefined ? this.selecteduser.Name :'Mix User Selection';
            updateSobject({sobjectLst:selected,Owneridstring:this.UpdatedUser.Id,sobjectname:this.selectedobjstr,fromuser:selectedUser,touser:this.UpdatedUser.Name,selectedrec:this.selectedrecords,totalrecords:this.totalRecords,wherestr:restr})
        .then(result => {
         /*   if(result==true){
            // alert('Selected Data has been Updated');
            this.isLoading=false;
            this.toasttitle='Status';
            this.toastMessage='Selected Data has been Updated';
            this.variant='success';
            this.showToast();
          //  this.createlog();
            this.fetchdata();
            } */
            
            console.log(JSON.stringify(result));
            if(result.isSuc==true && result.successRec !=undefined){
                this.toasttitle='Status';
                this.toastMessage=result.successRec+' data has been Updated out off '+this.totalRecords;
                this.variant='success';
                this.showToast();
            }
            if(result.isSuc==true && result.errorRec !=undefined){
                this.toasttitle='Status';
                this.toastMessage=result.errorRec+' row not Updated out off '+this.totalRecords;
                this.variant='warning';
                this.showToast();
            }
            if(result.isSuc==false){
                this.toasttitle='Status';
                this.toastMessage='Error !! Please contact With sysytem Admin';
                this.variant='error';
                this.showToast();
            }
            this.fetchdata();
            this.isLoading=false;
            
        })
        .catch(error =>{
            this.isLoading=false;
        })
                  
            }
        }
      /*  createlog(){
            console.log('selectedobjstr='+this.selectedobjstr+'fromuser='+this.selecteduser.Name +'touser='+this.UpdatedUser.Name+'selectedrec='+this.selectedrecords+'totalrecords:'+this.totalRecords)
            var restr='';
            if(this.map1.entries() != undefined){
                restr=JSON.stringify(Array.from(this.map1.entries()).reduce((obj, [key, value]) => {
                    obj[key] = value;
                    return obj;
                  }, {}));
            }
            console.log(restr);
            createSFDCLogrec({sobjectname:this.selectedobjstr,fromuser:this.selecteduser.Name,touser:this.UpdatedUser.Name,selectedrec:this.selectedrecords,totalrecords:this.totalRecords,wherestr:restr})
             .then(result => {
                 console.log('log created');
             })
             .catch(error =>{

             })
        } */
        showToast() {
            const event = new ShowToastEvent({
                title: this.toasttitle,
                message: this.toastMessage,
                variant: this.variant,
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        }
        filterlauncher(event){
           if(this.isfilter==true){
            this.isfilter=false;
           }else{
               this.isfilter=true;
           }
        }
        refreshComponent(e){
						this.value=null;
						this.listSObjectRecords=null;
						this.selecteduser=undefined;
						this.UpdatedUser=undefined;
						this.listOptions=undefined;
						
        }
        handleClick(event) {
            let label = event.target.label;
            if (label === "First") {
                this.handleFirst();
            } else if (label === "Previous") {
                this.handlePrevious();
            } else if (label === "Next") {
                this.handleNext();
            } else if (label === "Last") {
                this.handleLast();
            }
        }
        setRecordsToDisplay() {
            this.totalRecords = this.recordlist.length;
            this.pageNo = 1;
            this.totalPages = Math.ceil(this.totalRecords / this.recordsperpage);
            this.preparePaginationList();
        }
        handleNext() {
            this.pageNo += 1;
            this.preparePaginationList();
        }
    
        handlePrevious() {
            this.pageNo -= 1;
            this.preparePaginationList();
        }
    
        handleFirst() {
            this.pageNo = 1;
            this.preparePaginationList();
        }
    
        handleLast() {
            this.pageNo = this.totalPages;
            this.preparePaginationList();
        }
        preparePaginationList() {
          //  this.isLoading = true;
            let begin = (this.pageNo - 1) * parseInt(this.recordsperpage);
            let end = parseInt(begin) + parseInt(this.recordsperpage);
            this.listSObjectRecords = this.recordlist.slice(begin, end);
    
            this.startRecord = begin + parseInt(1);
            this.endRecord = end > this.totalRecords ? this.totalRecords : end;
            this.end = end > this.totalRecords ? true : false;
            this.disableEnableActions();
            this.isLoading = false;
        }
        disableEnableActions() {
            let buttons = this.template.querySelectorAll("lightning-button");
            buttons.forEach(bun => {
                if (bun.label === this.pageNo) {
                    bun.disabled = true;
                } else {
                    bun.disabled = false;
                }
    
                if (bun.label === "First") {
                    bun.disabled = this.pageNo === 1 ? true : false;
                } else if (bun.label === "Previous") {
                    bun.disabled = this.pageNo === 1 ? true : false;
                } else if (bun.label === "Next") {
                    bun.disabled = this.pageNo === this.totalPages ? true : false;
                } else if (bun.label === "Last") {
                    bun.disabled = this.pageNo === this.totalPages ? true : false;
                }
            });
        }
        handleSortData(event) {       
            this.sortBy = event.detail.fieldName;       
            this.sortDirection = event.detail.sortDirection;       
            this.sortData(event.detail.fieldName, event.detail.sortDirection);
        }
    
    
        sortData(fieldname, direction) {
            
            let parseData = JSON.parse(JSON.stringify(this.listSObjectRecords));
           
            let keyValue = (a) => {
                return a[fieldname];
            };
    
    
           let isReverse = direction === 'asc' ? 1: -1;
    
    
               parseData.sort((x, y) => {
                x = keyValue(x) ? keyValue(x) : ''; 
                y = keyValue(y) ? keyValue(y) : '';
               
                return isReverse * ((x > y) - (y > x));
            });
            
            this.listSObjectRecords = parseData;
    
    
        }
}