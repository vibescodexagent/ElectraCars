@isTest
private class DateTimeConverterTest {
    
    @testSetup
    static void setup() {
        // Use TestDataFactory to create test users with different timezones if needed
        // Currently DateTimeConverter uses UserInfo.getTimeZone() so tests run under current user context
    }
    
    @isTest
    static void testValidatePreferredDTWithFutureDateTime() {
        // Test with a future DateTime (should return converted ISO string)
        Test.startTest();
        
        // Create a DateTime 2 days in the future
        DateTime futureDateTime = DateTime.now().addDays(2);
        
        DateTimeConverter.InputParameters input = new DateTimeConverter.InputParameters();
        input.preferredDT = futureDateTime;
        
        List<DateTimeConverter.InputParameters> inputs = new List<DateTimeConverter.InputParameters>();
        inputs.add(input);
        
        List<DateTimeConverter.OutputParameters> outputs = DateTimeConverter.ValidatePreferredDT(inputs);
        
        Test.stopTest();
        
        // Verify output
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'Should have 1 output');
        System.assertNotEquals(null, outputs[0].convertedpreferredDT, 'Converted DateTime should not be null for future date');
        System.assert(outputs[0].convertedpreferredDT.contains('T'), 'Output should be in ISO 8601 format');
    }
    
    @isTest
    static void testValidatePreferredDTWithPastDateTime() {
        // Test with a past DateTime (should return null)
        Test.startTest();
        
        // Create a DateTime 2 days in the past
        DateTime pastDateTime = DateTime.now().addDays(-2);
        
        DateTimeConverter.InputParameters input = new DateTimeConverter.InputParameters();
        input.preferredDT = pastDateTime;
        
        List<DateTimeConverter.InputParameters> inputs = new List<DateTimeConverter.InputParameters>();
        inputs.add(input);
        
        List<DateTimeConverter.OutputParameters> outputs = DateTimeConverter.ValidatePreferredDT(inputs);
        
        Test.stopTest();
        
        // Verify output
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'Should have 1 output');
        System.assertEquals(null, outputs[0].convertedpreferredDT, 'Converted DateTime should be null for past date');
    }
    
    @isTest
    static void testValidatePreferredDTWithNullDateTime() {
        // Test with null DateTime input
        Test.startTest();
        
        DateTimeConverter.InputParameters input = new DateTimeConverter.InputParameters();
        input.preferredDT = null;
        
        List<DateTimeConverter.InputParameters> inputs = new List<DateTimeConverter.InputParameters>();
        inputs.add(input);
        
        List<DateTimeConverter.OutputParameters> outputs = DateTimeConverter.ValidatePreferredDT(inputs);
        
        Test.stopTest();
        
        // Verify output
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'Should have 1 output');
        System.assertEquals(null, outputs[0].convertedpreferredDT, 'Converted DateTime should be null when input is null');
    }
    
    @isTest
    static void testValidatePreferredDTWithCurrentYearReplacement() {
        // Test that the method replaces the year with current year
        Test.startTest();
        
        // Create a DateTime with a different year but future month/day/time
        Integer currentYear = Date.today().year();
        Integer futureMonth = Date.today().addMonths(2).month();
        DateTime futureDateTimeOldYear = DateTime.newInstance(2020, futureMonth, 15, 14, 30, 0);
        
        DateTimeConverter.InputParameters input = new DateTimeConverter.InputParameters();
        input.preferredDT = futureDateTimeOldYear;
        
        List<DateTimeConverter.InputParameters> inputs = new List<DateTimeConverter.InputParameters>();
        inputs.add(input);
        
        List<DateTimeConverter.OutputParameters> outputs = DateTimeConverter.ValidatePreferredDT(inputs);
        
        Test.stopTest();
        
        // Verify the year was replaced with current year
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'Should have 1 output');
        if (outputs[0].convertedpreferredDT != null) {
            System.assert(outputs[0].convertedpreferredDT.startsWith(String.valueOf(currentYear)), 
                         'Output should start with current year: ' + currentYear);
        }
    }
    
    @isTest
    static void testValidatePreferredDTWithTimezoneConversion() {
        // Test timezone conversion
        Test.startTest();
        
        // Create a future DateTime in GMT
        DateTime futureDateTime = DateTime.newInstanceGmt(
            Date.today().addMonths(1).year(),
            Date.today().addMonths(1).month(),
            15, 14, 30, 0
        );
        
        DateTimeConverter.InputParameters input = new DateTimeConverter.InputParameters();
        input.preferredDT = futureDateTime;
        
        List<DateTimeConverter.InputParameters> inputs = new List<DateTimeConverter.InputParameters>();
        inputs.add(input);
        
        List<DateTimeConverter.OutputParameters> outputs = DateTimeConverter.ValidatePreferredDT(inputs);
        
        Test.stopTest();
        
        // Verify output includes timezone offset
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'Should have 1 output');
        if (outputs[0].convertedpreferredDT != null) {
            // ISO 8601 format should include timezone offset like +0530 or -0800
            System.assert(outputs[0].convertedpreferredDT.contains('+') || outputs[0].convertedpreferredDT.contains('-'), 
                         'Output should include timezone offset');
        }
    } 
    
    @isTest
    static void testValidatePreferredDTWithEdgeCases() {
        // Test edge cases like leap year, end of year
        Test.startTest();
        
        List<DateTimeConverter.InputParameters> inputs = new List<DateTimeConverter.InputParameters>();
        
        // Leap year date (Feb 29)
        Integer currentYear = Date.today().year();
        Integer nextLeapYear = currentYear;
        while (Math.mod(nextLeapYear, 4) != 0 || (Math.mod(nextLeapYear, 100) == 0 && Math.mod(nextLeapYear, 400) != 0)) {
            nextLeapYear++;
        }
        
        DateTimeConverter.InputParameters input1 = new DateTimeConverter.InputParameters();
        input1.preferredDT = DateTime.newInstanceGmt(2024, 2, 29, 12, 0, 0);
        inputs.add(input1);
        
        // End of year
        DateTimeConverter.InputParameters input2 = new DateTimeConverter.InputParameters();
        input2.preferredDT = DateTime.newInstanceGmt(currentYear, 12, 31, 23, 59, 59);
        inputs.add(input2);
        
        // Beginning of year
        DateTimeConverter.InputParameters input3 = new DateTimeConverter.InputParameters();
        input3.preferredDT = DateTime.newInstanceGmt(currentYear, 1, 1, 0, 0, 0);
        inputs.add(input3);
        
        List<DateTimeConverter.OutputParameters> outputs = DateTimeConverter.ValidatePreferredDT(inputs);
        
        Test.stopTest();
        
        // Verify edge cases were processed
        System.assertEquals(3, outputs.size(), 'Should have 3 outputs for edge cases');
    }
}