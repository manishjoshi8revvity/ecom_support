public with sharing class BL_PunchoutLogsAnalyzerController {
    @AuraEnabled
    public static List<AggregateResult> getPunchoutLogs(Map<String,Object> config) {
        return BL_PunchoutLogsAnalyzerRepo.fetchPunchoutLogs(config);
    }

    @AuraEnabled
    public static List<AggregateResult> getPunchoutLogsByCustomer(Map<String,Object> config) {
        return BL_PunchoutLogsAnalyzerRepo.fetchPunchoutLogsByCustomer(config);
    }

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getCustomerNames(Boolean includeTest) {
        return BL_PunchoutLogsAnalyzerRepo.fetchCustomerNames(includeTest);
    }

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getCurrencyValues(Boolean includeTest) {
        return BL_PunchoutLogsAnalyzerRepo.fetchCurrencyValues(includeTest);
    }
}