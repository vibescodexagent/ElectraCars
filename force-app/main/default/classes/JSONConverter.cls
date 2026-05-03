/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : JSONConverter
 * Author          : VibeX
 * Created Date    : Apr 21, 2026
 * Last Modified By: VibeX
 * Last Modified On: Apr 21, 2026
 * Description     : This class implements for converting String Json into JSON object
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 21, 2026  │ VibeX  │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class JSONConverter {

	public class InputWrapper {
        @InvocableVariable(required=true) public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable public List<TimeSlot> timeSlot;
    }

	@InvocableMethod(label='Convert String to JSON Object'
                     description='Converts a JSON string into an Apex Object')
    public static List<OutputWrapper> convertStringToJson(List<InputWrapper> inputs) {
        
        List<OutputWrapper> results = new List<OutputWrapper>();
		TimeSlot ts = null;
        List<TimeSlot> tsLst = new List<TimeSlot>();
		for (InputWrapper input : inputs) {
            OutputWrapper output = new OutputWrapper();
            
            try {
                // Convert string to untyped JSON (Map/List structure)
                Map<String,Object> soltObj = null;
                for(object obj: (List<Object>) System.JSON.deserializeUntyped(input.jsonString) ){
                    ts = new TimeSlot();
                    soltObj = (map<String,Object>) obj;
                    system.debug('$#$#$# '+soltObj);
                    ts.slot = (String) soltObj.get('time');
                    ts.vehicleId = (String) soltObj.get('vehicleId');
                    ts.serviceResourceId = (String) soltObj.get('serviceResourceId');
                    tsLst.add(ts);
                }
                system.debug('%$%$%$ '+tsLst);
                output.timeSlot = tsLst;
            } catch (Exception e) {
                // Handle invalid JSON
                output.timeSlot = null;
                System.debug('Invalid JSON: ' + e.getMessage());
            }
            
            results.add(output);
        }

        return results;
    }

}