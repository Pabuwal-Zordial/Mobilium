@isTest
public class OpportunitySplitTriggerHandlerTest {

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
	}

	@isTest
	static void deleteExtraOpportunityOwnersTeamMembersTest() {
		Opportunity opportunity = [SELECT Id
									FROM Opportunity
									LIMIT 1];

		System.assertEquals(1, [SELECT Id
								FROM OpportunityTeamMember
								WHERE OpportunityId = :opportunity.Id].size());

		Test.startTest();

		OpportunitySplitTriggerHandler.isTriggerDisabled = true;
		opportunity.ownerId = [SELECT Id
								FROM User
								WHERE isActive = true
								AND Profile.Name = 'System Administrator'
								LIMIT 1][0].Id;
		update opportunity;
		OpportunitySplitTriggerHandler.isTriggerDisabled = false;

		System.assertEquals(2, [SELECT Id
								FROM OpportunityTeamMember
								WHERE OpportunityId = :opportunity.Id].size());

		opportunity.ownerId = [SELECT Id
								FROM User
								WHERE isActive = true
								AND Profile.Name = 'System Administrator'
								AND Id != :opportunity.OwnerId
								LIMIT 1][0].Id;
		update opportunity;

		Test.stopTest();

		System.assertEquals(1, [SELECT Id
								FROM OpportunityTeamMember
								WHERE OpportunityId = :opportunity.Id].size());

	}

	@isTest
	static void deleteOpportunitySplitForOldOwnerOnClosedOpportunitiesTest() {
		Opportunity opportunity = [SELECT Id
									FROM Opportunity
									LIMIT 1];

		opportunity.StageName = 'Won';
		update opportunity;

		opportunity = [SELECT Id
						FROM Opportunity
						WHERE Id = :opportunity.Id
						AND isClosed = true
						LIMIT 1];

		System.assertEquals(1, [SELECT Id
								FROM OpportunitySplit
								WHERE OpportunityId = :opportunity.Id].size());

		Test.startTest();

		Id newOwnerId = [SELECT Id
							FROM User
							WHERE isActive = true
							AND Profile.Name = 'System Administrator'
							LIMIT 1][0].Id;
		
		opportunity.ownerId = newOwnerId;
		update opportunity;

		Test.stopTest();

		List<OpportunitySplit> newOpportunitySplits = [SELECT Id, SplitOwnerId, Opportunity.OwnerId, SplitPercentage, SplitType.DeveloperName
														FROM OpportunitySplit
														WHERE OpportunityId = :opportunity.Id];

		System.assertEquals(1, newOpportunitySplits.size());
		System.assertEquals(newOpportunitySplits[0].SplitOwnerId, newOwnerId);
		System.assertEquals(newOpportunitySplits[0].Opportunity.OwnerId, newOwnerId);
		System.assertEquals(newOpportunitySplits[0].SplitPercentage, 100);
		System.assertEquals(newOpportunitySplits[0].SplitType.DeveloperName, OpportunitySplitTriggerHandler.SPLIT_TYPE_REVENUE);

		List<OpportunityTeamMember> opportunityTeamMembers = [SELECT Id, TeamMemberRole, UserId
																FROM OpportunityTeamMember
																WHERE OpportunityId = :opportunity.Id];
		
		System.assertEquals(1, opportunityTeamMembers.size());
		System.assertEquals(opportunityTeamMembers[0].UserId, newOwnerId);
		System.assertEquals(opportunityTeamMembers[0].TeamMemberRole, 'Opportunity Owner');
	}

	@isTest
	static void updateSplitOfPreviousOwnerToOverlay() {
		Opportunity opportunity = [SELECT Id
									FROM Opportunity
									LIMIT 1];

		List<OpportunityTeamMember> teamMembers = [SELECT Id, UserId 
													FROM OpportunityTeamMember
													WHERE OpportunityId = :opportunity.Id];

		System.assertEquals(1, teamMembers.size());

		Id previousOwnerId = teamMembers[0].UserId;

		Test.startTest();

		teamMembers[0].TeamMemberRole = 'Technical Account Manager Security';
		update teamMembers;

		opportunity.ownerId = [SELECT Id
								FROM User
								WHERE isActive = true
								AND Profile.Name = 'System Administrator'
								LIMIT 1][0].Id;
		update opportunity;

		System.assertEquals(2, [SELECT Id
								FROM OpportunityTeamMember
								WHERE OpportunityId = :opportunity.Id].size());

		Test.stopTest();

		System.assertEquals(2, [SELECT Id
								FROM OpportunityTeamMember
								WHERE OpportunityId = :opportunity.Id].size());

		System.assertEquals(1, [SELECT Id
								FROM OpportunitySplit
								WHERE SplitOwnerId = :previousOwnerId
								AND SplitType.DeveloperName = 'Overlay'].size());
	}
}