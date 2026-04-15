import {LightningElement,api,wire,track} from 'lwc';
import flatpick from '@salesforce/resourceUrl/ssrc_ECOM_DatePicker';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import updateShippingDateOnCartItem from '@salesforce/apex/ECOM_CartController.updateShippingDateOnCartItem'

var flatpickdp ={};
export default class Ecom_datePicker extends LightningElement {
    
    datepickerInitialized = false;
    @api cartItemId;
    selectedDate;
    @api minimumDate;
    date;

    renderedCallback(){
        if(this.datepickerInitialized){
            return;
        }
        this.datepickerInitialized = true;

        Promise.all([
            loadScript(this, flatpick + '/flatpick/flatpickr.js'),
            loadStyle(this,flatpick + '/flatpick/material_blue.min.css')
        ]).then(() => {
            this.intializeDatepicker();
        })
        .catch(error => {
            console.log({message: 'Error onloading',error});
        });
    } 
    intializeDatepicker(){
        if(!this.minimumDate){
            var today = new Date();
            this.date = today.getFullYear()+'-' + (today.getMonth()+1) + '-'+today.getDate();
            this.minimumDate = this.date;
        }
        const dpDiv = this.template.querySelector('div.flatpickr');
        flatpickdp =  flatpickr(dpDiv,{
            inline:true,
            //minDate: "today",
            minDate: this.minimumDate,
            appendTo:dpDiv,
            monthSelectorType:'static',
            disable: [
                function(date) {
                // return true to disable
                return (date.getDay() === 0 || date.getDay() === 6);
                
                }
                ],
            locale: {
            firstDayOfWeek: 1 // start week on Monday
            }
        });
    }

    handleChangeDate(evt){
       
        evt.preventDefault();
        const sDate = {
            dateString : evt.target.value,
            dateJs : flatpickdp.selectedDates[0]
        };
        evt.preventDefault();
        const changeDate = new CustomEvent('datechanged',{detail:sDate});
        this.dispatchEvent(changeDate);
        
        this.selectedDate = sDate.dateString;
        //this.updateShippingDate();
    }

    @api
    updateShippingDate(){
      
        updateShippingDateOnCartItem({
            cartItemId: this.cartItemId,
            shipDate: this.selectedDate
        })
            .then((result) => {
               
            })
            .catch((error) => {
                console.log(error);
            });
    }
}