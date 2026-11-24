@isTest
private class TestUpdateCommissionTypeFromChild {
    
    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
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
        
        insert opp;

        // Create an Opportunity Team Member (to check team member update)
      /*  OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'General Manager'
        );
        insert teamMember;*/
    }
    
    @isTest
    static void testInsertTrigger() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Insert child Commission_Type_Details__c to trigger the logic
        Commission_Type_Details__c ctd = new Commission_Type_Details__c(
            Opportunity__c = opp.Id,
            CCS__c=3,
            Net_90_or_better__c=true,
            X30_upfront__c=true
            //Commission_Type__c = 'Standard'
        );
        insert ctd;

        // Verify that Opportunity got updated
       // opp = [SELECT Commission_Type__c FROM Opportunity WHERE Id = :opp.Id];
      //  System.assertEquals('Category A Non-Renewal', opp.Commission_Type__c, 'Opportunity should be updated with Commission Type');

        // Verify that team member got updated
      /*  OpportunityTeamMember teamMember = [
            SELECT Commission_Type__c FROM OpportunityTeamMember 
            WHERE OpportunityId = :opp.Id LIMIT 1
        ];
        System.assertEquals('Standard', teamMember.Commission_Type__c, 'Team member should also get Commission Type');*/
    }
    
    @isTest
    static void testUpdateTrigger() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create Commission_Type_Details__c record
        Commission_Type_Details__c ctd = new Commission_Type_Details__c(
            Opportunity__c = opp.Id,
            CCS__c=1,
            Net_90_or_better__c=true,
            X30_upfront__c=true
        );
        insert ctd;
		
        Test.startTest();
        // Update the Commission_Type__c to trigger update logic
        ctd.CCS__c= 5;
        update ctd;
        Test.stopTest(); 
        
        // Verify that Opportunity got updated with new value
       // opp = [SELECT Commission_Type__c FROM Opportunity WHERE Id = :opp.Id];
       // System.assertEquals('Category A Non-Renewal', opp.Commission_Type__c, 'Opportunity should be updated with new Commission Type');

        // Verify that team member got updated with new value
       /* OpportunityTeamMember teamMember = [
            SELECT Commission_Type__c FROM OpportunityTeamMember 
            WHERE OpportunityId = :opp.Id LIMIT 1
        ];
        System.assertEquals('Premium', teamMember.Commission_Type__c, 'Team member should also get new Commission Type');*/
    }
}