@isTest
public class CampaignMemberTriggerHandlerTest {
    @isTest
    static void updateRelatedCampaignFieldTest_LeadAdd() {
		Campaign c = new Campaign(Name = 'Test', StartDate = System.today(), EndDate = System.today(), Type = null);
        insert c;
        Lead l = new Lead(LastName = 'Test', Company = 'Test');
        insert l;
        
        Test.startTest();
        insert new CampaignMember(CampaignId = c.Id, LeadId = l.Id);
        Test.stopTest();

        Lead lDB = [SELECT Id, Campaign_Lead_Source__c FROM Lead WHERE Id = :l.Id];

        System.assertEquals(c.Id, lDB.Campaign_Lead_Source__c);
    } 
    
    @isTest
    static void updateRelatedCampaignFieldTest_LeadRemove() {
		Campaign c = new Campaign(Name = 'Test', StartDate = System.today(), EndDate = System.today(), Type = null);
        insert c;
        Lead l = new Lead(LastName = 'Test', Company = 'Test');
        insert l;
        CampaignMember cm = new CampaignMember(CampaignId = c.Id, LeadId = l.Id);
        insert cm;
        
        Test.startTest();
        delete cm;
        Test.stopTest();

        Lead lDB = [SELECT Id, Campaign_Lead_Source__c FROM Lead WHERE Id = :l.Id];

        System.assertEquals(null, lDB.Campaign_Lead_Source__c);
    } 
    
    @isTest
    static void updateRelatedCampaignFieldTest_ContactAdd() {
		Campaign c = new Campaign(Name = 'Test', StartDate = System.today(), EndDate = System.today(), Type = null);
        insert c;
        Account a = new Account(Name = 'Test');
        insert a;
        Contact co = new Contact(LastName = 'Test', AccountId = a.Id);
        insert co;
        
        Test.startTest();
        insert new CampaignMember(CampaignId = c.Id, ContactId = co.Id);
        Test.stopTest();

        Contact coDB = [SELECT Id, Campaign_Contact_Source__c FROM Contact WHERE Id = :co.Id];

        System.assertEquals(c.Id, coDB.Campaign_Contact_Source__c);
        
    } 
    
    @isTest
    static void updateRelatedCampaignFieldTest_ContactRemove() {
		Campaign c = new Campaign(Name = 'Test', StartDate = System.today(), EndDate = System.today(), Type = null);
        insert c;
        Account a = new Account(Name = 'Test');
        insert a;
        Contact co = new Contact(LastName = 'Test', AccountId = a.Id);
        insert co;
        CampaignMember cm = new CampaignMember(CampaignId = c.Id, ContactId = co.Id);
        insert cm;
        
        Test.startTest();
        delete cm;
        Test.stopTest();

        Contact coDB = [SELECT Id, Campaign_Contact_Source__c FROM Contact WHERE Id = :co.Id];

        System.assertEquals(null, coDB.Campaign_Contact_Source__c);
        
    } 
}