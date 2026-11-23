@isTest
public class ItemsToApproveControllerTest {

	@testSetup
	static void setupData() {
		Account account = new Account(Name = 'Test Account');
		insert account;

		Opportunity opportunity = new Opportunity();
		opportunity.AccountId = account.Id;
		opportunity.Name = 'Test opportunity';
		opportunity.StageName ='Proposal';
		opportunity.CloseDate = System.today();
		opportunity.Probability_to_Close_Picklist__c = '0%';
		opportunity.Type = 'TL-Term License';
		opportunity.Amount = 0.00;
		opportunity.Company_Code__c = 'Mobileum Inc.';
		opportunity.Business_Unit__c = 'Roaming';
		insert opportunity;

		Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		app.setComments('Submitting');
		app.setProcessDefinitionNameOrId('Non_Standard_Approval');
		app.setObjectId(opportunity.Id);
		app.setNextApproverIds(new List<Id>{UserInfo.getUserId()});
		app.setSkipEntryCriteria(true);
		Approval.ProcessResult result = Approval.process(app);
	}

	@isTest
	public static void getPendingForApprovalRecordsTest(){
		Test.startTest();
			List<ItemsToApproveController.PedingForApprovalRecordWrapper> result = ItemsToApproveController.getPendingForApprovalRecords('Opportunity', new List<String> {'Company_Code__c'}, 'Name');
		Test.stopTest();

		System.assertEquals(1, result.size());
		System.assert(result[0].relatedToObjectFieldsData.containsKey('Company_Code__c'));
		System.assertEquals(result[0].relatedToObjectFieldsData.get('Company_Code__c'), 'Mobileum Inc.');
	}

	@isTest
	public static void processRecordsRejectTest(){
		Test.startTest();
			List<ItemsToApproveController.PedingForApprovalRecordWrapper> result = ItemsToApproveController.getPendingForApprovalRecords('Opportunity', null, 'Name');
			ItemsToApproveController.WorkItemAction workItemAction = new ItemsToApproveController.WorkItemAction();
			workItemAction.workItemId = result[0].workItemId;
			workItemAction.comments = 'Test Reject Comment';
			workItemAction.type = 'Reject';
			
			ItemsToApproveController.processRecords(new List<ItemsToApproveController.WorkItemAction> { workItemAction });
		Test.stopTest();

		List<ProcessInstance> processInstances = [SELECT Id, Status, (SELECT Id, StepStatus, Comments FROM Steps WHERE StepStatus = 'Rejected')
													FROM ProcessInstance
													WHERE TargetObjectId = :result[0].recordId];

		System.assertEquals(1, processInstances.size());
		System.assertEquals('Rejected', processInstances[0].Status);
		System.assertEquals(1, processInstances[0].steps.size());
		System.assertEquals('Test Reject Comment', processInstances[0].steps[0].Comments);
	}

	@isTest
	public static void processRecordsApproveTest(){
		Test.startTest();
			List<ItemsToApproveController.PedingForApprovalRecordWrapper> result = ItemsToApproveController.getPendingForApprovalRecords('Opportunity', null, 'Name');
			ItemsToApproveController.WorkItemAction workItemAction = new ItemsToApproveController.WorkItemAction();
			workItemAction.workItemId = result[0].workItemId;
			workItemAction.comments = 'Test Approve Comment';
			workItemAction.type = 'Approve';
			
			ItemsToApproveController.processRecords(new List<ItemsToApproveController.WorkItemAction> { workItemAction });
		Test.stopTest();

		List<ProcessInstance> processInstances = [SELECT Id, Status, (SELECT Id, StepStatus, Comments FROM Steps WHERE StepStatus = 'Approved')
													FROM ProcessInstance
													WHERE TargetObjectId = :result[0].recordId];

		System.assertEquals(1, processInstances.size());
		System.assertEquals('Approved', processInstances[0].Status);
		System.assertEquals(1, processInstances[0].steps.size());
		System.assertEquals('Test Approve Comment', processInstances[0].steps[0].Comments);
	}
}