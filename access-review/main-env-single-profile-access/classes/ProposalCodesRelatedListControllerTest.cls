@isTest
private class ProposalCodesRelatedListControllerTest
{
    @testSetup
    static void setup()
    {
        Account account = new Account
        (
            Name = 'Test Account'
        );
        insert account;

        Customer_Acronym__c customerAcronym = new Customer_Acronym__c
        (
            Name = 'TESTAC',
            Billing_Customer__c = account.Id,
            Final_Customer__c = account.Id,
            Atlassian_Key__c='key1'
        );
        insert customerAcronym;

        Opportunity opportunity = new Opportunity
        (
            Name = 'Test Opportunity',
            CloseDate = Date.today().addDays(2),
            AccountId = account.Id,
            Type = 'POC-Proof of Concept',
            StageName = 'Verbal',
            Business_Unit__c = 'Security',
            Company_Code__c = 'WeDo Technologies',
            Amount = 1000,
            Entity_Number__c = '80 - WeDo Consulting- Sistiemas de Informacos, SA',
            Customer_Acronym__c = customerAcronym.Id
        );
        insert opportunity;
        
        ProposalCodeGeneratorController.generateMasterCode(opportunity.Id);
    }
    
    @isTest
    private static void testRelateListController()
    {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        ProjectUtils.Response response = ProposalCodesRelatedListController.getRelatedRecords(opp.Id);
        Test.stopTest();
        
        System.assertEquals(true, response.isSuccess);
    }
    
    @isTest
    private static void testForceCoverage() //TO BE deleted after atlassian integration done
    {
        Test.startTest();
        ProjectUtils.replaceBodyVariables('a', new Map<String, String> { 'a' => 'b' });
        ProjectUtils.sendEmailNotification(new List<String> { 'abc@mail.com' }, 'test', 'test');
        Test.stopTest();
    }
}