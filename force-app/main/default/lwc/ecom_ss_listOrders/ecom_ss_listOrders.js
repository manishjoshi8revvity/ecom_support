import { api, LightningElement } from 'lwc';
import getOrdersFromHierarchyNumber from "@salesforce/apex/ECOM_SelfServiceController.getOrdersFromHierarchyNumber";

export default class Ecom_ss_listOrders extends LightningElement {
  @api heading;
  @api orderNotFoundMessage;
  @api orderNumberLabel;
  @api orderPONumberLabel;
  @api orderDateLabel;
  @api orderStatusLabel;
  @api startDateMonthOffset;

  get showLoader() {
    return this.loading || this.redirecting;
  }

  loading = true;
  redirecting = false;
  orders = [];

  connectedCallback() {
    this.decryptAndDisplayOrders();
  }

  getTrackPageUrl(orderNumber, poNumber, postalCode) {
    return `${location.pathname.includes('/selfservice') ? '/selfservice' : ''}/track-order?orderNumber=${encodeURIComponent(orderNumber)}&poNumberOrPostalCode=${encodeURIComponent(poNumber ? poNumber : postalCode)}`;
  }

  async decryptAndDisplayOrders() {
    try {
      let params = new URLSearchParams(window.location.search);
      let hierarchyNumber = params.get('hierarchyNumber');
      let searchString = params.get('searchData');
      let salesOrg = params.get('salesOrg');
      if(!hierarchyNumber || !searchString || !salesOrg) {
        throw new Error(this.orderNotFoundMessage);
      }

      let orderData = await getOrdersFromHierarchyNumber({
        requestMap: {
          hierarchyNumber,
          searchString,
          salesOrg,
          startDateMonthOffset: parseInt(this.startDateMonthOffset)
        }
      });

      if(!orderData || orderData.length === 0) {
        throw new Error(this.orderNotFoundMessage);
      }

      if(orderData.length === 1) {
        this.redirecting = true;
        window.location.href = this.getTrackPageUrl(orderData[0].OrderNumber, orderData[0].CustomerPONumber, orderData[0].PostalCode);
        return;
      }

      this.orders = orderData.map(order => {
        return {
          orderNumber: order.OrderNumber,
          poNumber: order.CustomerPONumber,
          orderDate: new Date(order.OrderDate).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
          orderStatus: order.OrderStatus,
          url: this.getTrackPageUrl(order.OrderNumber, order.CustomerPONumber, order.PostalCode)
        };
      });
    } catch (error) {
      this.loading = false;
    } finally {
      this.loading = false;
    }
  }
}