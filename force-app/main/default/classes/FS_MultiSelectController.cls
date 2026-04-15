global class FS_MultiSelectController { 
    string Ids = ApexPages.currentPage().getParameters().get('services');
    global FS_MultiSelectController(ApexPages.StandardController acon) {
        System.debug('IDS = ' + this.getMultipleIds());
    }
    global string getMultipleIds(){
       return Ids;
    }
}