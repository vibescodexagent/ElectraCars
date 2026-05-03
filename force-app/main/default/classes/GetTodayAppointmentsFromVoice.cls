public with sharing class GetTodayAppointmentsFromVoice {
    
    @InvocableMethod(label='Get Today Service Appointments from Voice Call')
    public static List<OutputWrapper> getAppointments(List<InputWrapper> inputs) {
        
        List<OutputWrapper> outputs = new List<OutputWrapper>();
        
        if (inputs == null || inputs.isEmpty()) {
            return outputs;
        }
        
        String recordId = inputs[0].recordId;
        String tdNumber = inputs[0].testDriveNumber;
        
        OutputWrapper out = new OutputWrapper();
        out.jsonResult = '[]';
        
        if (!String.isBlank(recordId)) {
            
            try {
                Id voiceCallId = (Id) recordId;
                String phone = null;
                
                for(VoiceCall vc:[SELECT Id, FromPhoneNumber FROM VoiceCall WHERE Id = :voiceCallId LIMIT 1]){
                    phone = vc.FromPhoneNumber;
                }
                
                System.debug('vc+++'+phone);
                if (!String.isBlank(phone) && phone != null ) {
                    
                    Id srId = null;
                    for(ServiceResource sr:[SELECT Id FROM ServiceResource WHERE RelatedRecordId != null and ResourceType = 'T' and RelatedRecord.Phone = :phone LIMIT 1]){
                        srId = sr.id;
                    }
                    system.debug('srid++'+srId);
                    if (!String.isBlank(srId) && srId != null ) {                   
                        
                        
                        DateTime nowDT = System.now();
                        DateTime endOfDay = DateTime.newInstance(
                            Date.today(),
                            Time.newInstance(23, 59, 59, 0)
                        );
                        
                        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
                        ServiceAppointment sa = null;
                        ServiceResource userName = null;
                        
                        Set<String> excludedStatuses = new Set<String>{'Canceled','Completed'};
                            DateTime scheduleStartTime  = null;
                        DateTimeConverter.InputParameters inputPra = new DateTimeConverter.InputParameters();
                        List<DateTimeConverter.InputParameters> requests = new List<DateTimeConverter.InputParameters>();
                        for (AssignedResource ar : [SELECT ServiceAppointment.Id,
                                                    ServiceAppointment.SchedStartTime,
                                                    ServiceAppointment.ModelName__c,
                                                    ServiceAppointment.ServiceTerritory.Name,
                                                    ServiceAppointment.ServiceTerritory.OperatingHours.TimeZone,
                                                    ServiceAppointment.ParentRecord.Name,
                                                    ServiceAppointment.subject,
                                                    ServiceResourceId,
                                                    ServiceResource.RelatedRecord.Name
                                                    FROM AssignedResource
                                                    WHERE ServiceResourceId = :srId
                                                    AND ServiceAppointment.SchedStartTime > :nowDT
                                                    AND ServiceAppointment.SchedStartTime < :endOfDay
                                                    AND ServiceAppointment.Status NOT IN :excludedStatuses
                                                    ORDER BY ServiceAppointment.SchedStartTime ASC]) {
                                                        system.debug('tdNumber'+tdNumber);
                                                        system.debug('sub'+ar.ServiceAppointment.subject);
                                                        
                       if((String.isBlank(tdNumber) || tdNumber == null) || tdNumber.equals(ar.ServiceAppointment.subject)){
                                                            
                                                           
                                                            
                                                            sa = ar.ServiceAppointment;
                                                            userName = ar.ServiceResource;
                                                            inputPra.preferredDT = sa.SchedStartTime;
                                                            requests.add(inputPra);                            
                                                            
                                                            Map<String, Object> rec = new Map<String, Object>();
                           									rec.put('ServiceResourceId',ar.ServiceResourceId);
                                                            rec.put('territory',sa.ServiceTerritory.Name);
                                                            rec.put('sales_rep_name',userName.RelatedRecord.Name);
                                                            rec.put('model_name', sa.ModelName__c);
                           									rec.put('testDriveNumber',sa.subject);
                                                            rec.put('start_time', DateTimeConverter.ValidatePreferredDT(requests)[0].convertedpreferredDT);
                                                            rec.put('name', sa.ParentRecord != null ? sa.ParentRecord.Name : null);
                                                            
                                                            resultList.add(rec);
                                                        }
                                                    }     
                        System.debug('resultList+++'+resultList);
                        out.jsonResult = JSON.serialize(resultList);                        
                    }
                }
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
                out.jsonResult = '[]';
            }
        }
        outputs.add(out);
        
        
        return outputs;
    }
    
    public class InputWrapper {
        @InvocableVariable(required=true)
        public String recordId; 
        
        @InvocableVariable(required=false)
        public String testDriveNumber;
    }
    
    public class OutputWrapper {
        @InvocableVariable
        public String jsonResult;
    }
}