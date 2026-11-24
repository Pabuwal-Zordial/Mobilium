@isTest
private class ProposalCodeTriggerHandlerTest
{
    @testSetup
    private static void setup()
    {
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;

        Customer_Acronym__c customerAcronym = new Customer_Acronym__c(
            Name = 'TESTCA',
            Final_Customer__c = account.Id,
            Atlassian_Key__c='key1'
        );
        insert customerAcronym;

        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Pipeline',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id,
            Customer_Acronym__c = customerAcronym.Id,
            Entity_Number__c = '11 - Roamware, Inc. - US',
            Type = 'POC-Proof of Concept',
            Business_Unit__c = 'Roaming'
        );
        insert opportunity;

        ProposalCodeGeneratorController.generateMasterCode(opportunity.Id);
    }

    @isTest
    private static void testAfterDelete()
    {
        Opportunity opportunityBefore = [SELECT Id, Project_Code__c FROM Opportunity LIMIT 1];
        Proposal_Code__c proposalCode = [SELECT Id FROM Proposal_Code__c LIMIT 1];

        Test.startTest();
        delete proposalCode;
        Test.stopTest();

        Opportunity opportunityAfter = [SELECT Id, Project_Code__c FROM Opportunity LIMIT 1];

        System.assertEquals(true, String.isNotBlank(opportunityBefore.Project_Code__c));
        System.assertEquals(true, String.isBlank(opportunityAfter.Project_Code__c));
    }
}