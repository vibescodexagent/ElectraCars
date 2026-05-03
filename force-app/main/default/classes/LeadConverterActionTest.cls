@isTest
private class LeadConverterActionTest {
    
    @testSetup
    static void setup() {
        // Create test data using TestDataFactory
        
        // Create Accounts
        List<Account> accounts = TestDataFactory.createAccounts(3, true);
        
        // Create Contacts associated with Accounts
        List<Contact> contacts = TestDataFactory.createContacts(3, false);
        for (Integer i = 0; i < contacts.size(); i++) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;
        
        // Create Leads
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Status = 'Open - Not Contacted',
                Email = 'testlead' + i + '@test.com'
            ));
        }
        insert leads;
        
        // Create Opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            opps.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = accounts[i].Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opps;
    }
    
    @isTest
    static void testSuccessfulLeadConversion() {
        // Test successful lead conversion with all required IDs
        Test.startTest();
        
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'Lead 0' LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :account.Id LIMIT 1];
        
        // Get converted status
        LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        
        LeadConverterAction.ConvertRequest request = new LeadConverterAction.ConvertRequest();
        request.leadId = lead.Id;
        request.accountId = account.Id;
        request.contactId = contact.Id;
        request.opportunityId = opp.Id;
        request.convertedStatus = convertStatus.MasterLabel;
        
        List<LeadConverterAction.ConvertRequest> requests = new List<LeadConverterAction.ConvertRequest>();
        requests.add(request);
        
        List<String> results = LeadConverterAction.finalizeConversion(requests);
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have 1 result');
        System.assertEquals('Success', results[0], 'Conversion should be successful');
        
        // Verify lead is converted
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted');
        System.assertEquals(account.Id, convertedLead.ConvertedAccountId, 'Converted Account should match');
        System.assertEquals(contact.Id, convertedLead.ConvertedContactId, 'Converted Contact should match');
        System.assertEquals(opp.Id, convertedLead.ConvertedOpportunityId, 'Converted Opportunity should match');
    }
    
    @isTest
    static void testBulkLeadConversion() {
        // Test bulk conversion of multiple leads
        Test.startTest();
        
        List<Lead> leads = [SELECT Id FROM Lead ORDER BY LastName LIMIT 3];
        List<Account> accounts = [SELECT Id FROM Account ORDER BY Name LIMIT 3];
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact ORDER BY AccountId LIMIT 3];
        List<Opportunity> opps = [SELECT Id FROM Opportunity ORDER BY Name LIMIT 3];
        
        LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        
        List<LeadConverterAction.ConvertRequest> requests = new List<LeadConverterAction.ConvertRequest>();
        
        for (Integer i = 0; i < 3; i++) {
            LeadConverterAction.ConvertRequest request = new LeadConverterAction.ConvertRequest();
            request.leadId = leads[i].Id;
            request.accountId = accounts[i].Id;
            request.contactId = contacts[i].Id;
            request.opportunityId = opps[i].Id;
            request.convertedStatus = convertStatus.MasterLabel;
            requests.add(request);
        }
        
        List<String> results = LeadConverterAction.finalizeConversion(requests);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(3, results.size(), 'Should have 3 results');
        for (String result : results) {
            System.assertEquals('Success', result, 'All conversions should be successful');
        }
        
        // Verify all leads are converted
        List<Lead> convertedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :leads];
        System.assertEquals(3, convertedLeads.size(), 'Should have 3 converted leads');
        for (Lead lead : convertedLeads) {
            System.assertEquals(true, lead.IsConverted, 'Lead should be converted');
        }
    }
    
 
    @isTest
    static void testConvertRequestDataStructure() {
        // Test the ConvertRequest inner class structure
        Test.startTest();
        
        LeadConverterAction.ConvertRequest request = new LeadConverterAction.ConvertRequest();
        request.leadId = '00Q000000000000';
        request.accountId = '001000000000000';
        request.contactId = '003000000000000';
        request.opportunityId = '006000000000000';
        request.convertedStatus = 'Qualified';
        
        Test.stopTest();
        
        // Verify properties are set
        System.assertNotEquals(null, request.leadId, 'Lead ID should be set');
        System.assertNotEquals(null, request.accountId, 'Account ID should be set');
        System.assertNotEquals(null, request.contactId, 'Contact ID should be set');
        System.assertNotEquals(null, request.opportunityId, 'Opportunity ID should be set');
        System.assertNotEquals(null, request.convertedStatus, 'Converted Status should be set');
    }
    
    @isTest
    static void testEmptyRequestList() {
        // Test with empty request list
        Test.startTest();
        
        List<LeadConverterAction.ConvertRequest> emptyRequests = new List<LeadConverterAction.ConvertRequest>();
        List<String> results = LeadConverterAction.finalizeConversion(emptyRequests);
        
        Test.stopTest();
        
        // Verify empty results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Results should be empty for empty request list');
    }
}