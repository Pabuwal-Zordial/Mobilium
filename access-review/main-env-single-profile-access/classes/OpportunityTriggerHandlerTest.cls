@isTest
private class OpportunityTriggerHandlerTest {
    @testSetup
    static void setup() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Currency_Table__c currencyUSD = new Currency_Table__c(Name = 'USD', Conversion_Rate__c = 1);
        insert currencyUSD;

        Customer_Acronym__c customerAcronym = new Customer_Acronym__c(Name = 'TESTCA', Final_Customer__c = account.Id, Atlassian_Key__c = 'key1');
        insert customerAcronym;

        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Validate the Opportunity',
            Forecast_Category__c = 'Pipeline',
            CloseDate = Date.today().addDays(10),
            Current_Quarter_Billing__c = 0,
            Currency_Table__c = currencyUSD.id,
            AccountId = account.Id,
            Customer_Acronym__c = customerAcronym.Id,
            Entity_Number__c = entityNumberStartingWith('11'),
            Cross_sell1__c = 'New Logo',
            OLD_Accepted_By__c = 'test',
            Probability = 0,
            Risk_Products__c = 'RAID 8 - Platform',
            Forecasted_ACV_Amount_QC__c = 33,
            Total_Roaming_Forecast_QC__c = 10000,
            Total_Security_Forecast_QC__c = 5000,
            Total_Test_Factory_Forecast_QC__c = 2000,
            Total_Testing_Amount_QC__c = 1500,
            Total_Engagement_Experience_Amount_QC__c = 3000,
            Type = 'POC-Proof of Concept',
            Business_Unit__c = 'Risk',
            Fraud_Management_Booking_Value_QC__c = 1
        );
        insert opportunity;
    }

    // Entity_Number__c is a restricted picklist whose active values differ between orgs
    // (sandbox vs production use entirely different entity labels). Assertions in this class
    // only depend on the 2-character numeric prefix ("11", "13"), so look up whichever active
    // value carries that prefix in the org the test is actually running in.
    private static String entityNumberStartingWith(String prefix) {
        for (Schema.PicklistEntry entry : Opportunity.Entity_Number__c.getDescribe().getPicklistValues()) {
            if (entry.isActive() && entry.getValue().startsWith(prefix)) {
                return entry.getValue();
            }
        }
        return null;
    }

    @isTest
    private static void testBeforeInsert() {
        Opportunity parentOpportunity = [SELECT Id, AccountId, Customer_Acronym__c FROM Opportunity];
        Currency_Table__c currencyUSD = [SELECT ID FROM Currency_Table__c LIMIT 1];

        Test.startTest();
        Opportunity opportunity = new Opportunity(
            Name = 'Test Child Opportunity',
            StageName = 'Validate the Opportunity',
            Forecast_Category__c = 'Pipeline',
            OLD_Accepted_By__c = 'test',
            CloseDate = Date.today().addDays(10),
            Risk_Products__c = 'RAID 8 - Platform',
            Current_Quarter_Billing__c = 0,
            Currency_Table__c = currencyUSD.id,
            Cross_sell1__c = 'New Logo',
            Forecasted_ACV_Amount_QC__c = 33,
            Total_Roaming_Forecast_QC__c = 10000,
            Total_Security_Forecast_QC__c = 5000,
            Total_Test_Factory_Forecast_QC__c = 2000,
            Total_Testing_Amount_QC__c = 1500,
            Total_Engagement_Experience_Amount_QC__c = 3000,
            AccountId = parentOpportunity.AccountId,
            Parent_Opportunity__c = parentOpportunity.Id,
            Business_Unit__c = 'Risk',
            Fraud_Management_Booking_Value_QC__c = 1
        );
        insert opportunity;
        Test.stopTest();

        opportunity = [SELECT Id, AccountId, Customer_Acronym__c FROM Opportunity WHERE Id = :opportunity.Id];
        System.assertEquals(parentOpportunity.Customer_Acronym__c, opportunity.Customer_Acronym__c);
    }

    @isTest
    private static void testBeforeUpdate() {
        Opportunity opportunity = [SELECT Id, AccountId, Customer_Acronym__c FROM Opportunity];
        ProjectUtils.Response response = ProposalCodeGeneratorController.generateMasterCode(opportunity.Id);

        DmlException ex;
        Test.startTest();
        try {
            opportunity.Customer_Acronym__c = null;
            update opportunity;
        } catch (Exception e) {
            ex = (DmlException) e;
        }
        Test.stopTest();

        System.assertEquals(true, response.isSuccess, 'Failed to create Proposal Code');
        System.assertEquals(true, ex <> null, 'Failed to throw exception');
        System.assertEquals('Cannot change customer acronym on opportunities with related proposal codes.', ex.getDmlMessage(0));
    }

    @isTest
    private static void testAfterUpdate() {
        Opportunity opportunity = [SELECT Id, AccountId, Customer_Acronym__c FROM Opportunity];
        ProjectUtils.Response response = ProposalCodeGeneratorController.generateMasterCode(opportunity.Id);

        Test.startTest();
        opportunity.Entity_Number__c = entityNumberStartingWith('13');
        update opportunity;
        Test.stopTest();

        opportunity = [SELECT Id, AccountId, Customer_Acronym__c, Project_Code__c FROM Opportunity];
        Proposal_Code__c proposalCode = [SELECT Name FROM Proposal_Code__c];

        System.assertEquals('11TESTCA.01.001', String.valueOf(response.value));
        System.assertEquals('13TESTCA.01.001', opportunity.Project_Code__c);
        System.assertEquals('13TESTCA.01.001', proposalCode.Name);
    }
}