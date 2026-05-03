public class TestDriveFormatterInvocable {

    public class Request {
        @InvocableVariable(required=true)
        public String jsonInput;
    }

    public class Response {
        @InvocableVariable
        public String jsonOutput;
    }

    @InvocableMethod(label='Enrich Test Drive JSON')
    public static List<Response> process(List<Request> requests) {

        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        String jsonInput = requests[0].jsonInput;

        // STEP 1: Deserialize untyped (IMPORTANT)
        Map<String, Object> root =
            (Map<String, Object>) JSON.deserializeUntyped(jsonInput);

        List<Object> testDrives =
            (List<Object>) root.get('testDrives');

        // STEP 2: Collect IDs
        Set<Id> saIds = new Set<Id>();

        for (Object obj : testDrives) {
            Map<String, Object> td = (Map<String, Object>) obj;
            saIds.add((Id) td.get('id'));
        }

        // STEP 3: Query data
        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>(
            [SELECT Id, Subject, SchedStartTime, SchedEndTime, ShowRoom__c, ModelName__c
             FROM ServiceAppointment
             WHERE Id IN :saIds]
        );

        // STEP 4: Enrich JSON
        for (Object obj : testDrives) {
            Map<String, Object> td = (Map<String, Object>) obj;

            Id saId = (Id) td.get('id');
            ServiceAppointment sa = saMap.get(saId);

            if (sa != null) {
                Map<String, Object> data = new Map<String, Object>();

                data.put('Subject', sa.Subject);
                data.put('SchedStartTime', sa.SchedStartTime);
                data.put('SchedEndTime', sa.SchedEndTime);
                data.put('ShowRoom__c', sa.get('ShowRoom__c'));
                data.put('ModelName__c', sa.get('ModelName__c'));

                td.put('data', data);
            }
        }

        // STEP 5: Convert back to JSON
        String outputJson = JSON.serialize(root);

        // STEP 6: Return
        Response res = new Response();
        res.jsonOutput = outputJson;

        responses.add(res);

        return responses;
    }
}