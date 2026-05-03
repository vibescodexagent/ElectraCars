/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TestDriveScoringPromptJSONParser
 * Author          : <YourName>
 * Created Date    : Apr 27, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Apr 27, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 27, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class TestDriveScoringPromptJSONParser {
	public class ResponseWrapper {
        @InvocableVariable public Integer Score;
        @InvocableVariable public String Recommendation;
    }

    @InvocableMethod(label='Parse Prompt JSON')
    public static List<ResponseWrapper> parseResponse(List<String> responses) {
        List<ResponseWrapper> result = new List<ResponseWrapper>();

        for(String res : responses){
            ResponseWrapper obj = (ResponseWrapper) JSON.deserialize(res, ResponseWrapper.class);
            result.add(obj);
        }
        return result;
    }

}