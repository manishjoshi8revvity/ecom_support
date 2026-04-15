({
    init : function( component, event, helper ) {
        
        var action =component.get("c.checkInfCaseUsrPermisson");

        action.setCallback(this, function(response){
           
            var state = response.getState();
            if(state === "SUCCESS")
            {
                console.log(JSON.stringify(response.getReturnValue()));
               
                if(response.getReturnValue())
                {
                    component.set('v.legacyCreatePermission',true); 
                    helper.openCreateRcrdCmp(component, event, helper);
                    

                }
                else
                {
                    
                    let objFlow = component.find( "flowData" );
                    objFlow.startFlow("S_FLOW_2401_Case_Create_Default");
                }
               
            }
        });
        $A.enqueueAction(action);
        
    }
})