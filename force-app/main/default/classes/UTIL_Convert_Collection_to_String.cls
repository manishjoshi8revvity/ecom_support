/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Utillity class for conversion of collection to String
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: True
  *
  * 7. Test Class Name: UTIL_Convert_Collection_to_String_Test
  *
  * 8. Author Name(s): 
  *    -AP/VG 202.09.22 Base
  *    -BD 2024.04.30 Added Dedupe parameter (True is default)/Added Sort Parameter (True is Default/False=Original Order)
  *    -BD 2024.04.30 Added 2nd output option as collection
  *    -
*************************************************************/ 
public class UTIL_Convert_Collection_to_String {

    @InvocableMethod
    public static List<FlowOutputs> flowcalled(List<FlowInputs> requests) {
        List<FlowOutputs> fOutlist = new List<FlowOutputs>();

        // 1. Loop through each input record passed from Flow
        if (requests != null && !requests.isEmpty()) {
            for (FlowInputs finpt : requests) {
                FlowOutputs fout = new FlowOutputs();
                List<String> workingList = new List<String>();
                Set<String> seen = new Set<String>();

                // 2. Loop through input list and trim each item
                for (String item : finpt.liststring) {
                    String trimmed = item?.trim();
                    if (trimmed == null) continue;

                    // 3. If deduplication is disabled, always add
                    //    If enabled (or null), add only if not already seen
                    if (finpt.dedupe == false) {
                        workingList.add(trimmed);
                    } else if (!seen.contains(trimmed)) {
                        workingList.add(trimmed);
                        seen.add(trimmed);
                    }
                }

                // 4. Sort alphabetically if requested (default = true)
                if (finpt.sortValues == null || finpt.sortValues == true) {
                    workingList.sort();
                }

                // 5. Create the output string using semicolon delimiter
                fout.varString = String.join(workingList, ';');

                // 6. Return both the cleaned list and the joined string
                fout.liststring = workingList;
                fOutlist.add(fout);
            }
        }

        return fOutlist;
    }

    public class FlowInputs {
        @InvocableVariable public List<String> liststring;     // Input collection of text values
        @InvocableVariable public Boolean dedupe;              // Optional: remove duplicates (default = true)
        @InvocableVariable public Boolean sortValues;          // Optional: sort alphabetically (default = true)
    }

    public class FlowOutputs {
        @InvocableVariable public String varString;            // Output string (joined with semicolons)
        @InvocableVariable public List<String> liststring;     // Cleaned and deduped list
    }
}