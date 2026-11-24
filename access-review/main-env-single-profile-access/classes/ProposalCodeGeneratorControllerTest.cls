@isTest
private class ProposalCodeGeneratorControllerTest
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
            Total_Security_Forecast_QC__c = 1000, 
            Customer_Acronym__c = customerAcronym.Id
        );
        insert opportunity;
    }

    static testMethod void itShouldRetrieveInitialData()
    {
        Opportunity opportunity = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        ProjectUtils.Response response = ProposalCodeGeneratorController.initData(opportunity.Id);
        Test.stopTest();

        Map<String, Object> result = (Map<String, Object>) response.value;

        System.assertEquals(true, response.isSuccess);
        System.assertEquals(true, Boolean.valueOf(result.get('isMasterCode')));
        System.assertEquals('POC-Proof of Concept', String.valueOf(result.get('opportunityType')));
    }

    static testMethod void itShouldCreateProjectMasterCode()
    {
        Opportunity opportunity = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        ProjectUtils.Response response = ProposalCodeGeneratorController.generateMasterCode(opportunity.Id);
        Test.stopTest();

        Proposal_Code__c projectCode = [SELECT Id, Name, Opportunity__c, Is_Master_Code__c FROM Proposal_Code__c][0];

        System.assertEquals(true, response.isSuccess);
        System.assertEquals('80TESTAC.01.001', projectCode.Name);
        System.assertEquals(opportunity.Id, projectCode.Opportunity__c);
        System.assertEquals(true, projectCode.Is_Master_Code__c);
    }

    static testMethod void itShouldCreateProjectExtensionCode()
    {
        Opportunity opportunity = [SELECT Id FROM Opportunity][0];
        Test.startTest();
        ProjectUtils.Response response = ProposalCodeGeneratorController.generateMasterCode(opportunity.Id);
        response = ProposalCodeGeneratorController.generateExtensionCode(opportunity.Id, 'POC-Proof of Concept');
        Test.stopTest();

        Proposal_Code__c projectCode = [SELECT Id, Name, Opportunity__c, Is_Master_Code__c FROM Proposal_Code__c WHERE Is_Master_Code__c = false][0];

        System.assertEquals(true, response.isSuccess);
        System.assertEquals('80TESTAC.01.002', projectCode.Name);
        System.assertEquals(opportunity.Id, projectCode.Opportunity__c);
        System.assertEquals(false, projectCode.Is_Master_Code__c);
    }
}