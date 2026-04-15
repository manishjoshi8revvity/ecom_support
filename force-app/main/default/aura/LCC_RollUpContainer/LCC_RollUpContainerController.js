({
    doInit: function(component,event,helper) {  
        component.set("v.showSpinner",true);
        var action = component.get('c.getCounterRecords'); 
        var payloadString = JSON.stringify({ recId : component.get("v.recordId"),
                                            metadataLabel : component.get("v.mappingFor") });
        action.setParams({payload : payloadString }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS' && component.isValid()) {               
                var result = JSON.parse(response.getReturnValue());
                component.set("v.showSpinner",false);
                // if an error occured server side then present it now
                if(result.isError) {
                    component.set("v.noResultsLabel", result.message);
                    helper.showToast('error','An error has occured',result.message);
                    console.log('**ERROR**',result.message);
                }
                
                component.set("v.resultantRollup", result.rollUps); // pass options back into the UI
                component.set("v.noResults", result.rollUps.length == 0); // to drive UI msg
                
            }
            else if (state === "INCOMPLETE") {
                component.set("v.showSpinner",false);
                helper.showToast('error','An unknown error has occured','Please try again or contact your administrator.');
            }
                else if (state === "ERROR") {
                    component.set("v.showSpinner",false);
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            helper.showToast('error','An error has occured',errors[0].message);
                        }
                    } else {
                        helper.showToast('error','An unknown error has occured','Please try again or contact your administrator.');
                    }
                }
        });
        $A.enqueueAction(action);
    }   
})