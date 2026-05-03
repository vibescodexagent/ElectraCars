/**
 * @description Test class for TestDriveInfo wrapper class
 * Tests all properties and common usage scenarios
 */
@isTest
private class TestDriveInfoTest {
    
    /**
     * @description Setup test data using TestDataFactory
     */
    @testSetup
    static void setup() {
        // Create Accounts for test data
        List<Account> accounts = TestDataFactory.createAccounts(2, true);
        
        // Create Contacts associated with Accounts
        List<Contact> contacts = TestDataFactory.createContacts(2, false);
        for (Integer i = 0; i < contacts.size(); i++) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;
        
        // Create Vehicle Assets
        List<Asset> assets = TestDataFactory.createVehicleAssets(
            2, 
            'Test Vehicle', 
            accounts[0].Id, 
            contacts[0].Id, 
            true
        );
        
        // Create Operating Hours for Service Territories
        List<OperatingHours> opHours = TestDataFactory.createOperatingHours(1, true);
        
        // Create Service Territories
        List<ServiceTerritory> territories = TestDataFactory.createServiceTerritories(
            2, 
            opHours[0].Id, 
            true
        );
    }
    
    /**
     * @description Test basic instantiation of TestDriveInfo
     */
    @isTest
    static void testInstantiation() {
        Test.startTest();
        TestDriveInfo info = new TestDriveInfo();
        Test.stopTest();
        
        Assert.isNotNull(info, 'TestDriveInfo should be instantiated');
        Assert.isNull(info.testDriveId, 'testDriveId should be null initially');
        Assert.isNull(info.subject, 'subject should be null initially');
        Assert.isNull(info.startTime, 'startTime should be null initially');
        Assert.isNull(info.endTime, 'endTime should be null initially');
        Assert.isNull(info.showRoom, 'showRoom should be null initially');
        Assert.isNull(info.vehicleName, 'vehicleName should be null initially');
        Assert.isNull(info.serviceTerritoryId, 'serviceTerritoryId should be null initially');
    }
    
    /**
     * @description Test setting all properties
     */
    @isTest
    static void testSetAllProperties() {
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        DateTime now = DateTime.now();
        
        Test.startTest();
        TestDriveInfo info = new TestDriveInfo();
        info.testDriveId = 'TD001';
        info.subject = 'Test Drive Appointment';
        info.startTime = now;
        info.endTime = now.addHours(1);
        info.showRoom = 'Downtown Showroom';
        info.vehicleName = 'Tesla Model S';
        info.serviceTerritoryId = territory.Id;
        Test.stopTest();
        
        Assert.areEqual('TD001', info.testDriveId, 'testDriveId should be set');
        Assert.areEqual('Test Drive Appointment', info.subject, 'subject should be set');
        Assert.areEqual(now, info.startTime, 'startTime should be set');
        Assert.areEqual(now.addHours(1), info.endTime, 'endTime should be set');
        Assert.areEqual('Downtown Showroom', info.showRoom, 'showRoom should be set');
        Assert.areEqual('Tesla Model S', info.vehicleName, 'vehicleName should be set');
        Assert.areEqual(territory.Id, info.serviceTerritoryId, 'serviceTerritoryId should be set');
    }
    
    /**
     * @description Test JSON serialization
     */
    @isTest
    static void testJsonSerialization() {
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        DateTime now = DateTime.now();
        
        TestDriveInfo info = new TestDriveInfo();
        info.testDriveId = 'TD002';
        info.subject = 'Test Drive';
        info.startTime = now;
        info.endTime = now.addHours(2);
        info.showRoom = 'Main Showroom';
        info.vehicleName = 'BMW i4';
        info.serviceTerritoryId = territory.Id;
        
        Test.startTest();
        String jsonString = JSON.serialize(info);
        Test.stopTest();
        
        Assert.isNotNull(jsonString, 'JSON string should not be null');
        Assert.isTrue(jsonString.contains('TD002'), 'JSON should contain testDriveId');
        Assert.isTrue(jsonString.contains('Test Drive'), 'JSON should contain subject');
        Assert.isTrue(jsonString.contains('Main Showroom'), 'JSON should contain showRoom');
        Assert.isTrue(jsonString.contains('BMW i4'), 'JSON should contain vehicleName');
    }
    
    /**
     * @description Test JSON deserialization
     */
    @isTest
    static void testJsonDeserialization() {
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        String jsonString = '{"testDriveId":"TD003","subject":"Test Drive Booking",' +
            '"startTime":"2024-06-15T10:00:00.000Z","endTime":"2024-06-15T11:00:00.000Z",' +
            '"showRoom":"North Showroom","vehicleName":"Audi e-tron",' +
            '"serviceTerritoryId":"' + territory.Id + '"}';
        
        Test.startTest();
        TestDriveInfo info = (TestDriveInfo)JSON.deserialize(jsonString, TestDriveInfo.class);
        Test.stopTest();
        
        Assert.isNotNull(info, 'Deserialized object should not be null');
        Assert.areEqual('TD003', info.testDriveId, 'testDriveId should match');
        Assert.areEqual('Test Drive Booking', info.subject, 'subject should match');
        Assert.areEqual('North Showroom', info.showRoom, 'showRoom should match');
        Assert.areEqual('Audi e-tron', info.vehicleName, 'vehicleName should match');
        Assert.areEqual(territory.Id, info.serviceTerritoryId, 'serviceTerritoryId should match');
    }
    
    /**
     * @description Test with null values
     */
    @isTest
    static void testNullValues() {
        Test.startTest();
        TestDriveInfo info = new TestDriveInfo();
        String jsonString = JSON.serialize(info);
        TestDriveInfo deserializedInfo = (TestDriveInfo)JSON.deserialize(jsonString, TestDriveInfo.class);
        Test.stopTest();
        
        Assert.isNotNull(deserializedInfo, 'Deserialized object should not be null');
        Assert.isNull(deserializedInfo.testDriveId, 'testDriveId should be null');
        Assert.isNull(deserializedInfo.subject, 'subject should be null');
        Assert.isNull(deserializedInfo.startTime, 'startTime should be null');
        Assert.isNull(deserializedInfo.endTime, 'endTime should be null');
        Assert.isNull(deserializedInfo.showRoom, 'showRoom should be null');
        Assert.isNull(deserializedInfo.vehicleName, 'vehicleName should be null');
        Assert.isNull(deserializedInfo.serviceTerritoryId, 'serviceTerritoryId should be null');
    }
    
    /**
     * @description Test creating a list of TestDriveInfo objects
     */
    @isTest
    static void testListCreation() {
        List<ServiceTerritory> territories = [SELECT Id FROM ServiceTerritory];
        DateTime now = DateTime.now();
        
        Test.startTest();
        List<TestDriveInfo> infoList = new List<TestDriveInfo>();
        for (Integer i = 0; i < 5; i++) {
            TestDriveInfo info = new TestDriveInfo();
            info.testDriveId = 'TD00' + i;
            info.subject = 'Test Drive ' + i;
            info.startTime = now.addHours(i);
            info.endTime = now.addHours(i + 1);
            info.showRoom = 'Showroom ' + i;
            info.vehicleName = 'Vehicle ' + i;
            info.serviceTerritoryId = territories[Math.mod(i, territories.size())].Id;
            infoList.add(info);
        }
        Test.stopTest();
        
        Assert.areEqual(5, infoList.size(), 'List should contain 5 items');
        Assert.areEqual('TD000', infoList[0].testDriveId, 'First item testDriveId should match');
        Assert.areEqual('TD004', infoList[4].testDriveId, 'Last item testDriveId should match');
    }
    
    /**
     * @description Test with empty strings
     */
    @isTest
    static void testEmptyStrings() {
        Test.startTest();
        TestDriveInfo info = new TestDriveInfo();
        info.testDriveId = '';
        info.subject = '';
        info.showRoom = '';
        info.vehicleName = '';
        info.serviceTerritoryId = '';
        Test.stopTest();
        
        Assert.areEqual('', info.testDriveId, 'testDriveId should be empty string');
        Assert.areEqual('', info.subject, 'subject should be empty string');
        Assert.areEqual('', info.showRoom, 'showRoom should be empty string');
        Assert.areEqual('', info.vehicleName, 'vehicleName should be empty string');
        Assert.areEqual('', info.serviceTerritoryId, 'serviceTerritoryId should be empty string');
    }
    
    /**
     * @description Test DateTime edge cases
     */
    @isTest
    static void testDateTimeEdgeCases() {
        DateTime past = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
        DateTime future = DateTime.newInstance(2030, 12, 31, 23, 59, 59);
        
        Test.startTest();
        TestDriveInfo info = new TestDriveInfo();
        info.startTime = past;
        info.endTime = future;
        Test.stopTest();
        
        Assert.areEqual(past, info.startTime, 'startTime should handle past dates');
        Assert.areEqual(future, info.endTime, 'endTime should handle future dates');
        Assert.isTrue(info.endTime > info.startTime, 'endTime should be after startTime');
    }
    
    /**
     * @description Test with special characters in strings
     */
    @isTest
    static void testSpecialCharacters() {
        Test.startTest();
        TestDriveInfo info = new TestDriveInfo();
        info.testDriveId = 'TD-001-A&B';
        info.subject = 'Test Drive: "Premium" Experience';
        info.showRoom = 'Showroom @ 5th Ave';
        info.vehicleName = 'Model X (2024)';
        Test.stopTest();
        
        Assert.areEqual('TD-001-A&B', info.testDriveId, 'testDriveId should handle special chars');
        Assert.areEqual('Test Drive: "Premium" Experience', info.subject, 'subject should handle quotes');
        Assert.areEqual('Showroom @ 5th Ave', info.showRoom, 'showRoom should handle @ symbol');
        Assert.areEqual('Model X (2024)', info.vehicleName, 'vehicleName should handle parentheses');
    }
    
    /**
     * @description Test with long strings
     */
    @isTest
    static void testLongStrings() {
        String longString = 'A'.repeat(255);
        
        Test.startTest();
        TestDriveInfo info = new TestDriveInfo();
        info.subject = longString;
        info.showRoom = longString;
        info.vehicleName = longString;
        Test.stopTest();
        
        Assert.areEqual(255, info.subject.length(), 'subject should handle 255 chars');
        Assert.areEqual(255, info.showRoom.length(), 'showRoom should handle 255 chars');
        Assert.areEqual(255, info.vehicleName.length(), 'vehicleName should handle 255 chars');
    }
    
    /**
     * @description Test bulk list operations (200+ records)
     */
    @isTest
    static void testBulkOperations() {
        List<ServiceTerritory> territories = [SELECT Id FROM ServiceTerritory];
        DateTime baseTime = DateTime.now();
        
        Test.startTest();
        List<TestDriveInfo> bulkList = new List<TestDriveInfo>();
        for (Integer i = 0; i < 200; i++) {
            TestDriveInfo info = new TestDriveInfo();
            info.testDriveId = 'BULK-' + String.valueOf(i).leftPad(4, '0');
            info.subject = 'Bulk Test Drive ' + i;
            info.startTime = baseTime.addHours(i);
            info.endTime = baseTime.addHours(i + 1);
            info.showRoom = 'Showroom ' + Math.mod(i, 10);
            info.vehicleName = 'Vehicle Type ' + Math.mod(i, 20);
            info.serviceTerritoryId = territories[Math.mod(i, territories.size())].Id;
            bulkList.add(info);
        }
        
        String serialized = JSON.serialize(bulkList);
        Test.stopTest();
        
        Assert.areEqual(200, bulkList.size(), 'Should create 200 records');
        Assert.isNotNull(serialized, 'Serialized string should not be null');
        Assert.isTrue(serialized.contains('BULK-0000'), 'Should contain first record');
        Assert.isTrue(serialized.contains('BULK-0199'), 'Should contain last record');
        Assert.isTrue(serialized.contains('Bulk Test Drive 0'), 'Should contain first subject');
        Assert.isTrue(serialized.contains('Bulk Test Drive 199'), 'Should contain last subject');
    }
    
    /**
     * @description Test round-trip serialization/deserialization preserves data
     */
    @isTest
    static void testRoundTripSerialization() {
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        DateTime startTime = DateTime.newInstance(2024, 6, 15, 10, 30, 0);
        DateTime endTime = DateTime.newInstance(2024, 6, 15, 11, 30, 0);
        
        TestDriveInfo original = new TestDriveInfo();
        original.testDriveId = 'RT-001';
        original.subject = 'Round Trip Test';
        original.startTime = startTime;
        original.endTime = endTime;
        original.showRoom = 'Central Showroom';
        original.vehicleName = 'Porsche Taycan';
        original.serviceTerritoryId = territory.Id;
        
        Test.startTest();
        String jsonStr = JSON.serialize(original);
        TestDriveInfo roundTrip = (TestDriveInfo)JSON.deserialize(jsonStr, TestDriveInfo.class);
        Test.stopTest();
        
        Assert.areEqual(original.testDriveId, roundTrip.testDriveId, 'testDriveId should match');
        Assert.areEqual(original.subject, roundTrip.subject, 'subject should match');
        Assert.areEqual(original.startTime, roundTrip.startTime, 'startTime should match');
        Assert.areEqual(original.endTime, roundTrip.endTime, 'endTime should match');
        Assert.areEqual(original.showRoom, roundTrip.showRoom, 'showRoom should match');
        Assert.areEqual(original.vehicleName, roundTrip.vehicleName, 'vehicleName should match');
        Assert.areEqual(original.serviceTerritoryId, roundTrip.serviceTerritoryId, 'serviceTerritoryId should match');
    }
}