/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-558  
*
* 2. Description - This class is used to get Site Details.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_Util
*
* 6. Test Class Name: 
*    - ECOM_SiteURL_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.07.17
*    - Vipul YYYY.MM.DD

*************************************************************/
public with sharing class ECOM_SiteURL extends VisualEditor.DynamicPickList{


    /**
    * @description 
    * @author Vipul Goyal | 09-20-2023 
    * @return VisualEditor.DynamicPickListRows 
    **/
    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows  finalSiteURLInformation = new VisualEditor.DynamicPickListRows();
        Map<String,String> mapSiteURLS = ECOM_Util.fetchStorefrontFrontConfigByModule(ECOM_Constant.MODULE_SITE_URL);
        
        for(String siteURLInfo : mapSiteURLS.keySet())
        {
            finalSiteURLInformation.addRow(new VisualEditor.DataRow(siteURLInfo , mapSiteURLS.get(siteURLInfo)));
        }
        return finalSiteURLInformation;
    }


    /**
    * @description 
    * @author Vipul Goyal | 09-20-2023 
    * @return VisualEditor.DataRow 
    **/
    public override VisualEditor.DataRow getDefaultValue() {
        String storeName = ECOM_Util.fetchConfigByValue(ECOM_Constant.SITE_SESSION_EXPIRE) ;
        if(String.isNotBlank(storeName))
        {
            return new VisualEditor.DataRow(ECOM_Constant.SITE_SESSION_EXPIRE, storeName);
        }else
        {
            return null;
        }
    }
    
}