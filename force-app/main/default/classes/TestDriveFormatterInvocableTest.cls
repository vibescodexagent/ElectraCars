/**
 * @description Test class for TestDriveFormatterInvocable
 * Tests the invocable method that enriches test drive JSON with ServiceAppointment data
 */
@isTest
private class TestDriveFormatterInvocableTest {
    
    /**
     * @description Setup test data using TestDataFactory
     */
    @testSetup
    static void setup() {
        // Create Accounts
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        
        // Create Contacts
        List<Contact> contacts = TestDataFactory.createContacts(1, false);
        contacts[0].AccountId = accounts[0].Id;
        insert contacts;
        
        // Create Operating Hours
        List<OperatingHours> opHours = TestDataFactory.createOperatingHours(1, true);
        
        // Create Service Territories
        List<ServiceTerritory> territories = TestDataFactory.createServiceTerritories(1, opHours[0].Id, true);
        
        // Create WorkType
        WorkType workType = new WorkType(
            Name = 'Test Drive',
            EstimatedDuration = 1.0,
            DurationType = 'Hours'
        );
        insert workType;
        
        // Create WorkOrders
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 3; i++) {
            WorkOrder wo = new WorkOrder(
                ContactId = contacts[0].Id,
                Subject = 'Test Drive Work Order ' + i,
                Status = 'New',
                WorkTypeId = workType.Id
            );
            workOrders.add(wo);
        }
        insert workOrders;
        
        // Create ServiceAppointments
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer i = 0; i < 3; i++) {
            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = workOrders[i].Id,
                ContactId = contacts[0].Id,
                Subject = 'Test Drive ' + i,
                Status = 'Scheduled',
                SchedStartTime = DateTime.now().addDays(i),
                SchedEndTime = DateTime.now().addDays(i).addHours(1),
                WorkTypeId = workType.Id
            );
            appointments.add(sa);
        }
        insert appointments;
    }
    
    /**
     * @description Test successful processing with single test drive
     */
    @isTest
    static void testProcessSingleTestDrive() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        String inputJson = '{"testDrives":[{"id":"' + sa.Id + '"}]}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isNotNull(responses[0].jsonOutput, 'Output JSON should not be null');
        
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responses[0].jsonOutput);
        List<Object> testDrives = (List<Object>)output.get('testDrives');
        
        Assert.areEqual(1, testDrives.size(), 'Should have one test drive');
        
        Map<String, Object> testDrive = (Map<String, Object>)testDrives[0];
        Assert.isTrue(testDrive.containsKey('data'), 'Should contain enriched data');
        
        Map<String, Object> data = (Map<String, Object>)testDrive.get('data');
        Assert.isNotNull(data.get('Subject'), 'Subject should be populated');
        Assert.isNotNull(data.get('SchedStartTime'), 'SchedStartTime should be populated');
        Assert.isNotNull(data.get('SchedEndTime'), 'SchedEndTime should be populated');
    }
    
    /**
     * @description Test processing with multiple test drives
     */
    @isTest
    static void testProcessMultipleTestDrives() {
        List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment ORDER BY Subject];
        
        String inputJson = '{"testDrives":[' +
            '{"id":"' + appointments[0].Id + '"},' +
            '{"id":"' + appointments[1].Id + '"},' +
            '{"id":"' + appointments[2].Id + '"}' +
            ']}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response');
        
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responses[0].jsonOutput);
        List<Object> testDrives = (List<Object>)output.get('testDrives');
        
        Assert.areEqual(3, testDrives.size(), 'Should have three test drives');
        
        for (Object obj : testDrives) {
            Map<String, Object> testDrive = (Map<String, Object>)obj;
            Assert.isTrue(testDrive.containsKey('data'), 'Each test drive should contain enriched data');
        }
    }
    
    /**
     * @description Test with null request list
     */
    @isTest
    static void testNullRequestList() {
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(null);
        Test.stopTest();
        
        Assert.isNotNull(responses, 'Response list should not be null');
        Assert.areEqual(0, responses.size(), 'Should return empty list for null input');
    }
    
    /**
     * @description Test with empty request list
     */
    @isTest
    static void testEmptyRequestList() {
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>());
        Test.stopTest();
        
        Assert.isNotNull(responses, 'Response list should not be null');
        Assert.areEqual(0, responses.size(), 'Should return empty list for empty input');
    }
    
    /**
     * @description Test with empty test drives array
     */
    @isTest
    static void testEmptyTestDrivesArray() {
        String inputJson = '{"testDrives":[]}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isNotNull(responses[0].jsonOutput, 'Output JSON should not be null');
        
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responses[0].jsonOutput);
        List<Object> testDrives = (List<Object>)output.get('testDrives');
        
        Assert.areEqual(0, testDrives.size(), 'Should have zero test drives');
    }
    
    /**
     * @description Test with non-existent ServiceAppointment ID
     */
    @isTest
    static void testNonExistentServiceAppointmentId() {
        // Use a fake ID that doesn't exist
        String fakeId = '001000000000000AAA';
        String inputJson = '{"testDrives":[{"id":"' + fakeId + '"}]}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response');
        
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responses[0].jsonOutput);
        List<Object> testDrives = (List<Object>)output.get('testDrives');
        
        Assert.areEqual(1, testDrives.size(), 'Should have one test drive');
        
        Map<String, Object> testDrive = (Map<String, Object>)testDrives[0];
        Assert.isFalse(testDrive.containsKey('data'), 'Should not contain data for non-existent appointment');
    }
    
    /**
     * @description Test that all fields are enriched correctly
     */
    @isTest
    static void testAllFieldsEnriched() {
        ServiceAppointment sa = [
            SELECT Id, Subject, SchedStartTime, SchedEndTime 
            FROM ServiceAppointment 
            LIMIT 1
        ];
        
        String inputJson = '{"testDrives":[{"id":"' + sa.Id + '"}]}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responses[0].jsonOutput);
        List<Object> testDrives = (List<Object>)output.get('testDrives');
        Map<String, Object> testDrive = (Map<String, Object>)testDrives[0];
        Map<String, Object> data = (Map<String, Object>)testDrive.get('data');
        
        Assert.areEqual(sa.Subject, data.get('Subject'), 'Subject should match');
        Assert.isNotNull(data.get('SchedStartTime'), 'SchedStartTime should be populated');
        Assert.isNotNull(data.get('SchedEndTime'), 'SchedEndTime should be populated');
        // Custom fields ShowRoom__c and ModelName__c will be null if they don't exist
        Assert.isTrue(data.containsKey('ShowRoom__c'), 'ShowRoom__c key should exist in data');
        Assert.isTrue(data.containsKey('ModelName__c'), 'ModelName__c key should exist in data');
    }
    
    /**
     * @description Test with additional properties in input JSON
     */
    @isTest
    static void testAdditionalPropertiesPreserved() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        String inputJson = '{"testDrives":[{"id":"' + sa.Id + '","customProp":"customValue"}],"otherProp":"otherValue"}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responses[0].jsonOutput);
        
        Assert.isTrue(output.containsKey('otherProp'), 'Other properties should be preserved');
        Assert.areEqual('otherValue', output.get('otherProp'), 'Other property value should match');
        
        List<Object> testDrives = (List<Object>)output.get('testDrives');
        Map<String, Object> testDrive = (Map<String, Object>)testDrives[0];
        
        Assert.isTrue(testDrive.containsKey('customProp'), 'Custom properties should be preserved');
        Assert.areEqual('customValue', testDrive.get('customProp'), 'Custom property value should match');
    }
    
    /**
     * @description Test Request and Response wrapper classes
     */
    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = '{"test":"value"}';
        
        TestDriveFormatterInvocable.Response res = new TestDriveFormatterInvocable.Response();
        res.jsonOutput = '{"result":"success"}';
        
        Test.stopTest();
        
        Assert.areEqual('{"test":"value"}', req.jsonInput, 'Request jsonInput should be set');
        Assert.areEqual('{"result":"success"}', res.jsonOutput, 'Response jsonOutput should be set');
    }
    
    /**
     * @description Test with mixed valid and invalid IDs
     */
    @isTest
    static void testMixedValidAndInvalidIds() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        String fakeId = '001000000000000AAA';
        
        String inputJson = '{"testDrives":[' +
            '{"id":"' + sa.Id + '"},' +
            '{"id":"' + fakeId + '"}' +
            ']}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responses[0].jsonOutput);
        List<Object> testDrives = (List<Object>)output.get('testDrives');
        
        Assert.areEqual(2, testDrives.size(), 'Should have two test drives');
        
        Map<String, Object> validTestDrive = (Map<String, Object>)testDrives[0];
        Assert.isTrue(validTestDrive.containsKey('data'), 'Valid ID should have data');
        
        Map<String, Object> invalidTestDrive = (Map<String, Object>)testDrives[1];
        Assert.isFalse(invalidTestDrive.containsKey('data'), 'Invalid ID should not have data');
    }
    
    /**
     * @description Test JSON round-trip integrity
     */
    @isTest
    static void testJsonRoundTripIntegrity() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        String inputJson = '{"testDrives":[{"id":"' + sa.Id + '"}]}';
        
        TestDriveFormatterInvocable.Request req = new TestDriveFormatterInvocable.Request();
        req.jsonInput = inputJson;
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req});
        Test.stopTest();
        
        String outputJson = responses[0].jsonOutput;
        Assert.isNotNull(outputJson, 'Output JSON should not be null');
        
        // Verify output is valid JSON
        Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(outputJson);
        Assert.isTrue(output.containsKey('testDrives'), 'Output should contain testDrives array');
    }
    
    /**
     * @description Test bulk processing with multiple requests (only first is processed)
     */
    @isTest
    static void testMultipleRequests() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        TestDriveFormatterInvocable.Request req1 = new TestDriveFormatterInvocable.Request();
        req1.jsonInput = '{"testDrives":[{"id":"' + sa.Id + '"}]}';
        
        TestDriveFormatterInvocable.Request req2 = new TestDriveFormatterInvocable.Request();
        req2.jsonInput = '{"testDrives":[]}';
        
        Test.startTest();
        List<TestDriveFormatterInvocable.Response> responses = 
            TestDriveFormatterInvocable.process(new List<TestDriveFormatterInvocable.Request>{req1, req2});
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response (only processes first request)');
        Assert.isNotNull(responses[0].jsonOutput, 'Output JSON should not be null');
    }
}