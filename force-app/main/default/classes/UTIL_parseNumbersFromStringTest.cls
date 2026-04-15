/**************************************************************
  * 1. Ticket(s) that relates to this class
  *    - ATEAM-####
  *    - INC00#####
  *
  * 2. Description - This class provides a method to parse numbers from a string input and return them as a list of doubles.
  *
  * 3. Objects referenced
  *    - None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: NumberParserTest
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - [Your Name] & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
@isTest
private class UTIL_parseNumbersFromStringTest {
    @isTest
    static void testExtractNumbersFromString() {
        // Test input strings
        List<String> testStrings = new List<String>{
            'The price is $12.50',
            'There are 5 apples and 3 oranges',
            'Invalid number: abc',
            'No numbers in this string',
            '123',
            '-456.78'
        };
        
        // Expected output numbers
        List<List<String>> expectedOutput = new List<List<String>>{
            new List<String>{'1250'},
            new List<String>{'53'},
            new List<String>{},
            new List<String>{},
            new List<String>{'123'},
            new List<String>{'45678'}
        };
        
        Test.startTest();
        
        // Call the extractNumbersFromString method for each test string
        List<String> actualOutput = UTIL_parseNumbersFromString.extractNumbersFromString(testStrings);
        
        Test.stopTest();
        
        // Verify the output matches the expected values
        System.assertEquals(expectedOutput.size(), actualOutput.size(), 'Output size mismatch');
        for(Integer i = 0; i < expectedOutput.size(); i++) {
            System.assertEquals(String.join(expectedOutput[i], ','), actualOutput[i], 'Output mismatch at index ' + i);
        }
    }
}