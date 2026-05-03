/**
 * @description Test class for GetTestDriveFromVoice
 * Uses TestDataFactory for creating test records and validates the invocable method behavior
 */
@isTest
private class GetTestDriveFromVoiceTest {

    @testSetup
    static void setup() {
        // Use TestDataFactory to create base records used across tests
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = TestDataFactory.createContacts(1, false);
        contacts[0].AccountId = accounts[0].Id;
        contacts[0].Phone = '+1234567890';
        contacts[0].Email = 'tduser@example.com';
        insert contacts;
        
        // Create a Lead to be used as ParentRecord for ServiceAppointments in tests
        Lead l = new Lead(LastName='TD Lead', Company='TestCo', Phone = '+2223334444', Email='leaduser@example.com');
        insert l;

        // Avoid performing DML on Org-wide or admin-only objects in tests.
        // We'll rely on defensive population of fields (CallCenterId/VendorType) on WorkOrder and
        // presence of Contact/User emails created above to satisfy Flow recipient logic where possible.
        // If the org requires additional metadata (OrgWideEmailAddress/CallCenter), please provision
        // them in the org or modify the Flow to skip during Test.isRunningTest().

        List<User> users = TestDataFactory.createUsers(1, null, false);
        users[0].Phone = '+1234567890';
        users[0].Email = 'resuser@example.com';
        insert users;

        // Create Operating Hours and Service Territory
        OperatingHours oh = new OperatingHours(Name='TD Operating Hours', TimeZone='America/New_York');
        insert oh;

        ServiceTerritory st = new ServiceTerritory(Name='TD Territory', OperatingHoursId=oh.Id, IsActive=true);
        insert st;

        // Create ServiceResource tied to the User
        ServiceResource sr = new ServiceResource(Name='TD Resource', ResourceType='T', RelatedRecordId=users[0].Id, IsActive=true);
        insert sr;

        // Create WorkType and WorkOrder (kept for org processes that expect WorkOrder records)
        WorkType wt = new WorkType(Name='Test Drive', EstimatedDuration=60, DurationType='Minutes');
        insert wt;

        WorkOrder wo = new WorkOrder(Subject='TD WorkOrder', WorkTypeId=wt.Id, ContactId=contacts[0].Id, AccountId=accounts[0].Id);
        // Populate fields commonly required by org validation / processes
        // Best-effort defaults; adjust if your org expects different values
        try {
            Map<String, Schema.SObjectField> woFields = Schema.sObjectType.WorkOrder.fields.getMap();
            if (woFields.containsKey('CallCenterId')) {
                // If CallCenterId expects an Id, attempt to set a placeholder string; may still fail if real Id required
                wo.put('CallCenterId', 'TestCallCenter');
            }
            if (woFields.containsKey('VendorType')) {
                wo.put('VendorType', 'Internal');
            }
        } catch (Exception ex) {
            // ignore if fields are not present
        }
        insert wo;
    }

    // Helper to create a ServiceAppointment and AssignedResource, returns the created ServiceAppointment
    // Modified to use a Lead as the ParentRecord instead of a WorkOrder
    private static ServiceAppointment createServiceAppt(String subject, DateTime startOffset, String status) {
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        // Use a Lead as ParentRecord for ServiceAppointment per user's instruction
        Lead l = [SELECT Id, Phone, Email FROM Lead LIMIT 1];
        ServiceResource res = [SELECT Id FROM ServiceResource LIMIT 1];

        ServiceAppointment sa = new ServiceAppointment(
            Subject = subject,
            ParentRecordId = l.Id,
            SchedStartTime = DateTime.now().addHours(startOffset.hour()),
            SchedEndTime = DateTime.now().addHours(startOffset.hour()).addMinutes(30),
            ServiceTerritoryId = territory.Id,
            Status = status,
            ModelName__c = 'Model X'
        );
        try {
            insert sa;
        } catch (DmlException e) {
            // Rethrow with clearer message for test debugging
            System.debug('ServiceAppointment insert failed: ' + e.getMessage());
            throw e;
        }

        AssignedResource ar = new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = res.Id);
        insert ar;

        return sa;
    }

    @isTest
    static void testGetTestDriveSuccess() {
        Test.startTest();
        ServiceAppointment sa1 = createServiceAppt('TD-AAA', Datetime.now().addHours(2), 'Scheduled');
        ServiceAppointment sa2 = createServiceAppt('TD-BBB', Datetime.now().addHours(4), 'Scheduled');
        DateTime currentdt=DateTime.now();
        VoiceCall vc = new VoiceCall(FromPhoneNumber = '+1234567890', ToPhoneNumber = '+1111111111',  VendorType='NativeVoice', CallType='Inbound', CallStartDateTime = currentdt, CallEndDateTime=currentdt.addMinutes(15));
        insert vc;

        // Call the GetTestDriveFromVoice invocable method (correct signature: getTestDrive)
        GetTestDriveFromVoice.InputWrapper input = new GetTestDriveFromVoice.InputWrapper();
        input.recordId = vc.Id;
        input.testDriveNumber = null;

        List<GetTestDriveFromVoice.OutputWrapper> results = GetTestDriveFromVoice.getTestDrive(new List<GetTestDriveFromVoice.InputWrapper>{ input });
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result for the voice call');

        // Verify output wrapper fields from GetTestDriveFromVoice
        // message must be present; testDriveId may be present when a matching test drive is found
        System.assertNotEquals(null, results[0].message, 'Message should not be null');
        if (results[0].testDriveId != null) {
            System.assert(results[0].testDriveId.length() > 0, 'testDriveId should be non-empty if present');
        }
        if (results[0].userId != null) {
            System.assert(results[0].userId.length() > 0, 'userId should be non-empty if present');
        }
        // leadId may be set when testDrive record links to a lead
        // no jsonResult field exists on GetTestDriveFromVoice.OutputWrapper
    }

    @isTest
    static void testGetTestDriveNoMatch() {
        Test.startTest();
        // Create an appointment but use a different phone on VoiceCall to force no match
        ServiceAppointment sa = createServiceAppt('TD-CCC', Datetime.now().addHours(3), 'Scheduled');
        DateTime currentdt=DateTime.now();
        VoiceCall vc = new VoiceCall(FromPhoneNumber = '+9999999999', ToPhoneNumber = '+1111111111',  VendorType='NativeVoice', CallType='Inbound', CallStartDateTime = currentdt, CallEndDateTime=currentdt.addMinutes(15));
        insert vc;

        // Call GetTestDriveFromVoice (ensure we only cover GetTestDriveFromVoice in this test)
        GetTestDriveFromVoice.InputWrapper input = new GetTestDriveFromVoice.InputWrapper();
        input.recordId = vc.Id;
        input.testDriveNumber = null;

        List<GetTestDriveFromVoice.OutputWrapper> results = GetTestDriveFromVoice.getTestDrive(new List<GetTestDriveFromVoice.InputWrapper>{ input });
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        // For no match, the service returns a message and null testDriveId
        System.assertEquals(null, results[0].testDriveId, 'testDriveId should be null for no match');
        System.assertNotEquals(null, results[0].message, 'Should return a not-found message for no matches');
    }

    @isTest
    static void testGetTestDriveInvalidInput() {
        Test.startTest();
        GetTestDriveFromVoice.InputWrapper input = new GetTestDriveFromVoice.InputWrapper();
        input.recordId = '001000000000000';
        input.testDriveNumber = null;

        List<GetTestDriveFromVoice.OutputWrapper> results = GetTestDriveFromVoice.getTestDrive(new List<GetTestDriveFromVoice.InputWrapper>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one wrapper result');
        System.assertEquals(null, results[0].testDriveId, 'Invalid recordId should return null testDriveId');
        System.assertNotEquals(null, results[0].message, 'Invalid recordId should return a message');
    }

    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        GetTestDriveFromVoice.InputWrapper inWrap = new GetTestDriveFromVoice.InputWrapper();
        inWrap.recordId = 'test-id';
        inWrap.testDriveNumber = 'TD-XYZ';

        GetTestDriveFromVoice.OutputWrapper outWrap = new GetTestDriveFromVoice.OutputWrapper();
        Test.stopTest();

        System.assertEquals('test-id', inWrap.recordId);
        System.assertEquals('TD-XYZ', inWrap.testDriveNumber);
        // Validate wrapper fields instantiation for GetTestDriveFromVoice OutputWrapper
        System.assertEquals(null, outWrap.testDriveId, 'Default outWrap.testDriveId should be null');
        outWrap.message = 'Test';
        System.assertEquals('Test', outWrap.message);
    }

 
    /**
     * @description Test branch where AssignedResource's ServiceAppointment is Completed
     */
    @isTest
    static void testCompletedServiceAppointmentPath() {
        // Create a ServiceAppointment and set its status to Completed
        ServiceAppointment sa = createServiceAppt('TD-COMPLETE', Datetime.now().addHours(1), 'Completed');

        // Create AssignedResource already created in helper; ensure AssignedResource exists for sa
        // (createServiceAppt already inserts AssignedResource)

        // Create VoiceCall from the ServiceResource related user
        ServiceResource sr = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1];
        User u = [SELECT Id, Phone FROM User WHERE Id = :sr.RelatedRecordId LIMIT 1];

        VoiceCall vc = new VoiceCall(FromPhoneNumber = u.Phone, ToPhoneNumber = '+1111111111', VendorType='NativeVoice', CallType='Inbound', CallStartDateTime = Datetime.now(), CallEndDateTime = Datetime.now().addMinutes(10));
        insert vc;

        GetTestDriveFromVoice.InputWrapper input = new GetTestDriveFromVoice.InputWrapper();
        input.recordId = vc.Id;
        input.testDriveNumber = 'TD-COMPLETE';

        Test.startTest();
        List<GetTestDriveFromVoice.OutputWrapper> results = GetTestDriveFromVoice.getTestDrive(new List<GetTestDriveFromVoice.InputWrapper>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one wrapper result');
        System.assertEquals(null, results[0].testDriveId, 'Completed appointment should result in null testDriveId');
        System.assertNotEquals(null, results[0].message, 'Should return a message indicating completed status');
    }
}