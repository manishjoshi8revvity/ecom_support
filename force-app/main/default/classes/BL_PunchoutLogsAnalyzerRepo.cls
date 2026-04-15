public without sharing class BL_PunchoutLogsAnalyzerRepo {
    public static List<AggregateResult> fetchPunchoutLogs(Map<String,Object> config) {
        String fields;
        String groups;
        String order;

        String grouping = (String) config.get('grouping');

        if(grouping == 'day') {
            fields = 'DAY_ONLY(POSR_Timestamp__c) posrDate';
            groups = 'DAY_ONLY(POSR_Timestamp__c)';
        } else if(grouping == 'month') {
            fields = 'CALENDAR_MONTH(POSR_Timestamp__c) posrMonth, CALENDAR_YEAR(POSR_Timestamp__c) posrYear';
            groups = 'CALENDAR_MONTH(POSR_Timestamp__c), CALENDAR_YEAR(POSR_Timestamp__c)';
        } else {
            fields = 'DAY_IN_WEEK(POSR_Timestamp__c) posrWeekday';
            groups = 'DAY_IN_WEEK(POSR_Timestamp__c)';
            order = 'DAY_IN_WEEK(POSR_Timestamp__c) ASC';
        }

        String query = 'SELECT SUM(Order_Total__c) orderTotal, COUNT(POSR_Timestamp__c) posrCount, COUNT(POOM_Timestamp__c) poomCount, AVG(Order_Total__c) avgOrderTotal, Order_Total_Currency__c, SUM(Line_Items__c) lineItemsTotal, SUM(Quantity__c) quantityTotal, ' + fields + ' FROM BioLegend_Punchout_Log__c';

        query += ' WHERE DAY_ONLY(POSR_Timestamp__c) >= ' + (String) config.get('startDate') + ' AND DAY_ONLY(POSR_Timestamp__c) <= ' + (String) config.get('endDate');

        Boolean includeTest = (Boolean) config.get('test');
        if(!includeTest) {
            query += ' AND Test_Record__c != true';
        }

        List<Object> customerObj = (List<Object>) config.get('customer');
        List<String> customer = new List<String>();
        for(Object c : customerObj) {
            customer.add((String) c);
        }
        if(customer != null && !customer.isEmpty()) {
            query += ' AND Customer_Name__c IN :customer';
        }

        List<Object> totalCurrencyObj = (List<Object>) config.get('currency');
        List<String> totalCurrency = new List<String>();
        for(Object c : totalCurrencyObj) {
            totalCurrency.add((String) c);
        }
        if(totalCurrency != null && !totalCurrency.isEmpty()) {
            query += ' AND Order_Total_Currency__c IN :totalCurrency';
        }

        query += ' GROUP BY Order_Total_Currency__c, ' + groups;

        if(String.isNotBlank(order)) {
            query += ' ORDER BY ' + order;
        }

        return Database.query(query);
    }

    public static List<AggregateResult> fetchPunchoutLogsByCustomer(Map<String,Object> config) {
        String query = 'SELECT SUM(Order_Total__c) orderTotal, COUNT(POSR_Timestamp__c) posrCount, COUNT(POOM_Timestamp__c) poomCount, AVG(Order_Total__c) avgOrderTotal, Order_Total_Currency__c, Customer_Name__c, SUM(Line_Items__c) lineItemsTotal, SUM(Quantity__c) quantityTotal FROM BioLegend_Punchout_Log__c';

        query += ' WHERE DAY_ONLY(POSR_Timestamp__c) >= ' + (String) config.get('startDate') + ' AND DAY_ONLY(POSR_Timestamp__c) <= ' + (String) config.get('endDate');

        Boolean includeTest = (Boolean) config.get('test');
        if(!includeTest) {
            query += ' AND Test_Record__c != true';
        }

        List<Object> customerObj = (List<Object>) config.get('customer');
        List<String> customer = new List<String>();
        for(Object c : customerObj) {
            customer.add((String) c);
        }
        if(customer != null && !customer.isEmpty()) {
            query += ' AND Customer_Name__c IN :customer';
        }

        List<Object> totalCurrencyObj = (List<Object>) config.get('currency');
        List<String> totalCurrency = new List<String>();
        for(Object c : totalCurrencyObj) {
            totalCurrency.add((String) c);
        }
        if(totalCurrency != null && !totalCurrency.isEmpty()) {
            query += ' AND Order_Total_Currency__c IN :totalCurrency';
        }

        query += ' GROUP BY Order_Total_Currency__c, Customer_Name__c';

        query += ' ORDER BY Customer_Name__c ASC';

        return Database.query(query);
    }

    public static List<AggregateResult> fetchCustomerNames(Boolean includeTest) {
        String query = 'SELECT Customer_Name__c FROM BioLegend_Punchout_Log__c WHERE Customer_Name__c != null';

        if(!includeTest) {
            query += ' AND Test_Record__c = false';
        }

        query += ' GROUP BY Customer_Name__c ORDER BY Customer_Name__c ASC';

        return Database.query(query);
    }

    public static List<AggregateResult> fetchCurrencyValues(Boolean includeTest) {
        String query = 'SELECT Order_Total_Currency__c FROM BioLegend_Punchout_Log__c WHERE Order_Total_Currency__c != null ';

        if(!includeTest) {
            query += ' AND Test_Record__c != true';
        }

        query += ' GROUP BY Order_Total_Currency__c ORDER BY Order_Total_Currency__c ASC';

        return Database.query(query);
    }
}