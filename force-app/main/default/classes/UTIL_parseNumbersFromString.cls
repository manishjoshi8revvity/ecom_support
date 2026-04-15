/**************************************************************
  * 1. Ticket(s) that relates to this class
  *    - OM-345
  *
  * 2. Description - This is to pull the numeic characters from a string in a FLOW
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
  * 6. Test Class Name: UTIL_parseNumbersFromStringTest
  *
  * 7. Is @Invocable (Yes or No):  Yes
  *
  * 8. Author Name(s): 
  *    - Brad Durbin 2024.04.01
  *
*************************************************************/ 

public class UTIL_parseNumbersFromString {
     @InvocableMethod(label='Extract Numbers from String')
    public static List<String> extractNumbersFromString(List<String> inputStrings) {
        List<String> outputNumbers = new List<String>();
        
        for(String inputString : inputStrings) {
            String[] words = inputString.split('[^0-9]+');
            String concatenatedNumbers = '';
            
            for(String word : words) {
                if(!String.isBlank(word)) {
                    // Concatenate the number to the string
                    concatenatedNumbers += word;
                }
            }
            
            outputNumbers.add(concatenatedNumbers);
        }
        
        return outputNumbers;
    }
}