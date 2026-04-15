import { api, LightningElement } from 'lwc';
import getProductRecommendations from '@salesforce/apex/ECOM_TestRecommendations.getProductRecommendations';
import getProductRecommendationsSAP from '@salesforce/apex/ECOM_TestRecommendations.getProductRecommendationsSAP';
import getCustomersAlsoBought from '@salesforce/apex/ECOM_TestRecommendations.getCustomersAlsoBought';
import getCustomersAlsoBought2 from '@salesforce/apex/ECOM_ProductRecommendationsController.getCustomersAlsoBought';
import LightningAlert from 'lightning/alert';

const readyMessage = {type: 'einstein-tracking', subtype: 'ready'};

export default class Ecom_testProductRecommendations extends LightningElement {
  @api hideUI;

  @api recencyFactor;
  _recencyFactor;
  @api steepnessFactor;
  _steepnessFactor;
  @api maxRecs;
  _maxRecs;
  @api samplesetSize;
  _samplesetSize;
  @api sameOrderBoost;
  _sameOrderBoost;
  @api disableMultiProductSOB;
  _disableMultiProductSOB;
  @api startDate;
  _startDate;
  @api endDate;
  _endDate;

  @api sourceDataset = 'web';

  salesOrg;

  displayInfo = {
    primaryField: 'Name',
    additionalFields: ['Part_Number__c'],
  }

  matchingInfo = {
    primaryField: { fieldPath: 'Part_Number__c', mode: 'startsWith' },
    additionalFields: [{ fieldPath: 'Name' }],
  }

  productPn = '';

  initialState = true;
  errorMessage = '';
  loading = false;
  recs = [];

  displayError(message) {
    LightningAlert.open({
      label: 'Error!',
      message: message,
      variant: 'error',
    });
  }

  processRecommendations(data) {
    this.productPn = data.baseProducts[0].Part_Number__c;

    let recsData = data.recommendations?.map(
      rec => (
        {
          ...rec,
          title: rec.product.Part_Number__c + ' - ' + rec.product.Name,
          score: parseFloat(rec.score).toFixed(2),
          recency: parseFloat(rec.recency).toFixed(2),
        }
      )
    );
    this.recs = recsData || [];

    this._recencyFactor = data.configuration.recencyFactor;
    this._steepnessFactor = data.configuration.steepnessFactor;
    this._maxRecs = data.configuration.maxRecs;
    this._samplesetSize = data.configuration.samplesetSize;
    this._sameOrderBoost = data.configuration.sameOrderBoost;
    this._disableMultiProductSOB = data.configuration.disableMultiProductSOB ? 'true' : 'false';
    this.salesOrg = data.configuration.salesOrg || '';

    let startDateTemp = new Date(data.configuration.startDate);
    if(startDateTemp.getTime() == 0) {
      this._startDate = 'None';
    } else {
      this._startDate = startDateTemp.toString();
    }

    this._endDate = new Date(data.configuration.endDate).toString();
  }

  async updateRecommendations() {
    let product = this.refs.productPicker?.value;
    if(!product) {
      this.displayError('Please select a product to get recommendations.');
      return;
    }

    let finalRecencyFactor = parseFloat(this.refs.recencyFactor?.value);
    if(isNaN(finalRecencyFactor)) {
      this.displayError('Invalid recency factor');
      return;
    }

    let finalSteepnessFactor = parseFloat(this.refs.steepnessFactor?.value);
    if(isNaN(finalSteepnessFactor)) {
      this.displayError('Invalid steepness factor');
      return;
    }

    let finalMaxRecs = parseInt(this.refs.maxRecs?.value);
    if(isNaN(finalMaxRecs)) {
      this.displayError('Invalid max recommendations');
      return;
    }

    let finalSamplesetSize = parseInt(this.refs.samplesetSize?.value);
    if(isNaN(finalSamplesetSize)) {
      this.displayError('Invalid sampleset size');
      return;
    }

    let finalSameOrderBoost = parseInt(this.refs.sameOrderBoost?.value);
    if(isNaN(finalSameOrderBoost)) {
      this.displayError('Invalid same order bonus');
      return;
    }

    let configMap = {
      recencyFactor: finalRecencyFactor,
      steepnessFactor: finalSteepnessFactor,
      maxRecs: finalMaxRecs,
      samplesetSize: finalSamplesetSize,
      sameOrderBoost: finalSameOrderBoost,
      disableMultiProductSOB: this.refs.disableMultiProductSOB?.checked ? true : false,
      internalUse: true
    };

    if(this.refs.salesOrg?.value) {
      configMap.salesOrg = this.refs.salesOrg.value;
    }

    let finalStartDate = this.refs.startDate?.value;
    if(finalStartDate) {
      configMap.startDate = new Date(finalStartDate).getTime() + '';
    }
    let finalEndDate = this.refs.endDate?.value;
    if(finalEndDate) {
      configMap.endDate = new Date(finalEndDate).getTime() + '';
    }

    this.loading = true;
    this.initialState = false;
    this.errorMessage = '';

    try {
      let data =
        await (
          this.sourceDataset === 'web' ?
          getProductRecommendations({ productIds: [product], configuration: configMap }) :
          getProductRecommendationsSAP({ productIds: [product], configuration: configMap })
        );
      this.processRecommendations(data);
    } catch (error) {
      console.error('Error fetching recommendations:', error);
      this.errorMessage = JSON.stringify(error, null, 2);
    }
    this.loading = false;
  }


  async receiveMsg(event) {
    let {data} = event;

    if(data?.type == 'einstein-tracking' && window.parent !== window && data?.subtype == 'ready') {
      window.parent.postMessage(readyMessage, '*');
    }

    if(data?.type == 'einstein-recommendation') {
      let config = {
        recencyFactor: parseFloat(this.recencyFactor),
        steepnessFactor: parseFloat(this.steepnessFactor),
        maxRecs: parseInt(this.maxRecs),
        samplesetSize: parseInt(this.samplesetSize),
        sameOrderBoost: parseFloat(this.sameOrderBoost),
        disableMultiProductSOB: this.disableMultiProductSOB,
        salesOrg: data.salesOrg,
        startDate: this.startDate ? new Date(this.startDate).getTime() + '' : undefined,
        endDate: this.endDate ? new Date(this.endDate).getTime() + '' : undefined
      };

      // let recData = await getProductRecommendationsSAP({
      //   productIds: data.ref,
      //   configuration: config
      // });

      // let pns = recData.recommendations?.map(
      //   rec => rec.product.Part_Number__c
      // );
      let recData = await getCustomersAlsoBought2({
        productIds: data.ref,
        communityId: '0DBHs000000Ckk5OAC',
        configuration: {
          maxRecs: parseInt(this.maxRecs),
          salesOrg: data.salesOrg ? data.salesOrg : undefined
        }
      });
      let pns = recData.sellableRecommendations?.map(
        rec => {
          return recData.productIdMap[rec].Part_Number__c;
        }
      );

      window.parent.postMessage({
        anchorType: 'product',
        data: pns || [],
        key: '',
        recoUUID: '',
        ref: data.ref,
        subtype: 'customers-who-bought-also-bought',
        type: 'einstein-recommendation-response'
      }, '*');
    }
  }

  connectedCallback() {
    window.addEventListener('message', this.receiveMsg.bind(this));
    if(window.parent) {
      window.parent.postMessage(readyMessage, '*');
    }
  }
  disconnectedCallback() {
    window.removeEventListener('message', this.receiveMsg);
  }




  // topPn = ['01tHs000008klCqIAI','01tHs000008kkCeIAI','01tHs000008klILIAY','01tHs000008kkGMIAY','01tHs000008kmUQIAY','01tHs000008kl5jIAA','01tHs000008km1tIAA','01tHs000008kmBhIAI','01tHs000008kn3kIAA','01tHs000008klH1IAI','01tHs00000A7lD9IAJ','01tHs000008kns9IAA','01tHs000008kc9cIAA','01tHs000008kkNzIAI','01tHs000008kmgWIAQ','01tHs000008knR0IAI','01tHs000008kkmHIAQ','01tHs000008kkUyIAI','01tHs000008knzDIAQ','01tHs000008kncgIAA','01tHs000008kmtPIAQ','01tHs000008kkUfIAI','01tHs000008knsbIAA','01tHs000008koB4IAI','01tHs00000A6wEPIAZ','01tHs000008klccIAA','01tHs000008knCcIAI','01tHs000008kmdSIAQ','01tHs000008kcS2IAI','01tHs000008kl6HIAQ','01tHs00000A6jILIAZ','01tHs000008kmPjIAI','01tHs000008kmRDIAY','01tHs000008kksdIAA','01tHs000008knCmIAI','01tHs000008klBrIAI','01tHs000008kmQdIAI','01tHs000008knrdIAA','01tHs000008knZ5IAI','01tHs000008kmmdIAA','01tHs000008kkZTIAY','01tHs000008koHlIAI','01tHs000008kglxIAA','01tHs000008kkmQIAQ','01tHs00000A84niIAB','01tHs000008klhqIAA','01tHs000008km9kIAA','01tHs000008kk8tIAA','01tHs000008klVuIAI','01tHs000008kn7dIAA'];
  // topPn = ['01tHs000008kmBhIAI'];
  topPn = ['01tHs000008kl1gIAA', '01tHs000008kmMNIAY', '01tHs000008knKeIAI', '01tHs000008kjIpIAI', '01tHs000008kjFzIAI', '01tHs000008kkMBIAY', '01tHs000008kl7KIAQ', '01tHs000008kjJXIAY', '01tHs000008klbwIAA', '01tHs000008kjHWIAY', '01tHs000008knSYIAY', '01tHs000008ko4mIAA', '01tHs000008kn7QIAQ', '01tHs000008kmjjIAA', '01tHs000008koB4IAI', '01tHs000008knR0IAI', '01tHs000008knzDIAQ', '01tHs000008klH1IAI', '01tHs000008kns9IAA', '01tHs000008knEfIAI', '01tHs000008kkmHIAQ', '01tHs000008kn8xIAA', '01tHs00000A84niIAB', '01tHs000008kmLHIAY', '01tHs000008klBMIAY', '01tHs000008kkgaIAA', '01tHs000008knrdIAA', '01tHs000008klhqIAA', '01tHs000008knZ5IAI', '01tHs000008kksdIAA', '01tHs000008kkw0IAA', '01tHs000008knOIIAY', '01tHs000008knYYIAY', '01tHs000008kktJIAQ', '01tHs000008kkUyIAI', '01tHs000008kln6IAA', '01tHs000008km8cIAA', '01tHs000008kkpiIAA', '01tHs000008kk97IAA', '01tHs000008knWxIAI', '01tHs000008knCcIAI', '01tHs000008kn3kIAA', '01tHs000008km1tIAA', '01tHs000008knsbIAA', '01tHs000008knvrIAA', '01tHs000008kmtPIAQ', '01tHs000008klccIAA', '01tHs000008kloyIAA', '01tHs000008klILIAY', '01tHs000008kle8IAA', '01tHs00000A6jEmIAJ', '01tHs000008knoVIAQ', '01tHs000008kmUQIAY', '01tHs000008kl1pIAA', '01tHs000008kkGMIAY', '01tHs000008knuCIAQ', '01tHs000008klWIIAY', '01tQo000006l6JRIAY']

  async handleTest() {
    let config = {
      disableMultiProductSOB: false,
      endDate: "1747938600000",
      internalUse: true,
      salesOrg: 'US10',
      recencyFactor: 300,
      steepnessFactor: 30,
      maxRecs: 20,
      samplesetSize: 200,
      sameOrderBoost: 300
    };

    // Create methods for each product part number and get recommendations. Use promise.all
    let promises = this.topPn.map(pn => {
      return getProductRecommendationsSAP({
        productIds: [pn],
        configuration: config
      });
    });

    try {
      let results = await Promise.all(promises);
      let debugString = results.map(res => res.debugArray).join('\n');
      console.log(debugString);
    } catch (error) {
      console.error('Error fetching recommendations for top PNs:', error);
      this.displayError('Error fetching recommendations for top PNs: ' + error.message);
    }
  }

  async handleTest2() {
    try {
      let promises = this.topPn.map((pn,i) => {
        return getCustomersAlsoBought({
          productIdentifiers: [pn],
          configuration: {
            debugMode: true,

            // calculateAccuracy: true,
            // accuracyStartDate: '2025-01-01',
            // accuracyEndDate: '2025-05-23',
            // startDate: '2023-01-01',
            // endDate: '2025-02-01',
            maxRecsToReturn: 10
          }
        });
      });

      let results = await Promise.allSettled(promises);
      console.log(results);

      let debugString = results.map(res => res.value?.debugArray).filter(el=>el).join('\n');
      alert(debugString);
      console.log(debugString);

      let a1=0,c1=0,a2=0,c2=0,a3=0,c3=0,a4=0,c4=0;
      results.forEach(r=>{
        if(r.value?.periodAccuracy && !isNaN(r.value.periodAccuracy)) {
          a1 += parseFloat(r.value.periodAccuracy);
          c1++;
        }
        if(r.value?.totalAccuracy && !isNaN(r.value.totalAccuracy)) {
          a2 += parseFloat(r.value.totalAccuracy);
          c2++;
        }
        if(r.value?.periodCustomerLevelAccuracy && !isNaN(r.value.periodCustomerLevelAccuracy)) {
          a3 += parseFloat(r.value.periodCustomerLevelAccuracy);
          c3++;
        }
        if(r.value?.totalCustomerLevelAccuracy && !isNaN(r.value.totalCustomerLevelAccuracy)) {
          a4 += parseFloat(r.value.totalCustomerLevelAccuracy);
          c4++;
        }
      })
      console.log('Avg period accuracy: ' + (a1/c1));
      console.log('Avg total accuracy: ' + (a2/c2));
      console.log('Avg period customer level accuracy: ' + (a3/c3));
      console.log('Avg total customer level accuracy: ' + (a4/c4));
    } catch (error) {
      console.error('Error fetching recommendations for top PNs:', error);
      this.displayError('Error fetching recommendations for top PNs: ' + error.message);
    }
  }
}