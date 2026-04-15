var _this = _this || this;
var revvityGTM =  {
    pushData : function(data){
        dataLayer.push(data);
    },
    loadIframe : function(){
        const noscript = document.createElement("noscript");
        const iframe = document.createElement("iframe");
        iframe.style.display = "none";
        iframe.style.visibility = "hidden";
        iframe.style.width = "0";
        iframe.style.height = "0";
        iframe.src = "https://www.googletagmanager.com/ns.html?id=GTM-K5JRJZCK";
        noscript.appendChild(iframe);
        const fisrtChild = document.body.firstElementChild;
        document.body.insertBefore(noscript,fisrtChild);
    }
};
