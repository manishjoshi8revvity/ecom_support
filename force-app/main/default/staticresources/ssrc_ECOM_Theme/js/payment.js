var _this = _this || this;
var isPaymentInitilized = false;
var isPaymentresponseRecieved = false;
var componentReference;
var snapPayStage = "https://stage.snappayglobal.com/Interop/HostedPaymentPage";
var snapPayGlobal = "https://www.snappayglobal.com/Interop/HostedPaymentPage";
window.interopForm = '';
//https://revvity--ecomdev.sandbox.my.site.com/checkout?payment=true
function paymentCallBack(error,message){
    //Send post message to LWC
    document.body.style.overflowY = "auto";
    if(!isPaymentresponseRecieved){
        componentReference.creditCardPaymentResponse(error,message);
    }
    isPaymentresponseRecieved = true;
 }
var payment =  {
    
    init :  function(options,comReference){
        isPaymentresponseRecieved = false;
        interopForm = options.interopForm;
        componentReference = comReference;
        if(isPaymentInitilized){
            let snappay_hppform = document.getElementById("snappay_hppform"); 
            snappay_hppform.remove();  
            let interop_form = document.getElementById("interop_form"); 
            interop_form.remove();  
            isPaymentInitilized = false;
            
        }  
        if(!isPaymentInitilized){
            isPaymentInitilized =  true;
            let scriptEle = document.createElement("script");
            //scriptEle.setAttribute("src", "https://stage.snappayglobal.com/Areas/Interop/Scripts/HPPForm.js");
            scriptEle.setAttribute("src", options.hppUrl);

            scriptEle.setAttribute("id", "snappay_hppform");
            scriptEle.setAttribute("data-target", "#snappayhppform_response");
            scriptEle.setAttribute("data-callback", "paymentCallBack");
            scriptEle.setAttribute("data-accountid", options.accountId);
            scriptEle.setAttribute("data-customerid", options.customerId);
            //scriptEle.setAttribute("data-currencycode", "USD");

            scriptEle.setAttribute("data-currencycode", options.currencycode);
            scriptEle.setAttribute("data-transactionamount", options.amount);

            //scriptEle.setAttribute("data-transactionamount", "123");
            scriptEle.setAttribute("data-merchantid", options.merchantId);
            scriptEle.setAttribute("data-transactiontype", "A");
            scriptEle.setAttribute("data-paymentmode", "CC");
            scriptEle.setAttribute("data-cvvrequired", "Y");
            scriptEle.setAttribute("data-enableemailreceipt", "Y");
            scriptEle.setAttribute("data-redirectionurl", "#");
            if(options.environment == 'Stage'){
                scriptEle.setAttribute("data-snappayurl", snapPayStage);
            }
            else{
                scriptEle.setAttribute("data-snappayurl", snapPayGlobal);
            }
            scriptEle.setAttribute("data-lastname", options.lastName);
            scriptEle.setAttribute("data-firstname", options.firstName);
            scriptEle.setAttribute("data-addressline1", options.street);
            scriptEle.setAttribute("data-city", options.city);
            scriptEle.setAttribute("data-state", options.state);
            scriptEle.setAttribute("data-zip", options.zip);
            scriptEle.setAttribute("data-country",options.country);
            scriptEle.setAttribute("data-email",options.email);
            scriptEle.setAttribute("data-phonenumber",options.phone);
            scriptEle.setAttribute("data-signature",payment.generateHMAC(options));
            document.body.appendChild(scriptEle);
            setTimeout(() => {
                payment.initilizeHPPForm();
            }, 50);
        }
    },
    initilizeHostedPage : function(outputResponse){
        var t = document.createElement("script");
        t.setAttribute("id", "interop_form");
        t.setAttribute("src", interopForm);
        t.setAttribute("data-requestid", outputResponse[1]);
        t.setAttribute("data-interopurl", outputResponse[2]);                
        document.body.appendChild(t);
       // document.body.style.overflowY = "hidden";
        setTimeout(() => {
            InteropForm.dvinterop_hostedform();
        }, 20);
       
    },
    callbackFunction : function(){
        
     },
     initilizeHPPForm : function(){
        HPPForm.bindEventListener();
        HPPForm.onCreditCardSelect();
     },
    generateHMAC : function(options){
        //set options dynamically later
        let apiAuthCode  = options.authCode;
        let accountid = options.accountId;
        let customerid = options.customerId;
        let merchantid = options.merchantId;
        let transactionamount = options.amount;
        let currencycode = options.currencycode;// "USD";
        let paymentmode = "CC";
        let email = options.email;//"john.smith@abcd.com";
        let txtnonce = payment.createGuid();
        let txttimestamp = "";
        let epochStart = new Date(Date.UTC(1970, '01', '01', 0, 0, 0, 0));
        let timeSpan = Date.now() - epochStart;
        txttimestamp = timeSpan;
        let signatureRawData = accountid + customerid + merchantid + transactionamount +
        currencycode + paymentmode + email + txtnonce + txttimestamp;
        let secretkey = CryptoJS.enc.Base64.parse(apiAuthCode);
        let prehash = CryptoJS.enc.Utf8.parse(signatureRawData);
        let hash = CryptoJS.HmacSHA256(prehash, secretkey);
        let signature = hash.toString(CryptoJS.enc.Base64);
        let signatureData = signature + ":" + txtnonce + ":" + txttimestamp;
        let prehash1 = CryptoJS.enc.Utf8.parse(signatureData);
        let HmacValue = prehash1.toString(CryptoJS.enc.Base64);
        return HmacValue;
    },
    createGuid : function(){
        return 'xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            let r = Math.random()*16|0, v = c === 'x' ? r : (r&0x3|0x8);
                return v.toString(16);
            });
    },
    calback : function(){

    }

};
function loadPayment(){
    payment.init();
};