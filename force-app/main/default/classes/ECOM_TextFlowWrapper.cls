/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - RWPS - 5611
 *
 * 2. Description - It is a wrapper class used in SUB.FLOW_4478: ECOM - Fetch Latest Order Details
 *
 * 3. Objects referenced
 * - None
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - None
 *
 * 6. Test Class Name:
 * - ECOM_TextFlowWrapper_Test
 *
 * 7. Is @Invocable (Yes or No): Yes
 *
 * 8. Author Name(s):
 * - Sachin Vispute 2026.01.02 Created the class consisting of Input, Output Wrapper along with invocable method - RWPS-5611
*************************************************************/
public class ECOM_TextFlowWrapper {

    // Input wrapper
    public class RequestWrapper {
        @InvocableVariable(label = 'Input Text' required = true)
        public String inputText;

        @InvocableVariable(label = 'Separator' required = true)
        public String separator;
    }

    // Output wrapper
    public class ResponseWrapper {
        @InvocableVariable(label='Split Values')
        public List<String> splitValues;

        @InvocableVariable(label='Formatted Values')
        public String formattedValues;
    }


    /**
    * @description This method splits a single input string using the provided separator
    * @author Sachin Vispute | 2026.01.02 | RWPS-5611
    * @params inputs | List<RequestWrapper>
    * @return List<ResponseWrapper>
    **/
    @InvocableMethod(label='Split String by Separator' description='Splits a single input string using the provided separator')
    public static List<ResponseWrapper> splitText(List<RequestWrapper> inputs) {
        RequestWrapper input = (inputs != null && !inputs.isEmpty()) ? inputs[0] : null;
        ResponseWrapper output = new ResponseWrapper();

        List<String> splitValues = new List<String>();
        String formattedValues = '';

        if (input != null && String.isNotBlank(input.inputText) && String.isNotBlank(input.separator)) {
            // Strip outer parentheses and split
            String trimmedString = input.inputText.trim(); // Remove leading/trailing whitespace
            if (trimmedString.startsWith('(') && trimmedString.endsWith(')') && trimmedString.length() >= 2) {
                trimmedString = trimmedString.substring(1, trimmedString.length() - 1); // Remove outer parentheses
            }

            for (String part : trimmedString.split(input.separator)) { // Split using the provided separator
                String temp = (part == null) ? '' : part.trim();
                if (String.isNotBlank(temp)) {
                    splitValues.add(temp);
                }
            }
        }

        if (!splitValues.isEmpty()) {
            List<String> formattedValuesList = new List<String>();
            for (String value : splitValues) {
                String escaped = value.replace('\'', '\\\''); // Escape single quotes
                formattedValuesList.add('\'' + escaped + '\''); // Adding single quotes around each value
            }
            formattedValues = String.join(formattedValuesList, ',');
        }

        output.splitValues = splitValues;
        output.formattedValues = formattedValues;

        return new List<ResponseWrapper>{ output };
    }
}