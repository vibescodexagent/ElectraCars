public class LeadConverterAction {
    @InvocableMethod(label='Finalize Lead Conversion' description='Marks Lead as converted using existing Account/Contact/Opportunity IDs')
    public static List<String> finalizeConversion(List<ConvertRequest> requests) {
        List<String> results = new List<String>();
        
        for (ConvertRequest req : requests) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(req.leadId);
            lc.setAccountId(req.accountId);
            lc.setContactId(req.contactId);
            lc.setOpportunityId(req.opportunityId);
            lc.setConvertedStatus(req.convertedStatus);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            
            if (lcr.isSuccess()) {
                results.add('Success');
            } else {
                results.add('Error: ' + lcr.getErrors()[0].getMessage());
            }
        }
        return results;
    }

    public class ConvertRequest {
        @InvocableVariable(required=true) public Id leadId;
        @InvocableVariable(required=true) public Id accountId;
        @InvocableVariable(required=true) public Id contactId;
        @InvocableVariable(required=true) public Id opportunityId;
        @InvocableVariable(required=true) public String convertedStatus;
    }
}