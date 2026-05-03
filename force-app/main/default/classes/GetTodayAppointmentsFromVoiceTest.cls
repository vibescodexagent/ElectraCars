/**
 * @description Test class for GetTodayAppointmentsFromVoice
 * Tests the invocable method that retrieves today's service appointments from voice calls
 * Note: Test setup avoids Flow triggers by creating data within Test.startTest/stopTest blocks
 */
@isTest
private class GetTodayAppointmentsFromVoiceTest {
    
    /**
     * @description Setup basic test data (no ServiceAppointments to avoid Flow trigger)
     */
    @testSetup
    static void setup() {
        // Create Accounts
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        
        // Create Contacts with email
        List<Contact> contacts = TestDataFactory.createContacts(1, false);
        contacts[0].AccountId = accounts[0].Id;
        contacts[0].Phone = '+1234567890';
        contacts[0].Email = 'test@example.com';
        insert contacts;
        
        // Create Vehicle Assets
        List<Asset> assets = TestDataFactory.createVehicleAssets(1, 'Tesla Model 3', accounts[0].Id, contacts[0].Id, true);
        
        // Create Users for ServiceResource
        List<User> users = TestDataFactory.createUsers(2, null, false);
        users[0].Phone = '+1234567890';
        users[0].Email = 'user1@test.com';
        users[1].Phone = '+0987654321';
        users[1].Email = 'user2@test.com';
        insert users;
        
        // Create Operating Hours
        OperatingHours oh = new OperatingHours(
            Name = 'Test Operating Hours',
            TimeZone = 'America/New_York'
        );
        insert oh;
        
        // Create Service Territory
        ServiceTerritory territory = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = oh.Id,
            IsActive = true
        );
        insert territory;
        
        // Create Service Resources
        List<ServiceResource> resources = new List<ServiceResource>();
        for (Integer i = 0; i < 2; i++) {
            resources.add(new ServiceResource(
                Name = 'Test Resource ' + i,
                ResourceType = 'T',
                RelatedRecordId = users[i].Id,
                IsActive = true
            ));
        }
        insert resources;
        
        // Create Work Type
        WorkType wt = new WorkType(
            Name = 'Test Drive',
            EstimatedDuration = 60,
            DurationType = 'Minutes'
        );
        insert wt;
        
        // Create Work Orders
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 3; i++) {
            workOrders.add(new WorkOrder(
                Subject = 'Test Work Order ' + i,
                WorkTypeId = wt.Id,
                ContactId = contacts[0].Id,
                AccountId = accounts[0].Id
            ));
        }
        insert workOrders;
    }
    
    /**
     * @description Helper to create Service Appointments and Assigned Resources
     */
    private static void createServiceAppointments() {
        WorkOrder[] workOrders = [SELECT Id FROM WorkOrder ORDER BY Subject];
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource WHERE Name = 'Test Resource 0' LIMIT 1];
        
        List<ServiceAppointment> serviceAppts = new List<ServiceAppointment>();
        
        // Appointment 1: Today, scheduled (use Lead as ParentRecord to exercise Lead path)
        Lead leadRec = new Lead(FirstName='TD', LastName='Lead1', Company='TestCo', Phone='+1234567890', Email='lead1@example.com');
        insert leadRec;
        serviceAppts.add(new ServiceAppointment(
            Subject = 'TD-12345',
            ParentRecordId = leadRec.Id,
            SchedStartTime = DateTime.now().addHours(2),
            SchedEndTime = DateTime.now().addHours(3),
            ServiceTerritoryId = territory.Id,
            Status = 'Scheduled',
            ModelName__c = 'Tesla Model 3'
        ));
        
        // Appointment 2: Today, scheduled, later time (Lead parent)
        Lead leadRec2 = new Lead(FirstName='TD', LastName='Lead2', Company='TestCo2', Phone='+1234567890', Email='lead2@example.com');
        insert leadRec2;
        serviceAppts.add(new ServiceAppointment(
            Subject = 'TD-67890',
            ParentRecordId = leadRec2.Id,
            SchedStartTime = DateTime.now().addHours(5),
            SchedEndTime = DateTime.now().addHours(6),
            ServiceTerritoryId = territory.Id,
            Status = 'Scheduled',
            ModelName__c = 'Tesla Model S'
        ));
        
        // Appointment 3: Today, completed (should be excluded) (Lead parent)
        Lead leadRec3 = new Lead(FirstName='TD', LastName='Lead3', Company='TestCo3', Phone='+1234567890', Email='lead3@example.com');
        insert leadRec3;
        serviceAppts.add(new ServiceAppointment(
            Subject = 'TD-11111',
            ParentRecordId = leadRec3.Id,
            SchedStartTime = DateTime.now().addHours(1),
            SchedEndTime = DateTime.now().addHours(2),
            ServiceTerritoryId = territory.Id,
            Status = 'Completed',
            ModelName__c = 'Tesla Model X'
        ));
        
        insert serviceAppts;
        
        // Create Assigned Resources
        List<AssignedResource> assignedResources = new List<AssignedResource>();
        for (ServiceAppointment sa : serviceAppts) {
            assignedResources.add(new AssignedResource(
                ServiceAppointmentId = sa.Id,
                ServiceResourceId = resource.Id
            ));
        }
        insert assignedResources;
    }
    
    /**
     * @description Test successful retrieval of today's appointments
     */
    @isTest
    static void testGetAppointmentsSuccess() {
        Test.startTest();
        createServiceAppointments();
        DateTime currentdt=DateTime.now();
        VoiceCall vc = new VoiceCall(
            FromPhoneNumber = '+1234567890',
            ToPhoneNumber = '+1111111111',
            VendorType='NativeVoice',
            CallType='Inbound',
            CallStartDateTime = currentdt,
            CallEndDateTime=currentdt.addMinutes(15)
        );
        insert vc;
        
        GetTodayAppointmentsFromVoice.InputWrapper input = new GetTodayAppointmentsFromVoice.InputWrapper();
        input.recordId = vc.Id;
        input.testDriveNumber = null;
        
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(new List<GetTodayAppointmentsFromVoice.InputWrapper>{input});
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isNotNull(results[0].jsonResult, 'JSON result should not be null');
        
        List<Object> appointments = (List<Object>) JSON.deserializeUntyped(results[0].jsonResult);
        Assert.areEqual(2, appointments.size(), 'Should return 2 scheduled appointments');
    }
    
    /**
     * @description Test with specific testDriveNumber filter
     */
    @isTest
    static void testGetAppointmentsWithTestDriveNumber() {
        Test.startTest();
        createServiceAppointments();
        DateTime currentdt=DateTime.now();
        VoiceCall vc = new VoiceCall(
            FromPhoneNumber = '+1234567890',
            ToPhoneNumber = '+1111111111',
            VendorType='NativeVoice',
            CallType='Inbound',
            CallStartDateTime = currentdt,
            CallEndDateTime=currentdt.addMinutes(15)
        );
        insert vc;
        
        GetTodayAppointmentsFromVoice.InputWrapper input = new GetTodayAppointmentsFromVoice.InputWrapper();
        input.recordId = vc.Id;
        input.testDriveNumber = 'TD-12345';
        
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(new List<GetTodayAppointmentsFromVoice.InputWrapper>{input});
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        List<Object> appointments = (List<Object>) JSON.deserializeUntyped(results[0].jsonResult);
        Assert.areEqual(1, appointments.size(), 'Should return only the filtered appointment');
        
        Map<String, Object> appointment = (Map<String, Object>) appointments[0];
        Assert.areEqual('TD-12345', appointment.get('testDriveNumber'), 'Should match test drive number');
    }
    
    /**
     * @description Test with null input
     */
    @isTest
    static void testGetAppointmentsNullInput() {
        Test.startTest();
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(null);
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty list for null input');
    }
    
    /**
     * @description Test with empty input list
     */
    @isTest
    static void testGetAppointmentsEmptyInput() {
        Test.startTest();
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(new List<GetTodayAppointmentsFromVoice.InputWrapper>());
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty list for empty input');
    }
    
    /**
     * @description Test with blank recordId
     */
    @isTest
    static void testGetAppointmentsBlankRecordId() {
        GetTodayAppointmentsFromVoice.InputWrapper input = new GetTodayAppointmentsFromVoice.InputWrapper();
        input.recordId = '';
        input.testDriveNumber = null;
        
        Test.startTest();
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(new List<GetTodayAppointmentsFromVoice.InputWrapper>{input});
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('[]', results[0].jsonResult, 'Should return empty array for blank recordId');
    }
    
    /**
     * @description Test with invalid recordId
     */
    @isTest
    static void testGetAppointmentsInvalidRecordId() {
        GetTodayAppointmentsFromVoice.InputWrapper input = new GetTodayAppointmentsFromVoice.InputWrapper();
        input.recordId = '001000000000000';
        input.testDriveNumber = null;
        
        Test.startTest();
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(new List<GetTodayAppointmentsFromVoice.InputWrapper>{input});
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('[]', results[0].jsonResult, 'Should return empty array for invalid recordId');
    }
    
    /**
     * @description Test with phone number not matching any ServiceResource
     */
    @isTest
    static void testGetAppointmentsPhoneNotMatched() {
        Test.startTest();
        createServiceAppointments();
        DateTime currentdt=DateTime.now();
        VoiceCall vc = new VoiceCall(
            FromPhoneNumber = '+5555555555',
            ToPhoneNumber = '+1111111111',
            VendorType='NativeVoice',
            CallType='Inbound',
            CallStartDateTime = currentdt,
            CallEndDateTime=currentdt.addMinutes(15)
        );
        insert vc;
        
        GetTodayAppointmentsFromVoice.InputWrapper input = new GetTodayAppointmentsFromVoice.InputWrapper();
        input.recordId = vc.Id;
        input.testDriveNumber = null;
        
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(new List<GetTodayAppointmentsFromVoice.InputWrapper>{input});
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual('[]', results[0].jsonResult, 'Should return empty array when phone not matched');
    }
    
    /**
     * @description Test wrapper classes instantiation
     */
    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        
        GetTodayAppointmentsFromVoice.InputWrapper input = new GetTodayAppointmentsFromVoice.InputWrapper();
        input.recordId = 'test123';
        input.testDriveNumber = 'TD-TEST';
        
        GetTodayAppointmentsFromVoice.OutputWrapper output = new GetTodayAppointmentsFromVoice.OutputWrapper();
        output.jsonResult = '{"test": "data"}';
        
        Test.stopTest();
        
        Assert.areEqual('test123', input.recordId, 'Input recordId should be set');
        Assert.areEqual('TD-TEST', input.testDriveNumber, 'Input testDriveNumber should be set');
        Assert.areEqual('{"test": "data"}', output.jsonResult, 'Output jsonResult should be set');
    }
    
    /**
     * @description Test JSON structure validation
     */
    @isTest
    static void testJsonStructureValidation() {
        Test.startTest();
        createServiceAppointments();
        DateTime currentdt=DateTime.now();
        VoiceCall vc = new VoiceCall(
            FromPhoneNumber = '+1234567890',
            ToPhoneNumber = '+1111111111',
            VendorType='NativeVoice',
            CallType='Inbound',
            CallStartDateTime = currentdt,
            CallEndDateTime=currentdt.addMinutes(15)
        );
        insert vc;
        
        GetTodayAppointmentsFromVoice.InputWrapper input = new GetTodayAppointmentsFromVoice.InputWrapper();
        input.recordId = vc.Id;
        input.testDriveNumber = 'TD-12345';
        
        List<GetTodayAppointmentsFromVoice.OutputWrapper> results = 
            GetTodayAppointmentsFromVoice.getAppointments(new List<GetTodayAppointmentsFromVoice.InputWrapper>{input});
        Test.stopTest();
        
        List<Object> appointments = (List<Object>) JSON.deserializeUntyped(results[0].jsonResult);
        Assert.areEqual(1, appointments.size(), 'Should have one appointment');
        
        Map<String, Object> appointment = (Map<String, Object>) appointments[0];
        Assert.isTrue(appointment.containsKey('ServiceResourceId'), 'Should contain ServiceResourceId');
        Assert.isTrue(appointment.containsKey('territory'), 'Should contain territory');
        Assert.isTrue(appointment.containsKey('sales_rep_name'), 'Should contain sales_rep_name');
        Assert.isTrue(appointment.containsKey('model_name'), 'Should contain model_name');
        Assert.isTrue(appointment.containsKey('testDriveNumber'), 'Should contain testDriveNumber');
        Assert.isTrue(appointment.containsKey('start_time'), 'Should contain start_time');
    }
}