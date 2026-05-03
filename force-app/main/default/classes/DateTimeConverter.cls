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

public inherited sharing class DateTimeConverter {

    public class InputParameters {
        @InvocableVariable(required=true)
        public DateTime preferredDT;
    }

    public class OutputParameters {
        @InvocableVariable(label='Converted DateTime String' description='Adjusted DateTime string in ISO 8601 format with current year, null if date is in the past')
        public String convertedpreferredDT;
    }

    @InvocableMethod(
        label='Validate Preferred DateTime'
        description='Parses an ISO 8601 DateTime string, replaces the year with the current year, converts to the logged-in user timezone, and returns null if the resulting date is in the past.'
    )
    public static List<OutputParameters> ValidatePreferredDT(List<InputParameters> inputs) {

        List<OutputParameters> outputs = new List<OutputParameters>();

        for (InputParameters input : inputs) {

            OutputParameters output = new OutputParameters();

            if (input.preferredDT == null) {
                output.convertedpreferredDT = null;
                outputs.add(output);
                continue;
            }

            try {
                // Parse the ISO 8601 string to DateTime
                //DateTime parsedDT = (DateTime) JSON.deserialize('"' + input.preferredDT + '"', DateTime.class);
                DateTime parsedDT = input.preferredDT;
                // Get logged in user's timezone directly — no SOQL needed
                TimeZone userTZ = UserInfo.getTimeZone();

                // Extract date/time components directly from parsedDT (no offset applied)
                Integer currentYear = Date.today().year();
                Integer month       = parsedDT.monthGmt();
                Integer day         = parsedDT.dayGmt();
                Integer hour        = parsedDT.hourGmt();
                Integer minute      = parsedDT.minuteGmt();
                Integer second      = parsedDT.secondGmt();

                // Rebuild DateTime with current year using extracted components
                DateTime adjustedDT = DateTime.newInstanceGmt(
                    currentYear, month, day, hour, minute, second
                );

                // Convert adjustedDT to user's local timezone
                Integer adjustedOffsetMs = userTZ.getOffset(adjustedDT);
                DateTime adjustedUserDT  = adjustedDT.addSeconds(adjustedOffsetMs / 1000);
                DateTime currentDateTime = DateTime.now().addSeconds(adjustedOffsetMs / 1000);
                // Return null if adjusted DateTime is not in the future (in user's timezone)
                if (adjustedUserDT <= currentDateTime) {
                    output.convertedpreferredDT = null;
                    outputs.add(output);
                    continue;
                }
               // output.convertedpreferredDT = adjustedUserDT;
                // Format timezone offset as +HH:MM or -HH:MM
                Integer totalMinutes  = adjustedOffsetMs / 60000;
                String  sign          = totalMinutes >= 0 ? '+' : '-';
                Integer absMinutes    = Math.abs(totalMinutes);
                Integer offsetHours   = absMinutes / 60;
                Integer offsetMinutes = Math.mod(absMinutes, 60);

                String offsetString = sign
                    + String.valueOf(offsetHours).leftPad(2, '0')
                    + String.valueOf(offsetMinutes).leftPad(2, '0');

                // Build ISO 8601 string: yyyy-MM-ddTHH:mm:ss.000+0000
                String isoString =
                    String.valueOf(currentYear)                             + '-' +
                    String.valueOf(adjustedUserDT.monthGmt()).leftPad(2, '0')  + '-' +
                    String.valueOf(adjustedUserDT.dayGmt()).leftPad(2, '0')    + 'T' +
                    String.valueOf(adjustedUserDT.hourGmt()).leftPad(2, '0')   + ':' +
                    String.valueOf(adjustedUserDT.minuteGmt()).leftPad(2, '0') + ':' +
                    String.valueOf(adjustedUserDT.secondGmt()).leftPad(2, '0') + '.000' +
                    offsetString;
                system.debug('$#$#$#$ '+isoString);
                output.convertedpreferredDT = isoString;

            } catch (Exception e) {
                System.debug('DateTimeConverter Error: ' + e.getMessage());
                output.convertedpreferredDT = null;
            }

            outputs.add(output);
        }

        return outputs;
    }
}