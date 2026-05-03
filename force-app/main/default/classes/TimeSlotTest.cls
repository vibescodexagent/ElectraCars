@isTest
private class TimeSlotTest {
    
    @testSetup
    static void setup() {
        // Create test data using TestDataFactory
        
        // Create Account and Contact for vehicles
        List<Account> accounts = TestDataFactory.createAccounts(2, true);
        List<Contact> contacts = TestDataFactory.createContacts(2, false);
        
        // Associate Contacts with Accounts
        for (Integer i = 0; i < contacts.size(); i++) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;
        
        // Create Vehicle Assets
        List<Asset> vehicles = TestDataFactory.createVehicleAssets(
            3, 
            'Test Vehicle', 
            accounts[0].Id, 
            contacts[0].Id, 
            true
        );
    }
    
    @isTest
    static void testTimeSlotInstantiation() {
        // Test creating a TimeSlot instance
        Test.startTest();
        
        TimeSlot timeSlot = new TimeSlot();
        timeSlot.slot = '09:00 AM - 10:00 AM';
        timeSlot.vehicleId = 'VEH001';
        timeSlot.serviceResourceId = 'SR001';
        
        Test.stopTest();
        
        // Verify properties are set correctly
        System.assertEquals('09:00 AM - 10:00 AM', timeSlot.slot, 'Slot should be set correctly');
        System.assertEquals('VEH001', timeSlot.vehicleId, 'Vehicle ID should be set correctly');
        System.assertEquals('SR001', timeSlot.serviceResourceId, 'Service Resource ID should be set correctly');
    }
    
    @isTest
    static void testTimeSlotWithNullValues() {
        // Test TimeSlot with null values
        Test.startTest();
        
        TimeSlot timeSlot = new TimeSlot();
        // Don't set any values
        
        Test.stopTest();
        
        // Verify default null values
        System.assertEquals(null, timeSlot.slot, 'Slot should be null by default');
        System.assertEquals(null, timeSlot.vehicleId, 'Vehicle ID should be null by default');
        System.assertEquals(null, timeSlot.serviceResourceId, 'Service Resource ID should be null by default');
    }
    
    @isTest
    static void testTimeSlotSerialization() {
        // Test JSON serialization of TimeSlot
        Test.startTest();
        
        TimeSlot timeSlot = new TimeSlot();
        timeSlot.slot = '10:00 AM - 11:00 AM';
        timeSlot.vehicleId = 'VEH002';
        timeSlot.serviceResourceId = 'SR002';
        
        // Serialize to JSON
        String jsonString = JSON.serialize(timeSlot);
        
        Test.stopTest();
        
        // Verify serialization
        System.assertNotEquals(null, jsonString, 'JSON string should not be null');
        System.assert(jsonString.contains('10:00 AM - 11:00 AM'), 'JSON should contain slot value');
        System.assert(jsonString.contains('VEH002'), 'JSON should contain vehicle ID');
        System.assert(jsonString.contains('SR002'), 'JSON should contain service resource ID');
    }
    
    @isTest
    static void testTimeSlotDeserialization() {
        // Test JSON deserialization to TimeSlot
        Test.startTest();
        
        String jsonString = '{"slot":"11:00 AM - 12:00 PM","vehicleId":"VEH003","serviceResourceId":"SR003"}';
        TimeSlot timeSlot = (TimeSlot) JSON.deserialize(jsonString, TimeSlot.class);
        
        Test.stopTest();
        
        // Verify deserialization
        System.assertNotEquals(null, timeSlot, 'TimeSlot should not be null');
        System.assertEquals('11:00 AM - 12:00 PM', timeSlot.slot, 'Slot should be deserialized correctly');
        System.assertEquals('VEH003', timeSlot.vehicleId, 'Vehicle ID should be deserialized correctly');
        System.assertEquals('SR003', timeSlot.serviceResourceId, 'Service Resource ID should be deserialized correctly');
    }
    
    @isTest
    static void testTimeSlotListOperations() {
        // Test creating a list of TimeSlot objects
        Test.startTest();
        
        List<TimeSlot> timeSlots = new List<TimeSlot>();
        
        for (Integer i = 0; i < 5; i++) {
            TimeSlot timeSlot = new TimeSlot();
            timeSlot.slot = (9 + i) + ':00 AM - ' + (10 + i) + ':00 AM';
            timeSlot.vehicleId = 'VEH' + i;
            timeSlot.serviceResourceId = 'SR' + i;
            timeSlots.add(timeSlot);
        }
        
        Test.stopTest();
        
        // Verify list operations
        System.assertEquals(5, timeSlots.size(), 'Should have 5 time slots in list');
        System.assertEquals('9:00 AM - 10:00 AM', timeSlots[0].slot, 'First slot should match');
        System.assertEquals('SR4', timeSlots[4].serviceResourceId, 'Last service resource ID should match');
    }
    
    @isTest
    static void testTimeSlotWithAssetData() {
        // Test using TimeSlot with actual Asset data from TestDataFactory
        Test.startTest();
        
        List<Asset> vehicles = [SELECT Id, Name FROM Asset LIMIT 3];
        List<TimeSlot> timeSlots = new List<TimeSlot>();
        
        for (Integer i = 0; i < vehicles.size(); i++) {
            TimeSlot timeSlot = new TimeSlot();
            timeSlot.slot = (9 + i) + ':00 AM - ' + (10 + i) + ':00 AM';
            timeSlot.vehicleId = vehicles[i].Id;
            timeSlot.serviceResourceId = 'SR' + i;
            timeSlots.add(timeSlot);
        }
        
        Test.stopTest();
        
        // Verify data population
        System.assertEquals(3, timeSlots.size(), 'Should have 3 time slots from vehicles');
        for (TimeSlot ts : timeSlots) {
            System.assertNotEquals(null, ts.slot, 'Slot should not be null');
            System.assertNotEquals(null, ts.vehicleId, 'Vehicle ID should not be null');
            System.assertNotEquals(null, ts.serviceResourceId, 'Service Resource ID should not be null');
        }
    }
    
    @isTest
    static void testTimeSlotWithMixedData() {
        // Test using TimeSlot with Asset data and string IDs
        Test.startTest();
        
        List<Asset> vehicles = [SELECT Id FROM Asset LIMIT 3];
        List<TimeSlot> timeSlots = new List<TimeSlot>();
        
        for (Integer i = 0; i < vehicles.size(); i++) {
            TimeSlot timeSlot = new TimeSlot();
            timeSlot.slot = (14 + i) + ':00 PM - ' + (15 + i) + ':00 PM';
            timeSlot.vehicleId = vehicles[i].Id;
            timeSlot.serviceResourceId = 'SR' + i; // Using string ID for service resource
            timeSlots.add(timeSlot);
        }
        
        Test.stopTest();
        
        // Verify data population
        System.assertEquals(3, timeSlots.size(), 'Should have 3 time slots');
        for (TimeSlot ts : timeSlots) {
            System.assertNotEquals(null, ts.slot, 'Slot should not be null');
            System.assertNotEquals(null, ts.vehicleId, 'Vehicle ID should not be null');
            System.assertNotEquals(null, ts.serviceResourceId, 'Service Resource ID should not be null');
        }
    }
    
    @isTest
    static void testTimeSlotAuraEnabledAnnotations() {
        // Test that @AuraEnabled properties work correctly with Lightning components
        Test.startTest();
        
        TimeSlot timeSlot = new TimeSlot();
        timeSlot.slot = '02:00 PM - 03:00 PM';
        timeSlot.vehicleId = 'AURA_VEH';
        timeSlot.serviceResourceId = 'AURA_SR';
        
        // Serialize as would be done when returning to Lightning component
        String jsonForAura = JSON.serialize(timeSlot);
        
        Test.stopTest();
        
        // Verify Aura-enabled serialization
        System.assertNotEquals(null, jsonForAura, 'Aura JSON should not be null');
        System.assert(jsonForAura.contains('slot'), 'Should contain slot property');
        System.assert(jsonForAura.contains('vehicleId'), 'Should contain vehicleId property');
        System.assert(jsonForAura.contains('serviceResourceId'), 'Should contain serviceResourceId property');
    }
    
    @isTest
    static void testBulkTimeSlotCreation() {
        // Test bulk creation to ensure no governor limit issues
        Test.startTest();
        
        List<TimeSlot> bulkTimeSlots = new List<TimeSlot>();
        
        for (Integer i = 0; i < 200; i++) {
            TimeSlot timeSlot = new TimeSlot();
            timeSlot.slot = 'Slot ' + i;
            timeSlot.vehicleId = 'VEH' + i;
            timeSlot.serviceResourceId = 'SR' + i;
            bulkTimeSlots.add(timeSlot);
        }
        
        // Serialize all time slots
        String bulkJson = JSON.serialize(bulkTimeSlots);
        
        Test.stopTest();
        
        // Verify bulk operations
        System.assertEquals(200, bulkTimeSlots.size(), 'Should have 200 time slots');
        System.assertNotEquals(null, bulkJson, 'Bulk JSON should not be null');
    }
    
    @isTest
    static void testTimeSlotPropertyModification() {
        // Test modifying properties after instantiation
        Test.startTest();
        
        TimeSlot timeSlot = new TimeSlot();
        timeSlot.slot = 'Original Slot';
        timeSlot.vehicleId = 'ORIG_VEH';
        timeSlot.serviceResourceId = 'ORIG_SR';
        
        // Modify properties
        timeSlot.slot = 'Modified Slot';
        timeSlot.vehicleId = 'MOD_VEH';
        timeSlot.serviceResourceId = 'MOD_SR';
        
        Test.stopTest();
        
        // Verify modifications
        System.assertEquals('Modified Slot', timeSlot.slot, 'Slot should be updated');
        System.assertEquals('MOD_VEH', timeSlot.vehicleId, 'Vehicle ID should be updated');
        System.assertEquals('MOD_SR', timeSlot.serviceResourceId, 'Service Resource ID should be updated');
    }
    
    @isTest
    static void testTimeSlotWithVariousTimeFormats() {
        // Test TimeSlot with different time slot formats
        Test.startTest();
        
        List<TimeSlot> timeSlots = new List<TimeSlot>();
        
        // 12-hour format
        TimeSlot ts1 = new TimeSlot();
        ts1.slot = '09:00 AM - 10:00 AM';
        ts1.vehicleId = 'VEH1';
        ts1.serviceResourceId = 'SR1';
        timeSlots.add(ts1);
        
        // 24-hour format
        TimeSlot ts2 = new TimeSlot();
        ts2.slot = '14:00 - 15:00';
        ts2.vehicleId = 'VEH2';
        ts2.serviceResourceId = 'SR2';
        timeSlots.add(ts2);
        
        // Custom format
        TimeSlot ts3 = new TimeSlot();
        ts3.slot = 'Morning Slot';
        ts3.vehicleId = 'VEH3';
        ts3.serviceResourceId = 'SR3';
        timeSlots.add(ts3);
        
        Test.stopTest();
        
        // Verify all formats are supported
        System.assertEquals(3, timeSlots.size(), 'Should have 3 time slots with different formats');
        System.assertEquals('09:00 AM - 10:00 AM', timeSlots[0].slot, '12-hour format should be stored');
        System.assertEquals('14:00 - 15:00', timeSlots[1].slot, '24-hour format should be stored');
        System.assertEquals('Morning Slot', timeSlots[2].slot, 'Custom format should be stored');
    }
    
    @isTest
    static void testTimeSlotWithCompleteScenario() {
        // Test a complete scenario using TestDataFactory data
        Test.startTest();
        
        // Get test data
        Asset vehicle = [SELECT Id, Name FROM Asset LIMIT 1];
        
        // Create time slots for a day
        List<TimeSlot> dailySlots = new List<TimeSlot>();
        
        String[] slots = new String[]{'09:00 AM - 10:00 AM', '10:00 AM - 11:00 AM', '11:00 AM - 12:00 PM', 
                                      '01:00 PM - 02:00 PM', '02:00 PM - 03:00 PM', '03:00 PM - 04:00 PM'};
        
        for (Integer i = 0; i < slots.size(); i++) {
            TimeSlot timeSlot = new TimeSlot();
            timeSlot.slot = slots[i];
            timeSlot.vehicleId = vehicle.Id;
            timeSlot.serviceResourceId = 'SR00' + i; // Using string ID
            dailySlots.add(timeSlot);
        }
        
        // Serialize for Lightning component
        String jsonSlots = JSON.serialize(dailySlots);
        
        Test.stopTest();
        
        // Verify complete scenario
        System.assertEquals(6, dailySlots.size(), 'Should have 6 time slots for the day');
        System.assertNotEquals(null, jsonSlots, 'JSON should be generated for Lightning component');
        
        // Verify first and last slots
        System.assertEquals('09:00 AM - 10:00 AM', dailySlots[0].slot, 'First slot should be morning');
        System.assertEquals('03:00 PM - 04:00 PM', dailySlots[5].slot, 'Last slot should be afternoon');
    }
}