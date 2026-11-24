@isTest
public class RestrictChangeAttachmentTestClass{

	@testSetup
	private static void setup()
	{
		User usr = new User(
			Id = UserInfo.getUserId()
		);
		update usr;

		Account account = new Account(
			Name = 'Test Account'
		);
		insert account;

		Customer_Acronym__c customerAcronym = new Customer_Acronym__c(
			Name = 'TESTCA',
			Atlassian_Key__c = 'TESTCA',
			Final_Customer__c = account.Id
		);
		insert customerAcronym;

		Opportunity opportunity = new Opportunity(
			Name = 'Test Opportunity',
			StageName = 'Pipeline',
			CloseDate = Date.today().addDays(10),
			AccountId = account.Id,
			Customer_Acronym__c = customerAcronym.Id,
			Entity_Number__c = '11 - Roamware, Inc. - US',
			Type = 'POC-Proof of Concept',
			Business_Unit__c = 'Security',
			Total_Security_Forecast_QC__c = 1000
		);
		insert opportunity;
	}

	static testmethod void unitTest1() 
	{
		Account acc = new Account();
		acc.Name = 'TestAcc';
		insert acc;

		Attachment attach = new Attachment();
		attach.Name = 'TestAttach';
		attach.Body = Blob.valueOf('TestAttach');
		attach.parentId = acc.Id;

		insert attach;
	}

	static testmethod void unitTest2() 
	{
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

		Attachment attach = new Attachment();
		attach.Name = 'TestAttach';
		attach.Body = Blob.valueOf('TestAttach');
		attach.parentId = opp.Id;

		insert attach;
		attach.Name = 'TestAttach1';
		update attach;
		delete attach;
	}
}