// JavaScript source code
window.InteropForm = {
    handler: null,
    SnapPayURL: null,
    dvinterop_hostedform: function () {
        var e;
        if (document.querySelector("#interop_form")) {
            var x = document.querySelectorAll("#interop_form");
            var i = x.length;
            if (i > 0) {
                e = x[i - 1].attributes;
            }
            else {
                console.error("Cannot find #interop_form attributes.");
                return;
            }
        }
        else {
            console.error("Cannot find #interop_form attributes.");
            return;
        }
        var result = "";
        var iURL = "";
        var reference = "";
        for (var o = 0; o < e.length; o++) {
            var s = e[o];
            if (s.name === "data-requestid") {
                result = s.value;
            }
            else if (s.name === "data-interopurl") {
                iURL = s.value;
                SnapPayURL = s.value;
            }
            if (s.name === "data-reference") {
                reference = s.value;
            }
        }
        if (result !== '' && result !== undefined && iURL !== '' && iURL !== undefined) {
            var t = document.createElement("div");
            t.setAttribute("id", "interopform_overlay");
            t.setAttribute("style", "position:fixed; top:0; left:0; bottom:0; right:0; width:100%; height:100%; border:none; margin:0; padding:0; overflow:hidden; z-index:999999; background: rgba(0,0,0,0.4);");
            document.querySelector("body").appendChild(t);
            document.querySelector("body").style.overflowY = "auto";

            var a = document.createElement("iframe");
            a.setAttribute("id", "interopform_iframe");
            a.setAttribute("title", "Payment Form");
            if (reference !== '' && reference === 'hostedpaymentpage') {
                a.setAttribute("style", "position:fixed; top:0; left:0; bottom:0; right:0; width:100%; height:100%; border:none; margin:0; padding:0; overflow:hidden; z-index:999999; background-color: #FFFFFF;");
            }
            else {
                a.setAttribute("style", "position:fixed; top:0; left:0; bottom:0; right:0; width:100%; height:100%; border:none; margin:0; padding:0; overflow:hidden; z-index:999999; background-color: rgba(0,0,0,0.4);");
            }

            var r = iURL + "/Interop/InteropForm";
            r += "?reqId=" + encodeURIComponent(result);
            a.setAttribute("src", r);
            document.querySelector("body").appendChild(a);
            window.removeEventListener("message", InteropForm.messageListener);
            window.addEventListener("message", InteropForm.messageListener);
        }
        else {
            InteropForm.scriptAttributesError("Invalid request.");
            return;
        }
    },
    messageListener: function (e) {
        if (typeof e.data !== "undefined") {
            if (e.data.messageAuthor === "interopform_lightbox") {
                if (e.data.err) {
                    var tt = {
                        data: {
                            messageAuthor: "interopform_lightbox",
                            message: { response: e.data.message.response }, err: e.data.err
                        }
                    };
                    //HostedForm._set_hidden_input(HostedForm._get_hidden_input(), t);
                    //window[HostedForm.handler](t.data.err, t.data.message);
                    InteropForm._clear_iframe();
                    return;
                }
                if (e.data.message !== undefined && e.data.message !== "") {
                    var t = document.createElement("div");
                    t.setAttribute("id", "receipt_overlay");
                    t.setAttribute("style", "position:fixed; top:0; left:0; bottom:0; right:0; width:100%; height:100%; border:none; margin:0; padding:0; overflow-y:auto; z-index:999999; background: rgba(0,0,0,0.4);");
                    document.querySelector("body").appendChild(t);
                    document.querySelector("body").style.overflowY = "auto";

                    var a = document.createElement("iframe");
                    a.setAttribute("id", "receipt_iframe");
                    a.setAttribute("title", "Receipt");
                    a.setAttribute("style", "position:fixed; top:0; left:0; bottom:0; right:0; width:100%; height:100%; border:none; margin:0; padding:0; overflow-y:auto; z-index:999999;");

                    //console.log("snappay url is " + SnapPayURL);

                    var r = SnapPayURL + "/Receipt";
                    r += "?input=" + encodeURIComponent(e.data.message);
                    //console.log("url is " + r);
                    a.setAttribute("src", r);
                    document.querySelector("body").appendChild(a);
                    //console.log(document.querySelector("body"));
                }
                InteropForm._clear_iframe();
                //InteropForm._set_hidden_input(HostedForm._get_hidden_input(), e);
                //if (InteropForm.handler !== null && !HostedForm.parentOverlay) {
                //    window[HostedForm.handler](e.data.err, e.data.message)
                //}
            }
        }
    },
    scriptAttributesError: function (e) {
        console.error(e);
        InteropForm.exit_modal();
    },
    _clear_iframe: function () {
        if (document.querySelector("#interopform_iframe")) {
            document.querySelector("#interopform_iframe").remove();
        }
        InteropForm.exit_modal();
    },
    exit_modal: function () {
        if (document.querySelector("#interopform_overlay")) {
            document.querySelector("#interopform_overlay").remove();
        }
        if (document.querySelector("body")) {
            document.querySelector("body").style.overflowY = "initial";
        }
    },
    iframeListener: null
};
//InteropForm.dvinterop_hostedform();



