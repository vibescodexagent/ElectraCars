@isTest
private class TestDriveScoringPromptJSONParserTest {
    
    @testSetup
    static void setup() {
        // Create test data using TestDataFactory
        
        // Create Account and Contact
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = TestDataFactory.createContacts(1, false);
        contacts[0].AccountId = accounts[0].Id;
        insert contacts;
        
        // Create Vehicle Assets for test drive scenarios
        List<Asset> vehicles = TestDataFactory.createVehicleAssets(
            2, 
            'Test Vehicle', 
            accounts[0].Id, 
            contacts[0].Id, 
            true
        );
    }
    
    @isTest
    static void testParseValidSingleResponse() {
        // Test parsing a valid single JSON response
        Test.startTest();
        
        String jsonResponse = '{"Score":85,"Recommendation":"Highly recommended for purchase"}';
        List<String> responses = new List<String>{jsonResponse};
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have 1 result');
        System.assertEquals(85, results[0].Score, 'Score should be 85');
        System.assertEquals('Highly recommended for purchase', results[0].Recommendation, 'Recommendation should match');
    }
    
    @isTest
    static void testParseMultipleResponses() {
        // Test parsing multiple JSON responses
        Test.startTest();
        
        List<String> responses = new List<String>{
            '{"Score":90,"Recommendation":"Excellent driving experience"}',
            '{"Score":75,"Recommendation":"Good performance, minor improvements needed"}',
            '{"Score":60,"Recommendation":"Average experience"}',
            '{"Score":95,"Recommendation":"Outstanding vehicle performance"}'
        };
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(4, results.size(), 'Should have 4 results');
        System.assertEquals(90, results[0].Score, 'First score should be 90');
        System.assertEquals(75, results[1].Score, 'Second score should be 75');
        System.assertEquals(60, results[2].Score, 'Third score should be 60');
        System.assertEquals(95, results[3].Score, 'Fourth score should be 95');
        
        System.assertEquals('Excellent driving experience', results[0].Recommendation, 'First recommendation should match');
        System.assertEquals('Outstanding vehicle performance', results[3].Recommendation, 'Last recommendation should match');
    }
    
    @isTest
    static void testParseWithZeroScore() {
        // Test parsing with zero score
        Test.startTest();
        
        String jsonResponse = '{"Score":0,"Recommendation":"Vehicle requires significant improvements"}';
        List<String> responses = new List<String>{jsonResponse};
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have 1 result');
        System.assertEquals(0, results[0].Score, 'Score should be 0');
        System.assertNotEquals(null, results[0].Recommendation, 'Recommendation should not be null');
    }
    
    @isTest
    static void testParseWithMaxScore() {
        // Test parsing with maximum score
        Test.startTest();
        
        String jsonResponse = '{"Score":100,"Recommendation":"Perfect vehicle"}';
        List<String> responses = new List<String>{jsonResponse};
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have 1 result');
        System.assertEquals(100, results[0].Score, 'Score should be 100');
        System.assertEquals('Perfect vehicle', results[0].Recommendation, 'Recommendation should match');
    }
    
    @isTest
    static void testParseWithEmptyRecommendation() {
        // Test parsing with empty recommendation
        Test.startTest();
        
        String jsonResponse = '{"Score":50,"Recommendation":""}';
        List<String> responses = new List<String>{jsonResponse};
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have 1 result');
        System.assertEquals(50, results[0].Score, 'Score should be 50');
        System.assertEquals('', results[0].Recommendation, 'Recommendation should be empty string');
    }
    
    @isTest
    static void testParseWithLongRecommendation() {
        // Test parsing with long recommendation text
        Test.startTest();
        
        String longRecommendation = 'This vehicle demonstrates exceptional performance across all metrics including acceleration, ' +
                                   'braking, handling, comfort, and fuel efficiency. The driver reported a highly satisfying ' +
                                   'experience with particular praise for the advanced safety features and intuitive controls.';
        String jsonResponse = '{"Score":88,"Recommendation":"' + longRecommendation + '"}';
        List<String> responses = new List<String>{jsonResponse};
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have 1 result');
        System.assertEquals(88, results[0].Score, 'Score should be 88');
        System.assertEquals(longRecommendation, results[0].Recommendation, 'Long recommendation should be preserved');
    }
    
    @isTest
    static void testParseEmptyList() {
        // Test parsing empty list
        Test.startTest();
        
        List<String> emptyResponses = new List<String>();
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(emptyResponses);
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Results should be empty');
    }
    
    
    @isTest
    static void testParseWithSpecialCharacters() {
        // Test parsing with special characters in recommendation
        Test.startTest();
        
        String specialRecommendation = 'Vehicle performance is good! Driver said: "It\'s amazing" & rated 4.5/5 stars.';
        String jsonResponse = '{"Score":92,"Recommendation":"' + specialRecommendation.replace('"', '\\"') + '"}';
        List<String> responses = new List<String>{jsonResponse};
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have 1 result');
        System.assertEquals(92, results[0].Score, 'Score should be 92');
        System.assertNotEquals(null, results[0].Recommendation, 'Recommendation should not be null');
    }
    
    @isTest
    static void testParseWithVehicleContext() {
        // Test parsing with actual vehicle data from TestDataFactory
        Test.startTest();
        
        // Get test vehicle data
        List<Asset> vehicles = [SELECT Id, Name FROM Asset LIMIT 2];
        
        List<String> responses = new List<String>();
        for (Asset vehicle : vehicles) {
            String recommendation = 'Test drive completed for ' + vehicle.Name + ' - Positive feedback received';
            responses.add('{"Score":87,"Recommendation":"' + recommendation + '"}');
        }
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, results.size(), 'Should have 2 results matching vehicle count');
        System.assertEquals(87, results[0].Score, 'Score should be 87');
        System.assert(results[0].Recommendation.contains('Test drive completed'), 'Recommendation should contain test drive text');
    }
    
    @isTest
    static void testResponseWrapperStructure() {
        // Test the ResponseWrapper inner class structure
        Test.startTest();
        
        TestDriveScoringPromptJSONParser.ResponseWrapper wrapper = 
            new TestDriveScoringPromptJSONParser.ResponseWrapper();
        wrapper.Score = 78;
        wrapper.Recommendation = 'Test recommendation';
        
        Test.stopTest();
        
        // Verify properties
        System.assertEquals(78, wrapper.Score, 'Score should be set');
        System.assertEquals('Test recommendation', wrapper.Recommendation, 'Recommendation should be set');
    }
    
    @isTest
    static void testParseWithVariousScoreRanges() {
        // Test parsing with various score ranges
        Test.startTest();
        
        List<String> responses = new List<String>{
            '{"Score":10,"Recommendation":"Poor - needs improvement"}',
            '{"Score":25,"Recommendation":"Below average"}',
            '{"Score":50,"Recommendation":"Average performance"}',
            '{"Score":75,"Recommendation":"Good performance"}',
            '{"Score":90,"Recommendation":"Excellent performance"}'
        };
        
        List<TestDriveScoringPromptJSONParser.ResponseWrapper> results = 
            TestDriveScoringPromptJSONParser.parseResponse(responses);
        
        Test.stopTest();
        
        // Verify score ranges
        System.assertEquals(5, results.size(), 'Should have 5 results');
        System.assert(results[0].Score < 20, 'First score should be in poor range');
        System.assert(results[2].Score == 50, 'Third score should be average');
        System.assert(results[4].Score > 85, 'Last score should be in excellent range');
    }
}