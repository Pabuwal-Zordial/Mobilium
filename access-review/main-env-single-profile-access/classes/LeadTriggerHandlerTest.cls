@isTest
public class LeadTriggerHandlerTest {
    @isTest
    static void updateURLFieldsTest_Insert() {
        Lead l = new Lead(LastName = 'Test', Company = 'Test');

        Test.startTest();
        l.Hubspot_Last_Referring_Website_Long__c = 'https://www.google.com?test=test';
        l.Hubspot_Last_Webpage_Seen_Long__c = 'https://www.google.com?test=test';
        insert l;
        Test.stopTest();
        
        Lead lDB = [SELECT Id, Hubspot_Last_Referring_Website__c, Hubspot_Last_Webpage_Seen__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals('https://www.google.com', lDB.Hubspot_Last_Referring_Website__c);
        System.assertEquals('https://www.google.com', lDB.Hubspot_Last_Webpage_Seen__c);
    } 
    
    @isTest
    static void updateURLFieldsTest_Update() {
        Lead l = new Lead(LastName = 'Test', Company = 'Test');
		insert l;
        
        Test.startTest();
        l.Hubspot_Last_Referring_Website_Long__c = 'https://www.google.com?test=test';
        l.Hubspot_Last_Webpage_Seen_Long__c = 'https://www.google.com?test=test';
        update l;
        Test.stopTest();
        
        Lead lDB = [SELECT Id, Hubspot_Last_Referring_Website__c, Hubspot_Last_Webpage_Seen__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals('https://www.google.com', lDB.Hubspot_Last_Referring_Website__c);
        System.assertEquals('https://www.google.com', lDB.Hubspot_Last_Webpage_Seen__c);
    } 
}