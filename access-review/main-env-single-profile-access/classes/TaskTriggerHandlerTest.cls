@isTest
public class TaskTriggerHandlerTest {
    @isTest
    static void alignRecordTypeTest_Insert() {
        Lead l = new Lead(LastName = 'Test', Company = 'Test');
        insert l;
        Account a = new Account(Name= 'Test', Country__c= 'a1641000001US67AAG',Relationship_Type__c='Analyst' , Industry='Finance', Website='www.finance.com');
        insert a;
        Task t = new Task(Subject = 'Test', WhoId = l.Id, Type = 'Email');
        Task t1 = new Task(Subject = 'Tes1t', WhatId = a.Id, Type = 'Email');
        Test.startTest();
        insert t;
        insert t1;
        Test.stopTest();
        
        Task tDB = [SELECT Id, RecordTypeId FROM Task WHERE Id = :t.Id];
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Email'];
        
        System.assertEquals(rt.Id, tDB.RecordTypeId);
    }
    
    @isTest
    static void alignRecordTypeTest_Update() {
        Lead l = new Lead(LastName = 'Test', Company = 'Test');
        insert l;
        Account a = new Account(Name= 'Test', Country__c= 'a1641000001US67AAG',Relationship_Type__c='Analyst' , Industry='Finance', Website='www.finance.com');
        insert a;
        Task t = new Task(Subject = 'Test', WhoId = l.Id, Type = 'Email');
        insert t;
        Task t1 = new Task(Subject = 'Test1', WhatId = a.Id, Type = 'Email');
        insert t1;
        
        Test.startTest();
        t.Type = 'Call';
        update t;
        t1.Type = 'Call';
        update t1;
        Test.stopTest();
        
        Task tDB = [SELECT Id, RecordTypeId FROM Task WHERE Id = :t.Id];
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Call'];
        
        System.assertEquals(rt.Id, tDB.RecordTypeId);
    }
    
    @isTest
    static void updateHubspotTaskTest() {
        Campaign c = new Campaign(Name = 'Test', StartDate = System.today(), EndDate = System.today(), Type = null);
        insert c;
        Lead l = new Lead(LastName = 'Test', Company = 'Test');
        insert l;
        Task t = new Task(Subject = 'Test', WhoId = l.Id, Type = 'Website');
        
        Test.startTest();
        t.Description = 'Company: Mobileum\r\nCountry: Portugal\r\nDepartment: Department\r\nEmail: email@email.email\r\nsfCampaignId: '+c.Id+'\r\n'+'Landing Page Name: Test\r\nLandingPageUrl: https://test.test\r\n';
        insert t;
        Test.stopTest();
        
        Task tDB = [SELECT Id, Subject, OwnerId, Landing_Page_Name__c, Landing_Page_Url__c, Email_Provided__c, Company__c, Department__c, Country__c FROM Task WHERE Id = :t.Id];
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Inside_Sales'].Id;
        
        System.assertEquals(queueId, tDB.OwnerId);
        System.assertEquals('Test', tDB.Landing_Page_Name__c);
        System.assertEquals('https://test.test', tDB.Landing_Page_Url__c);
        System.assertEquals('Test [Test]', tDB.Subject);
        System.assertEquals('email@email.email', tDB.Email_Provided__c);
        System.assertEquals('Mobileum', tDB.Company__c);
        System.assertEquals('Department', tDB.Department__c);
        System.assertEquals('Portugal', tDB.Country__c);
    }
}