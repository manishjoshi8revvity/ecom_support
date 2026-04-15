({    
    // helper method to present a toast 
    showToast : function(typ, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": msg,
            "type" : typ
        });
        toastEvent.fire();
    }
})