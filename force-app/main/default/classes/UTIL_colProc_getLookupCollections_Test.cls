@isTest
public class UTIL_colProc_getLookupCollections_Test {
    @IsTest
    static void methodName(){
        list<string> teststring = new List<string>{'01234567890wertyui','01234567890wertCGH'};
        string commaseparatedfield='Id,Name';
        string objectapi='Account';
        UTIL_colProc_getLookupCollections.fetchSobject(teststring,commaseparatedfield,objectapi);
    }
    @IsTest
    static void methodName2(){
        list<string> teststring = new List<string>{'01234567890wertyui','01234567890wertCGH'};
        string commaseparatedfield='Id,Name2';
        string objectapi='Account';
        UTIL_colProc_getLookupCollections.fetchSobject(teststring,commaseparatedfield,objectapi);
    }

}