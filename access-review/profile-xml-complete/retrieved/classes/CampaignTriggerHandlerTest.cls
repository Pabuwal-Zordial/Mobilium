@isTest
public class CampaignTriggerHandlerTest {
    @isTest
    static void setCampaignMemberStatusPerTypeTest() {
		// TODO fix this test class (weird duplicate error only on test class...)
        Campaign c = new Campaign(Name = 'Test', StartDate = System.today(), EndDate = System.today(), Type = null);
        
        Test.startTest();
        insert c;
        update c;
		Map<String, List<CampaignMemberStatus>> l = CampaignTriggerHandler.setStatusPerTypeMap();
        Test.stopTest();
    } 
}