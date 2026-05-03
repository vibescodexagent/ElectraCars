/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : DateTimeConverter
 * Author          : Vibe X
 * Created Date    : Apr 26, 2026
 * Last Modified By: Vibe X
 * Last Modified On: Apr 26, 2026
 * Description     : This class implements for Convert DateTime
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 26, 2026  │ Vibe X   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public with sharing class GetTestDriveFromVoice {

    @InvocableMethod(label='Get Test Drive Id from Voice Call')
    public static List<OutputWrapper> getTestDrive(List<InputWrapper> inputs) {

        List<OutputWrapper> outputs = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {

            OutputWrapper out = new OutputWrapper();
            String phone;
            Id srId;

            for (VoiceCall vc : [SELECT Id, FromPhoneNumber FROM VoiceCall WHERE Id = :input.recordId LIMIT 1 ]) {
                phone = vc.FromPhoneNumber;
            }

            System.debug('Phone: ' + phone);

            for (ServiceResource sr : [ SELECT Id,RelatedRecordId FROM ServiceResource WHERE RelatedRecord.Phone = :phone AND ResourceType = 'T' LIMIT 1 ]) {
                srId = sr.Id;
                out.userId = sr.RelatedRecordId;
            }

            Boolean found = false;
            for (Test_Drive__c td : [Select Id,Name,Service_Appointment__r.ParentRecordId from Test_Drive__c  where Name=:input.testDriveNumber Limit 1]){
                out.testDriveId = td.id;
                out.leadId = td.Service_Appointment__r.ParentRecordId;
            }

            for (AssignedResource ar : [SELECT ServiceAppointment.Id,ServiceAppointment.Subject,ServiceAppointment.Status FROM AssignedResource WHERE ServiceResourceId = :srId]) {

                if (ar.ServiceAppointment != null &&
                    ar.ServiceAppointment.Subject == input.testDriveNumber) {

                    found = true;
                        system.debug('++'+ar.ServiceAppointment.Status);
                    if (ar.ServiceAppointment.Status == 'Completed') {
                        out.message = 'This test drive is already completed. Would you like to comment on any other test drive?';
                        out.testDriveId = null;
                        break;
                    } else {
                        out.message = 'Test Drive found';
                    }

                    break;
                }
            }

            system.debug('testDriveId'+out.testDriveId);

            if (!found) {
                out.testDriveId = null;
                out.message = 'Please provide a correct TestDrive number tagged to you.';
            }

            outputs.add(out);
        }

        return outputs;
    }

    public class InputWrapper {
        @InvocableVariable(required=true)
        public String recordId;

        @InvocableVariable(required=true)
        public String testDriveNumber;
    }

    public class OutputWrapper {
        @InvocableVariable
        public String testDriveId;

        @InvocableVariable
        public String userId;

        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public String leadId;
    }
}