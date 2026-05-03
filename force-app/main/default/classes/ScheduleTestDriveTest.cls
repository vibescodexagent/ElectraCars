@isTest
private class ScheduleTestDriveTest {
    // Mock for HttpCalloutService used by ScheduleTestDrive.getAppointmentCandidates
    private class TimeSlotMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setStatusCode(200);
            // Return a candidates array with one slot containing resources and start/end times
            String startTime = Datetime.now().addHours(2).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            String endTime = Datetime.now().addHours(2).addMinutes(30).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            String body = '{"candidates":[{"startTime":"' + startTime + '","endTime":"' + endTime + '","resources":["012000000000000AAA"]}]}';
            res.setBody(body);
            return res;
        }
    }

    @testSetup
    static void setup() {
        // Create a ServiceTerritory
        List<OperatingHours> operatingHours=TestDataFactory.createOperatingHours(1,true);
        ServiceTerritory st = new ServiceTerritory(Name='TD Territory Test',OperatingHoursId=operatingHours[0].Id, IsActive=true);
        insert st;

        // Create a ServiceResource for territory members (resource type != 'S')
        User u = [SELECT Id FROM User where IsActive=true LIMIT 1];
        ServiceResource sr = new ServiceResource(Name='Res1', ResourceType='T', RelatedRecordId = u.Id, IsActive = true);
        insert sr;

        // Create ServiceTerritoryMember linking resource to territory
        ServiceTerritoryMember stm = new ServiceTerritoryMember(ServiceTerritoryId = st.Id, ServiceResourceId = sr.Id,EffectiveStartDate=Datetime.now());
        insert stm;

        // Create ServiceResourceSkill if Skill exists; Skill is often a read-only/metadata object
        List<Skill> skills = [SELECT Id FROM Skill WHERE MasterLabel = 'Test Drive Assistance Skills' LIMIT 1];
        if (!skills.isEmpty()) {
            ServiceResourceSkill srs = new ServiceResourceSkill(ServiceResourceId = sr.Id, SkillId = skills[0].Id, SkillLevel = 5,EffectiveStartDate=Datetime.now());
            insert srs;
        }

        // Create WorkTypeGroup referenced by the code if not exists
        List<WorkTypeGroup> existing = [SELECT Id FROM WorkTypeGroup WHERE Name='Test Drive' LIMIT 1];
        if (existing.isEmpty()) {
            WorkTypeGroup wtg = new WorkTypeGroup(Name='Test Drive');
            insert wtg;
        }
    }

    @isTest
    static void testTimedetailsReturnsSlots() {
        // Register mock
        Test.setMock(HttpCalloutMock.class, new TimeSlotMock());

        // Prepare request
        ScheduleTestDrive.TestDriveRequest req = new ScheduleTestDrive.TestDriveRequest();
        req.preferedStartTime = Datetime.now().addHours(1);
        req.vehicleName = 'Model';
        // pick existing territory id
        Id terrId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        req.serviceTerritoryId = terrId;

        Test.startTest();
        List<String> resp = ScheduleTestDrive.Timedetails(new List<ScheduleTestDrive.TestDriveRequest>{ req });
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response list should not be null');
        System.assertEquals(1, resp.size(), 'Should return one serialized JSON string');

        // parse JSON and assert structure using Apex-safe casts
        Object parsed = JSON.deserializeUntyped(resp[0]);
        // parsed is expected to be a List<Object>
        if (!(parsed instanceof List<Object>)) {
            // If it's not a list, fail the test with debug info
            System.assert(false, 'Expected parsed JSON to be a List but was: ' + String.valueOf(parsed));
        }
        List<Object> parsedList = (List<Object>) parsed;
        System.assert(parsedList.size() > 0, 'finalList should contain at least one candidate');

        Object first = parsedList.get(0);
        if (!(first instanceof Map<String, Object>)) {
            System.assert(false, 'Expected first element to be a Map but was: ' + String.valueOf(first));
        }
        Map<String, Object> slot = (Map<String, Object>) first;

        // Validate keys that ScheduleTestDrive adds
        System.assert(slot.containsKey('resource'), 'slot must include resource');
        System.assert(slot.containsKey('skillLevel'), 'slot must include skillLevel');
        System.assert(slot.containsKey('skillType'), 'slot must include skillType');
    }

    @isTest
    static void testTimedetailsNoCandidates() {
        // Mock that returns empty object
        Test.setMock(HttpCalloutMock.class, new NoCandidatesMock());

        ScheduleTestDrive.TestDriveRequest req = new ScheduleTestDrive.TestDriveRequest();
        req.preferedStartTime = Datetime.now().addHours(1);
        req.vehicleName = '';
        Id terrId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        req.serviceTerritoryId = terrId;

        Test.startTest();
        List<String> resp = ScheduleTestDrive.Timedetails(new List<ScheduleTestDrive.TestDriveRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, resp.size(), 'Should always return a list with one element');
        System.assertEquals('No slots available', resp[0], 'Should return No slots available when no candidates present');
    }

    // Separate mock class for no-candidates response
    private class NoCandidatesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(200);
            r.setHeader('Content-Type','application/json');
            r.setBody('{}');
            return r;
        }
    }
}