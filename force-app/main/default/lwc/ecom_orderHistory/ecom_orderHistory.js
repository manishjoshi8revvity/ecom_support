import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyOrders from '@salesforce/apex/ECOM_OrderHistoryController.getMyOrders';
export default class Ecom_orderHistory extends NavigationMixin(LightningElement) {

    @track myOrders;
    @track totalOrders;
    @wire(getMyOrders)
    wiredData({ error, data }) {
        if (data) {
           this.myOrders = data;
        
           console.log('myOrders =>'+JSON.stringify(this.myOrders));
              this.totalOrders = this.myOrders.length; 
           console.log('totalOrders =>'+this.totalOrders);
        } else if (error) {
            console.log('error ' + JSON.stringify(error));
        }
    }
}