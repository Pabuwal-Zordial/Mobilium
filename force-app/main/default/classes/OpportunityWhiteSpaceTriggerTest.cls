@isTest
private class OpportunityWhiteSpaceTriggerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Trigger Account');
        insert acc;

        Offering__c off = new Offering__c(
            Name = 'Network Analytics Test',
            Offering_Code__c = 'OFF-NET-TEST',
            Product_Family__c = 'Network',
            Sort_Order__c = 1,
            Active__c = true
        );
        insert off;

        Account_Plan__c plan = new Account_Plan__c(
            Account__c = acc.Id,
            Fiscal_Year__c = 'FY2027',
            Plan_Key__c = acc.Id + '_FY2027',
            Status__c = 'Active'
        );
        insert plan;
    }

    @isTest
    static void testOpportunityUpdateToClosedWon() {
        White_Space_Assessment__c wsa = [
            SELECT Id, Account_Plan__r.Account__c, Account_Plan__c, Our_Spending__c, Competitor_Spending__c, Internal_Spending__c
            FROM White_Space_Assessment__c
            WHERE Offering__r.Offering_Code__c = 'OFF-NET-TEST'
            LIMIT 1
        ];

        // Set baseline spends
        wsa.Our_Spending__c = 5000;
        wsa.Competitor_Spending__c = 10000;
        wsa.Internal_Spending__c = 50000;
        wsa.Unknown_Spending__c = 5000;
        update wsa;

        // Create open opportunity
        Opportunity opp = new Opportunity(
            AccountId = wsa.Account_Plan__r.Account__c,
            Account_Plan__c = wsa.Account_Plan__c,
            White_Space_Assessment__c = wsa.Id,
            Name = 'Test Expansion Opp',
            Amount = 25000,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting'
        );
        insert opp;

        Test.startTest();
        // Update to Closed Won
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        White_Space_Assessment__c updatedWsa = [
            SELECT Id, Our_Spending__c, Competitor_Spending__c, Internal_Spending__c, Unknown_Spending__c, Comments__c
            FROM White_Space_Assessment__c
            WHERE Id = :wsa.Id
        ];

        System.assertEquals(30000, updatedWsa.Our_Spending__c, 'Our spend should increase by won amount');
        System.assertEquals(0, updatedWsa.Competitor_Spending__c, 'Competitor spend should be fully absorbed');
        System.assertEquals(35000, updatedWsa.Internal_Spending__c, 'Internal DIY spend should absorb remaining amount');
        System.assert(updatedWsa.Comments__c.contains('Won Deal'), 'Comments should contain win note');
    }

    @isTest
    static void testOpportunityInsertAsClosedWon() {
        White_Space_Assessment__c wsa = [
            SELECT Id, Account_Plan__r.Account__c, Account_Plan__c, Our_Spending__c, Competitor_Spending__c, Internal_Spending__c
            FROM White_Space_Assessment__c
            WHERE Offering__r.Offering_Code__c = 'OFF-NET-TEST'
            LIMIT 1
        ];

        wsa.Our_Spending__c = 5000;
        wsa.Competitor_Spending__c = 20000;
        update wsa;

        Test.startTest();
        Opportunity opp = new Opportunity(
            AccountId = wsa.Account_Plan__r.Account__c,
            Account_Plan__c = wsa.Account_Plan__c,
            White_Space_Assessment__c = wsa.Id,
            Name = 'Direct Won Opp',
            Amount = 15000,
            CloseDate = Date.today(),
            StageName = 'Closed Won'
        );
        insert opp;
        Test.stopTest();

        White_Space_Assessment__c updatedWsa = [
            SELECT Id, Our_Spending__c, Competitor_Spending__c, Internal_Spending__c
            FROM White_Space_Assessment__c
            WHERE Id = :wsa.Id
        ];

        System.assertEquals(20000, updatedWsa.Our_Spending__c, 'Our spend should increase by 15,000');
        System.assertEquals(5000, updatedWsa.Competitor_Spending__c, 'Competitor spend should decrease by 15,000');
    }

    @isTest
    static void testDirectOpportunityAutoLinking() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Trigger Account' LIMIT 1];
        White_Space_Assessment__c wsa = [
            SELECT Id, Account_Plan__c 
            FROM White_Space_Assessment__c 
            WHERE Offering__r.Offering_Code__c = 'OFF-NET-TEST' 
            LIMIT 1
        ];

        Test.startTest();
        // Insert with only AccountId and CloseDate (FY2027) and Name matching 'network'
        Opportunity directOpp = new Opportunity(
            AccountId = acc.Id,
            Name = 'Direct Technica Network Deal',
            Amount = 50000,
            CloseDate = Date.newInstance(2027, 6, 15),
            StageName = 'Prospecting'
        );
        insert directOpp;
        Test.stopTest();

        Opportunity queriedOpp = [
            SELECT Id, Account_Plan__c, White_Space_Assessment__c 
            FROM Opportunity 
            WHERE Id = :directOpp.Id
        ];

        System.assertNotEquals(null, queriedOpp.Account_Plan__c, 'Account Plan should auto-link based on FY2027 close date');
        System.assertEquals(wsa.Id, queriedOpp.White_Space_Assessment__c, 'Assessment should auto-link based on offering keyword');
    }
}
