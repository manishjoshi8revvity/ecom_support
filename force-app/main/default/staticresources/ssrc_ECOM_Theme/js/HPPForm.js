// JavaScript source code
window.HPPForm = {    
    handler: null,
    parentOverlay: false,
    handshakePassed: false,
    handshakeCheck: null,
    dvsnappay_hppform: function () {
        var e;
        if (document.querySelector("#snappay_hppform")) {
            e = document.querySelector("#snappay_hppform").attributes;
        }
        else {
            console.error("Cannot find #snappay_hppform attributes.");
            return;
        }
        var result = 0;
        var outputResponse = [];
        var vMessage = "";
        var object = {};
        var baseUrl = "";
        var redirectURL = "";
        for (var o = 0; o < e.length; o++) {
            var s = e[o];
            if (s.name === "data-callback" &&  HPPForm.handler===null) {
                HPPForm.handler = s.value;
            }
            else if (s.name === "data-parentoverlay") {
                if (s.value === "true") {
                    HPPForm.parentOverlay = true;
                }
            }
            else if (s.name === "data-accountid") {
                object["accountid"] = s.value;
            }
            else if (s.name === "data-customerid") {
                object["customerid"] = s.value;
            }
            else if (s.name === "data-merchantid") {
                object["merchantid"] = s.value;
            }
            else if (s.name === "data-transactionamount") {
                object["transactionamount"] = s.value;
                if (s.value === "") {
                    object["transactionamount"] = "0";
                }
                object["transactionamounttext"] = s.value;
            }
            else if (s.name === "data-currencycode") {
                object["currencycode"] = s.value;
            }
            else if (s.name === "data-paymentmode") {
                object["paymentmode"] = s.value;
            }
            else if (s.name === "data-cvvrequired") {
                object["cvvrequired"] = s.value;
            }
            else if (s.name === "data-enableemailreceipt") {
                object["enableemailreceipt"] = s.value;
            }
            else if (s.name === "data-enableprintreceipt") {
                object["enableprintreceipt"] = s.value;
            }
            else if (s.name === "data-customid") {
                object["customid"] = s.value;
            }
            else if (s.name === "data-redirectionurl") {
                object["redirectionurl"] = s.value;
                redirectURL = s.value;
            }
            else if (s.name === "data-snappayurl") {
                object["snappayurl"] = s.value;
                baseUrl = s.value;
            }
            else if (s.name === "data-udf0") {
                object["udf0"] = s.value;
            }
            else if (s.name === "data-udf1") {
                object["udf1"] = s.value;
            }
            else if (s.name === "data-udf2") {
                object["udf2"] = s.value;
            }
            else if (s.name === "data-udf3") {
                object["udf3"] = s.value;
            }
            else if (s.name === "data-udf4") {
                object["udf4"] = s.value;
            }
            else if (s.name === "data-udf5") {
                object["udf5"] = s.value;
            }
            else if (s.name === "data-udf6") {
                object["udf6"] = s.value;
            }
            else if (s.name === "data-udf7") {
                object["udf7"] = s.value;
            }
            else if (s.name === "data-udf8") {
                object["udf8"] = s.value;
            }
            else if (s.name === "data-udf9") {
                object["udf9"] = s.value;
            }
            else if (s.name === "data-udf9") {
                object["udf9"] = s.value;
            }
            else if (s.name === "data-firstname") {
                object["firstname"] = s.value;
            }
            else if (s.name === "data-lastname") {
                object["lastname"] = s.value;
            }
            else if (s.name === "data-addressline1") {
                object["addressline1"] = s.value;
            }
            else if (s.name === "data-city") {
                object["city"] = s.value;
            }
            else if (s.name === "data-state") {
                object["state"] = s.value;
            }
            else if (s.name === "data-zip") {
                object["zip"] = s.value;
            }
            else if (s.name === "data-country") {
                object["country"] = s.value;
            }
            else if (s.name === "data-email") {
                object["email"] = s.value;
            }
            else if (s.name === "data-phonenumber") {
                object["phonenumber"] = s.value;
            }
            else if (s.name === "data-signature") {
                object["signature"] = s.value;
            }
            else if (s.name === "data-redirectionurlonerror") {
                object["redirectionurlonerror"] = s.value;
            }
            else if (s.name === "data-deviceentry") {
                object["deviceentry"] = s.value;
            }            
            else if (s.name === "data-transactiontype") {
                object["transactiontype"] = s.value;
            }
            else if (s.name === "data-language") {
                object["language"] = s.value;
            }
            else if (s.name === "data-parenturi") {
                object["parenturi"] = s.value;
            }
        }

        jQuery(function ($) {           
            if (result === 0) {    
                var url = baseUrl + "/GetInputFromJS";  
                var interopJSURL = "";
                var interopReqNo = "";
                var interopMainURL = "";    
                var errorMessage = "";
                $.ajax({
                    cache: false,
                    url: url,
                    type: "POST",
                    async: false,
                    dataType: "json",
                    data: { input: JSON.stringify(object) },
                    success: function (data) {
                        interopJSURL = data.success.interopJSURL;
                        interopReqNo = data.success.interopReqNo;
                        interopMainURL = data.success.interopMainURL;
                        vMessage = data.success.errorMessage;
                        outputResponse = [interopJSURL, interopReqNo, interopMainURL];
                        if (interopReqNo !== "" && interopJSURL !== "" && interopMainURL !== "") {
                            result = 1;
                        }
                    },
                    error: function (request, status, error) {
                        vMessage = error;
                    }
                });
            }

            if (result > 0) {
                if (HPPForm.handshakePassed === true) {
                    //$("#snappay_hppform").attr("data-sessionid", result);
                    if ($("#snappay_hppform").attr("data-jsurl") === null || $("#snappay_hppform").attr("data-jsurl") === undefined) {
                        var jsurl = baseUrl;
                        $("#snappay_hppform").attr("data-jsurl", jsurl);
                    }
                    HPPForm.sendOverlayMessageUp();
                    return;
                }
               
                // var t = document.createElement("script");
                // t.setAttribute("id", "interop_form");
                // t.setAttribute("src", outputResponse[0]);
                // t.setAttribute("data-requestid", outputResponse[1]);
                // t.setAttribute("data-interopurl", outputResponse[2]);                
                // document.querySelector("body").appendChild(t);
                // document.querySelector("body").style.overflowY = "hidden";
                payment.initilizeHostedPage(outputResponse);
                if (!HPPForm._get_hidden_input() && !HPPForm.handler) {
                    HPPForm.scriptAttributesError("Cannot find a handler function or a hidden input field. Please pass the name of your js handler function to 'data-handler' and/or pass the selector for your hidden input field to 'data-target'"); return;
                }
                window.removeEventListener("message", HPPForm.messageListener);
                window.addEventListener("message", HPPForm.messageListener);
            }
            else {
                var z = {
                    data: {
                        messageAuthor: "hppform_lightbox",
                        message: { response: vMessage },
                        err: ""
                    }
                };
                HPPForm._set_hidden_input(HPPForm._get_hidden_input(), z);
                window[HPPForm.handler](z.data.err, z.data.message);
                HPPForm._clear_iframe();
                var msg = JSON.stringify(z.data.message);
                window.parent.postMessage(msg, "*");
                if (redirectURL !== "#") {     
                    //CDC-InteropRedirectCommand-HPPForm/jQuery
                    window.parent.location = redirectURL;
                }   
                return;
            }
        });
    },
    messageListener: function (e) {
        if (typeof e.data !== "undefined") {
            if (e.data.messageAuthor === "hppform_lightbox") {
                if (HPPForm.parentOverlay) {
                    var p = {
                        messageAuthor: e.data.messageAuthor,
                        message: e.data.message,
                        err: e.data.err
                    };
                    HPPForm_nested.nestedSender.postMessage(p, "*");
                }
                if (e.data.err && !HPPForm.parentOverlay) {
                    var t = {
                        data: {
                            messageAuthor: "hppform_lightbox",
                            message: { response: e.data.message.response },
                            err: e.data.err
                        }
                    };
                    HPPForm._set_hidden_input(HPPForm._get_hidden_input(), t);
                    window[HPPForm.handler](t.data.err, t.data.message);
                    HPPForm._clear_iframe();
                    return;
                }
                if (e.data.message !== undefined && e.data.message !== "") {
                    var jsonData = e.data.message;
                    var res = HPPForm.createResponseForJS(jsonData, e.data.baseurl);
                    var z = {
                        data: {
                            messageAuthor: "hppform_lightbox",
                            message: { response: res },
                            err: e.data.err
                        }
                    };
                    HPPForm._set_hidden_input(HPPForm._get_hidden_input(), z);
                    window[HPPForm.handler](z.data.err, z.data.message);                    
                    HPPForm._clear_iframe();
                    var msg = JSON.stringify(z.data.message);
                    window.parent.postMessage(msg, "*");
                    if (e.data.redirecturl !== "#") {
                        //CDC-InteropRedirectCommand-HPPForm/messageListener
                        window.parent.location = e.data.redirecturl;
                    }                   
                    return;
                }
            HPPForm._clear_iframe();
            HPPForm._set_hidden_input(HPPForm._get_hidden_input(), e);
            if (HPPForm.handler !== null && !HPPForm.parentOverlay) {
                window[HPPForm.handler](e.data.err, e.data.message);
                }
            }
            else if (e.data.messageAuthor === "hppform_lightbox_handshake") {
                if (e.data.message === HPPForm.handshakeCheck + 1) {
                    HPPForm.handshakePassed = true;
                }
            }
        }
    },
    createResponseForJS: function (param, redirectto) {
        var returnMsg = "";        
        var url = redirectto + "/HostedPaymentPage/SetOutputForJS"; 
        $.ajax({
            //cache: false,
            url: url,
            type: "POST",
            async: false,
            dataType: "json",
            data: { input: param },
            success: function (data) {
                returnMsg = data.success.returnMsg;
            },
            error: function (request, status, error) {
                returnMsg = error;
            }
        });
        //console.log(returnMsg);
        return returnMsg;
    },
    _get_hidden_input: function () {
        if (document.querySelector("#snappay_hppform").getAttribute("data-target")) {
            return document.querySelector(document.querySelector("#snappay_hppform").getAttribute("data-target"));
        } return null;
    },
    _set_hidden_input: function (e, t) {
        if (e) {
            if (t.data.err) {
                e.value = JSON.stringify(t.data.err);
            }
            else {
                e.value = JSON.stringify(t.data.message);
            }
        }
    },
    scriptAttributesError: function (e) {
        console.error(e);
        var t = {
            data: { messageAuthor: "hppform_lightbox", message: { response: e }, err: new Error(e) }
        };
        HPPForm._set_hidden_input(HPPForm._get_hidden_input(), t);
        if (typeof window[HPPForm.handler] === "function") {
            window[HPPForm.handler](t.data.err, t.data.message);
        }
        HPPForm._clear_iframe();
    },
    _clear_iframe: function () {
        if (document.querySelector("#interopform_iframe")) {
            document.querySelector("#interopform_iframe").remove();
        }
        if (document.querySelector("#receipt_iframe")) {
            document.querySelector("#receipt_iframe").remove();
        }
        HPPForm.exit_modal();
    },
    exit_modal: function () {
        if (document.querySelector("#interopform_overlay")) {
            $("#interopform_overlay").remove();
        }
        if (document.querySelector("body")) {
            document.querySelector("body").style.overflowY = "initial";
        }
        if (document.querySelector("#receipt_overlay")) {
            $("#receipt_overlay").remove();
        }        
    },
    sendOverlayMessageUp: function () {
        var e = document.querySelector("#snappay_hppform");
        var t = e.outerHTML;
        var a = {
            messageAuthor: "hppform_lightbox_overlay", message: t
        };
        window.parent.postMessage(a, "*");
    },
    initiateOverlayHandshake: function () {
        HPPForm.handshakeCheck = Math.floor(Math.random() * 1e6);
        var e = { messageAuthor: "hppform_lightbox_handshake", message: HPPForm.handshakeCheck };
        window.parent.postMessage(e, "*"); setTimeout(function () {
            if (!HPPForm.handshakePassed) {
                console.warn("'data-overlayonparent' was passed as 'true' but 'cdi_nested_lightbox.js' was not found on the parent page");
            }
        }, 2e3);
    },
    onCreditCardSelect : function(){
        HPPForm.dvsnappay_hppform();
    },
    bindEventListener : function(){
        window.addEventListener("message", HPPForm.messageListener);
        if (document.querySelector("#snappay_hppform").hasAttribute("data-overlayonparent") && document.querySelector("#snappay_hppform").getAttribute("data-overlayonparent") === "true") {
            HPPForm.initiateOverlayHandshake();
        }
    },
    iframeListener: null
};

// window.addEventListener("message", HPPForm.messageListener);
// if (document.querySelector("#snappay_hppform").hasAttribute("data-overlayonparent") && document.querySelector("#snappay_hppform").getAttribute("data-overlayonparent") === "true") {
//     HPPForm.initiateOverlayHandshake();
// }

//  HPPForm.dvsnappay_hppform();





