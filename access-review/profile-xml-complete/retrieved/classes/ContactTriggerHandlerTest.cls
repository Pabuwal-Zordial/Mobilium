@isTest
public class ContactTriggerHandlerTest {
    @isTest
    static void updateURLFieldsTest_Insert() {
        Account a = new Account(Name = 'Test');
        insert a;
        Contact c = new Contact(LastName = 'Test', AccountId = a.Id);

        Test.startTest();
        c.Hubspot_Last_Referring_Website_Long__c = 'https://www.google.com?test=test';
        c.Hubspot_Last_Webpage_Seen_Long__c = 'https://www.google.com?test=test';
        insert c;
        Test.stopTest();
        
        Contact cDB = [SELECT Id, Hubspot_Last_Referring_Website__c, Hubspot_Last_Webpage_Seen__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('https://www.google.com', cDB.Hubspot_Last_Referring_Website__c);
        System.assertEquals('https://www.google.com', cDB.Hubspot_Last_Webpage_Seen__c);
    } 
    
    @isTest
    static void updateURLFieldsTest_Update() {
        Account a = new Account(Name = 'Test');
        insert a;
        Contact c = new Contact(LastName = 'Test', AccountId = a.Id);
		insert c;
        
        Test.startTest();
        c.Hubspot_Last_Referring_Website_Long__c = 'https://www.google.com?test=test';
        c.Hubspot_Last_Webpage_Seen_Long__c = 'https://www.google.com?test=test';
        update c;
        Test.stopTest();
        
        Contact cDB = [SELECT Id, Hubspot_Last_Referring_Website__c, Hubspot_Last_Webpage_Seen__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('https://www.google.com', cDB.Hubspot_Last_Referring_Website__c);
        System.assertEquals('https://www.google.com', cDB.Hubspot_Last_Webpage_Seen__c);
    } 
}