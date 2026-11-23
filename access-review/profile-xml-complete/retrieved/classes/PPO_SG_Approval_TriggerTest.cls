@IsTest
private class PPO_SG_Approval_TriggerTest {
    private static final String TEMPLATE_INITIAL = 'PPO_new_Process_Notification_template';

    @TestSetup
    static void setup() {
        EmailTemplate et = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = :TEMPLATE_INITIAL
            LIMIT 1
        ];

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Product2 product = new Product2(Name = 'UT Product ' + Crypto.getRandomInteger(), IsActive = true);
        insert product;

        Id stdPbId = Test.getStandardPricebookId();

        PricebookEntry stdPrice = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = product.Id, UnitPrice = 1000, IsActive = true, UseStandardPrice = false);
        insert stdPrice;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity ' + String.valueOf(Crypto.getRandomInteger()),
            StageName = 'Secure Agreement',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Forecast_Category__c = 'Pipeline',
            Current_Quarter_Billing__c = 0,
            Entity_Number__c = '11 - Roamware, Inc. - US',
            Cross_sell1__c = 'New Logo',
            OLD_Accepted_By__c = 'test',
            Probability = 0,
            Forecasted_ACV_Amount_QC__c = 33,
            Total_Roaming_Forecast_QC__c = 10000,
            Total_Security_Forecast_QC__c = 5000,
            Total_Test_Factory_Forecast_QC__c = 2000,
            Total_Testing_Amount_QC__c = 1500,
            Total_Engagement_Experience_Amount_QC__c = 3000,
            Type = 'POC-Proof of Concept',
            Business_Unit__c = 'RISK',
            Fraud_Management_Booking_Value_QC__c = 1,
            Delivery_Involved__c = 'No',
            Customer_Services_Involved__c = 'No',
            Managed_Services_Involved__c = 'Yes',
            Opportunity_Approval_Status__c = 'Approved - 2nd',
            Second_Approval_Status__c = 'Approved - 2nd',
            Risk_Products__c = Opportunity.Risk_Products__c.getDescribe().getPicklistValues()[0].getValue()
        );
        insert opp;

        opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opp.Id];

        if (opp.Pricebook2Id == null) {
            opp.Pricebook2Id = stdPbId;
            update opp;
            opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opp.Id];
        }

        Id pbeId;
        if (opp.Pricebook2Id == stdPbId) {
            pbeId = stdPrice.Id;
        } else {
            PricebookEntry customPbe = new PricebookEntry(
                Pricebook2Id = opp.Pricebook2Id,
                Product2Id = product.Id,
                UnitPrice = 1000,
                IsActive = true,
                UseStandardPrice = true
            );
            insert customPbe;
            pbeId = customPbe.Id;
        }

        insert new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbeId, Quantity = 1, UnitPrice = 1000);
    }

    @IsTest
    static void insert_should_cover_before_and_after_insert() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Opportunity %' LIMIT 1];

        PPO_Sales_Governance__c ppo = new PPO_Sales_Governance__c(Name = 'PPO Insert Test', Opportunity__c = opp.Id, PPO_Approval_Status__c = 'Not Submitted', PPO_Start_Date__c = System.today().addDays(1), PPO_End_Date__c = System.today().addDays(10), PO_target_date__c = System.today().addDays(10), Third_Party_Costs__c = 0, Costs_LoE__c = 0, PPO_Reason__c = 'Test reason', Written_confirmation_from_the_Customer__c = 'Yes');

        Test.startTest();
        insert ppo; // before insert + after insert (sendInitialEmail)
        Test.stopTest();

        System.assertNotEquals(null, ppo.Id, 'PPO should have been inserted.');
    }

    @IsTest
    static void update_should_cover_before_and_after_update() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Opportunity %' LIMIT 1];

        PPO_Sales_Governance__c ppo = new PPO_Sales_Governance__c(Name = 'PPO Update Test', Opportunity__c = opp.Id, PPO_Approval_Status__c = 'Not Submitted', PPO_Start_Date__c = System.today().addDays(1), PPO_End_Date__c = System.today().addDays(10), PO_target_date__c = System.today().addDays(10), Third_Party_Costs__c = 0, Costs_LoE__c = 0, PPO_Reason__c = 'Test reason', Written_confirmation_from_the_Customer__c = 'Yes');
        insert ppo;

        Test.startTest();
        update ppo; // before update + after update
        Test.stopTest();

        System.assertEquals('Test reason', ppo.PPO_Reason__c);
    }

    @IsTest
    static void update_written_confirmation_yes_to_no_with_file_should_block() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Opportunity %' LIMIT 1];

        PPO_Sales_Governance__c ppo = new PPO_Sales_Governance__c(Name = 'PPO File Block Test', Opportunity__c = opp.Id, PPO_Approval_Status__c = 'Not Submitted', PPO_Start_Date__c = System.today().addDays(1), PPO_End_Date__c = System.today().addDays(10), PO_target_date__c = System.today().addDays(10), Third_Party_Costs__c = 0, Costs_LoE__c = 0, PPO_Reason__c = 'Test reason', Written_confirmation_from_the_Customer__c = 'Yes');
        insert ppo;

        // Attach a file so updatePPOFields() blocks switching Yes -> No
        insert new ContentVersion(Title = 'PPO_Attachment', PathOnClient = 'PPO_Attachment.pdf', VersionData = Blob.valueOf('dummy'), FirstPublishLocationId = ppo.Id);

        Test.startTest();
        try {
            ppo.Written_confirmation_from_the_Customer__c = 'No';
            update ppo;
            System.assert(false, 'Expected DML to fail due to addError().');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You cannot change Written Confirmation from the Customer to'), 'Unexpected error: ' + e.getMessage());
        }
        Test.stopTest();
    }
}