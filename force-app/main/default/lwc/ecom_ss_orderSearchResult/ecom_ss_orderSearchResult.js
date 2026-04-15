import { LightningElement, track } from "lwc";
import IMAGES from "@salesforce/resourceUrl/ecom_ss_static_files";
import getOrderDetails from "@salesforce/apex/ECOM_SelfServiceController.getOrderDetails";
import { sessionAuthDataKey } from "c/ecom_ss_utils";
// RWPS-2227 start
import getNonShippableItems from "@salesforce/apex/ECOM_SelfServiceController.getNonShippableItems";
import nonShippableTooltip from "@salesforce/label/c.ECOM_Self_Service_Non_Shippable_Status_Tooltip";
import nonShippableLabel from "@salesforce/label/c.ECOM_Self_Service_Non_Shippable_Status_Label";
// RWPS-2227 end

import nonIntegratedCarrier from "@salesforce/label/c.ECOM_Self_Service_Non_Integrated_Carrier"; // RWPS-2661

export default class Ecom_ss_orderSearchResult extends LightningElement {
  itemStatusClass = {
    'Shipped': 'success',
    'Removed': 'danger',
    'Non-Shippable': 'secondary', // RWPS-2227
    'none': 'none' // RWPS-2227
  }
  shippedStatus = 'Shipped'; // RWPS-3601
  notIntegratedValue = nonIntegratedCarrier; // RWPS-3601

  trackingMap = {}

  windowWidth = window.innerWidth;
  @track componentState = {
    loader: true,
    data: false,
    error: false,
    loginIssue: false
  }
  get orderFinalData() {
    return this.componentState.data;
  }

  get isLargeScreen() {
    if (this.windowWidth > 1103) {
      return true;
    }
    return false;
  }

  updateWindowWidth() {
    this.windowWidth = window.innerWidth;
  }

  disconnectedCallback() {
    window.removeEventListener("resize", this.updateWindowWidth);
  }

  handleAccordionToggle(e) {
    let accordionOpenClass = "ecom-ss-full-width-accordion-open";
    let accordion = e.target.closest(".ecom-ss-full-width-accordion");

    if (!accordion) {
      return;
    }

    let accordionContentOuter = accordion.querySelector(
      ".ecom-ss-full-width-accordion-content-outer"
    );

    if (accordion.classList.contains(accordionOpenClass)) {
      accordion.classList.remove(accordionOpenClass);
      accordionContentOuter.style.height = 0;
    } else {
      accordion.classList.add(accordionOpenClass);
      accordionContentOuter.style.height =
        accordionContentOuter.querySelector(
          ".ecom-ss-full-width-accordion-content"
        ).clientHeight + "px";
    }
  }

  accordionIcons = {
    expand: IMAGES + "/accordion-expand.svg",
    collapse: IMAGES + "/accordion-collapse.svg"
  };

  getDeliveryDataLastLeg(deliveryData) {
    let finalData = {
      qtyData: 0,
      expectedShipDate: '-',
      actualShipDate: '-',
      // RWPS-3601 start
      trackingData: []
    };
    let lastLegNum = -1;

    let orderTrackingData = {}
    let totalQty = 0;

    let lastLeg = {};

    if (deliveryData && deliveryData.length > 0) {
      deliveryData.forEach((data) => {
        let leg = parseInt(data.legNumber);
        if(!isNaN(leg) && leg > lastLegNum) {
          lastLegNum = leg;
        }
      });

      let delDataFiltered = deliveryData.filter((data) => {
        let leg = parseInt(data.legNumber)

        if(lastLegNum==-1 || leg == lastLegNum) {
          return true;
        }
      });

      delDataFiltered.forEach((data, idx) => {
        if(idx==0) {
          lastLeg = data;
          lastLegNum = 0;
        }
        if(data.TrackingId?.trim()) {
          orderTrackingData[data.TrackingId + (data.carrierName ? data.carrierName : '')] = data;
        }
        if(data.shippedQty && !isNaN(parseFloat(data.shippedQty))) {
          totalQty += parseFloat(data.shippedQty);
        }
      });

    }

    if (lastLegNum == -1) {
      return finalData;
    }

    finalData.qtyData = totalQty || lastLeg.shippedQty || finalData.qtyData;

    let shipmentCreationDate = lastLeg.ShipmentCreationDate;
    if (shipmentCreationDate) {
      finalData.actualShipDate = shipmentCreationDate;
    }

    finalData.expectedShipDate = (
      lastLeg.ExpectedShipDate
      && finalData.actualShipDate !== shipmentCreationDate
    )
      ? lastLeg.ExpectedShipDate
      : finalData.expectedShipDate;

    for (let trackingDataKey in orderTrackingData) {
      let trackingData = orderTrackingData[trackingDataKey];
      let trackingId = trackingData.TrackingId;
      let trackingKey = null;

      if(trackingId) {
        if(trackingData.carrierType && this.trackingMap[trackingData.carrierType]) {
          trackingKey = trackingData.carrierType;
        } else if(trackingData.carrierName) {
          if(this.trackingMap[trackingData.carrierName]) {
            trackingKey = trackingData.carrierName;
          } else {
            let possibleKey = trackingData.carrierName.split(' ')[0];

            if(this.trackingMap[possibleKey]) {
              trackingKey = possibleKey;
            }
          }
        }
      }

      if(trackingId) {
        if(trackingKey) {
          finalData.trackingData.push({
            carrierName: trackingKey,
            trackingId: trackingId,
            trackingUrl: this.trackingMap[trackingKey].replace('{trackingNumber}', trackingId),
            key: 'orderTracking-' + finalData.trackingData.length
          })
        } else {
          finalData.notIntegratedFlag = true;
        }
      }
    }
    // RWPS-3601 end

    return finalData;
  }

  formatDate(inputDate) {
    let outputDate = (
      new Date(inputDate)
        .toLocaleDateString (
          'en-US',
          { month: '2-digit', day: '2-digit', year: 'numeric' }
        )
    )

    if(outputDate == 'Invalid Date') {
      outputDate = null;
    }

    return outputDate;
  }

  componentError(message) {
    this.componentState.error = message ? message : 'An error occurred!';
    this.componentState.loader = false;
  }

  sendOrderDetailRequest() {
    let dataMap = {};

    let query = new URL(document.location.toString()).searchParams;

    let orderNumber = query.get('orderNumber');
    if(orderNumber) {
      dataMap.orderNumber = orderNumber;
      dataMap.orderNumberPadded =
        new Intl.NumberFormat(
          "en-US",
          { maximumFractionDigits : 0, minimumIntegerDigits: 8 }
        ).format(parseInt(orderNumber)).replaceAll(',', '');
    } else {
      this.componentError('Incorrect data provided');
      return;
    }

    let poNumberOrPostalCode = query.get('poNumberOrPostalCode');
    if(poNumberOrPostalCode) {
      dataMap.poNumberOrPostalCode = poNumberOrPostalCode
    } else {
      let encryptedSession = localStorage.getItem(sessionAuthDataKey);
      if(encryptedSession) {
        dataMap.encryptedSession = encryptedSession;
      } else {
        this.componentError('Incorrect data provided');
        return;
      }
    }

    getOrderDetails({ dataMap })
      .then(async res => { // RWPS-2227

        if(!(res.sapOrder || res.orderData)) {
          this.componentState.loader = false;
          if(res.loginError) {
            this.componentState.loginIssue = true;
          }
          return;
        }

        if(res.trackingMap) {
          this.trackingMap = {...JSON.parse(res.trackingMap)};
        }

        let orderDetails = res.orderData || res.sapOrder;

        let erpAddress = orderDetails.Default_Ship_to_ERP_Address__r;

        let accountDetails = {};
        if(erpAddress) {
          accountDetails = {
            accountName: erpAddress.fxAccountName__c,
            accountNumber: erpAddress.fxCustomerNumber_Master__c
          }
        } else {
          accountDetails = {
            accountName: orderDetails.AccountName,
            accountNumber: orderDetails.AccountNumber
          }
        }

        let orderTotal = parseFloat(
          orderDetails.TotalOrderCost ||
          orderDetails.Order_Total_Price__c ||
          orderDetails.TotalAmount
        )
        orderTotal =
          isNaN(orderTotal) ?
            null :
            new Intl.NumberFormat("en-US", {minimumFractionDigits : 2}).format(orderTotal)

        let orderDate = null;
        // RWPS-3591 start
        if(orderDetails.OrderDate) {
          orderDate = orderDetails.OrderDate;
        } else {
          let createdDate = orderDetails.CreatedDate || res.Order__r?.CreatedDate;
          if(createdDate) {
            orderDate = this.formatDate(createdDate);
          }
        }
        // RWPS-3591 end

        let data = {
          orderNumberLabel: res.sapOrder ? 'SAP order' : 'Order No.',
          orderNumber: orderDetails.OrderNumber || res.SAPOrderNumber || orderNumber,
          poNumber: (
            orderDetails.PoNumber ||
            orderDetails.PONumber
          ),
          orderDate: orderDate,
          orderCurrency: orderDetails.OrderCurrency || orderDetails.CurrencyIsoCode,
          orderTotal: orderTotal,
          accountNumber: accountDetails.accountNumber,
          accountName: accountDetails.accountName,
          overallStatus: orderDetails.ECOM_Order_Summary_Status__c,
          shippingAddress: (
            orderDetails.ShippingAddress ||
            orderDetails.Default_Ship_to_ERP_Address__r?.fxAddressFull__c
          ),
          billingAddress: (
            orderDetails.BillingAddress ||
            orderDetails.Default_Bill_to_ERP_Address__r?.fxAddressFull__c
          ),
          recipient:
            orderDetails.CustomerAuthorizedBy
            ? orderDetails.CustomerAuthorizedBy.ECOM_Attention_Recipient__c
            : orderDetails.Attention,
          customerWillAccept:
            (orderDetails.customerWillAcceptDate)
            ? orderDetails.customerWillAcceptDate
            : null,
          creditStatus: orderDetails.creditStatus,
          deliveryBlock: orderDetails.DeliveryBlock,
          deliveryBlockDescription: orderDetails.DeliveryBlockDescription,
          deliveryBlockPresent: orderDetails.DeliveryBlock || orderDetails.DeliveryBlockDescription,
          paymentTerms: orderDetails.paymentTerms,
          incoTerms: orderDetails.incoTerm,
          ultimateDestination: orderDetails.UltCountryDesc
        }

        data.deliveryData1 =
          data.customerWillAccept || data.creditStatus || data.deliveryBlock || data.deliveryBlockDescription;

        data.orderItems = [];
        let itemsCount = orderDetails.OrderItems?.length || orderDetails.count_items__c;

        if(orderDetails.SAPResponse) {
          itemsCount = 0;

          orderDetails.OrderItems.forEach((item, idx) => {
            if(!item.PartNumber) {
              return;
            }
            itemsCount++;

            let status = item.deliveryStatus;
            let statusCode = item.deliveryStatusCode;
            if(statusCode == 'A') {
              status = 'Not shipped';
            } else if(statusCode == 'B') {
              status = 'Partially shipped';
            } else if (statusCode == 'C') {
              status = this.shippedStatus // RWPS-3601
            } else if(statusCode == 'R') {
              status = 'Removed'
            }

            let deliveryData = this.getDeliveryDataLastLeg(item.deliveryData);
            if(item.QuantityOrdered) {
              if(deliveryData.qtyData !== item.QuantityOrdered && status != this.shippedStatus) { // RWPS-3601
                deliveryData.qtyData = deliveryData.qtyData + ' of ' + item.QuantityOrdered;
              }
            }

            data.orderItems.push({
              key: 'order-item-level-data-' + idx,
              partNumber: item.PartNumber,
              description: item.Description ? item.Description : '-',
              status: status,
              statusType:
                this.itemStatusClass[status]
                ? this.itemStatusClass[status]
                : 'warning',
              ...deliveryData
            })
          })
        } else if(orderDetails.OrderItems) {
          itemsCount = orderDetails.OrderItems.length;

          orderDetails.OrderItems.forEach(item => {
            data.orderItems.push({
              key: item.Id,
              partNumber: item.Product2?.ProductCode ? item.Product2.ProductCode : '-',
              description: item.Description ? item.Description : '-',
              status: item.ECOM_Status__c,
              statusType:
                this.itemStatusClass[item.ECOM_Status__c]
                ? this.itemStatusClass[item.ECOM_Status__c]
                : 'warning',
              qtyData: item.Quantity ? item.Quantity : '-',
              expectedShipDate: '-',
              actualShipDate: '-',
              trackingData: [] //RWPS-3601
            })
          })
        }

        data.itemsCount = itemsCount;

        // RWPS-2227 start
        let partNumberSet = new Set();
        data.orderItems.forEach(item => {
          partNumberSet.add(item.partNumber);
        });

        let nonShippableParts = await getNonShippableItems({partNumbers: [...partNumberSet]});
        let nonShippableMap = {};
        nonShippableParts.forEach(part => {
          nonShippableMap[part.Part_Number__c] = true;
        });

        data.orderItems.forEach((item, idx) => {
          if(nonShippableMap[item.partNumber]) {
            data.orderItems[idx].status = nonShippableLabel;
            data.orderItems[idx].statusType = this.itemStatusClass['Non-Shippable'];
            data.orderItems[idx].statusTitle = nonShippableTooltip;
            data.orderItems[idx].statusInfo = true;
            data.orderItems[idx].qtyData = '-';
            data.orderItems[idx].expectedShipDate = '-';
            data.orderItems[idx].actualShipDate = '-';
            data.orderItems[idx].trackingData = []; // RWPS-3601
          }
        });
        // RWPS-2227 end

        this.componentState.data = data;
        this.componentState.loader = false;
      }).catch(e=>{
        console.error(e.message);
        this.componentError('An error occurred!');
      })
  }

  connectedCallback() {
    window.addEventListener("resize", this.updateWindowWidth.bind(this));
    this.sendOrderDetailRequest();
  }
}