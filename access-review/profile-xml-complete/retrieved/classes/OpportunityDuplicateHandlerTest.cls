@isTest
public class OpportunityDuplicateHandlerTest {

    @isTest
    static void testDuplicateOpportunityDetection() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create an existing Opportunity (converted from Lead)
        
      
        Opportunity existingOpp = new Opportunity(
            Name = 'Existing Opportunity',
            AccountId = acc.Id,
             Total_Roaming_Forecast_QC__c=100.00,
            StageName = 'Validate the Opportunity',
            CloseDate = Date.today().addDays(30),
            Business_Unit__c = 'Risk;Roaming',
            Converted_from_Lead__c = true,
            Forecasted_ACV_Amount_QC__c=10,
            Cross_sell1__c='Cross sell',
            Current_Quarter_Billing__c=100,
            Risk_Products__c='RAID Data Fraud'
           // Roaming_and_Network_Products__c='RoamFilter'
        );
        insert existingOpp;

        // Create a new Opportunity with overlapping BU
        Opportunity newOpp = new Opportunity(
            Name = 'New Opportunity',
            AccountId = acc.Id,
             Total_Roaming_Forecast_QC__c=100.00,
            StageName = 'Validate the Opportunity',
            CloseDate = Date.today().addDays(40),
            Current_Quarter_Billing__c=10,
            Forecasted_ACV_Amount_QC__c=10,
            Cross_sell1__c='Cross sell',
            Business_Unit__c = 'Risk;Roaming',
            Risk_Products__c='RAID Data Fraud'
           // Roaming_and_Network_Products__c='RoamFilter'
        );
        insert newOpp;

        // Run the method and check email invocation
        Test.startTest();
        OpportunityDuplicateHandler.checkDuplicates(new List<Opportunity>{ newOpp });
        OpportunityDuplicateHandler.sendDuplicateEmail(newOpp,existingOpp,new Set<String>{'Risk', 'Roaming'});
        Test.stopTest();

       // System.assertEquals(1, Limits.getEmailInvocations(), 'Expected one email to be sent.');
    }

    @isTest
    static void testNoDuplicateWhenBusinessUnitsDoNotOverlap() {
        // Create another Account
        Account acc = new Account(Name = 'No Duplicate Account');
        insert acc;

        // Create an old Opportunity with no BU overlap
        Opportunity existingOpp = new Opportunity(
            Name = 'Old Opportunity',
            AccountId = acc.Id,
            Total_Roaming_Forecast_QC__c=100.00,
            StageName = 'Validate the Opportunity',
            CloseDate = Date.today().addDays(10),
            Current_Quarter_Billing__c=100,
            Forecasted_ACV_Amount_QC__c=10,
            Cross_sell1__c='Cross sell',
            Business_Unit__c = 'Security',
            Security_Products__c='URL scanner',
            Converted_from_Lead__c = true
        );
        insert existingOpp;

        // Create a new Opportunity with different BUs
        Opportunity newOpp = new Opportunity(
            Name = 'Another New Opportunity',
            AccountId = acc.Id,
            Total_Roaming_Forecast_QC__c=100.00,
            StageName = 'Validate the Opportunity',
            CloseDate = Date.today().addDays(15),
            Current_Quarter_Billing__c=100,
            Cross_sell1__c='Cross sell',
            Forecasted_ACV_Amount_QC__c=10,
            Business_Unit__c = 'Risk;Roaming',
            Risk_Products__c='RAID Data Fraud',
            Roaming_and_Network_Products__c='RoamFilter'
        );
        insert newOpp;

        // Run the duplicate check
        Test.startTest();
        OpportunityDuplicateHandler.checkDuplicates(new List<Opportunity>{ newOpp });
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(), 'Expected no email to be sent.');
    }
}