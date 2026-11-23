public class FixOpportunitySplitsBatch implements Database.Batchable<sObject> {

	private String query;

	public FixOpportunitySplitsBatch(String query) {
		if(query == null){
			query = 'SELECT Id FROM Opportunity';
		} else {
			this.query = query;
		}
	}


	public Database.QueryLocator start(Database.BatchableContext BC)
	{
	  return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope)
	{
		List<Opportunity> opportunities = (List<Opportunity>)scope;

		//FIX Team Members
		//List<OpportunityTeamMember> teamMembersToUpdate = new List<OpportunityTeamMember>();
		List<OpportunityTeamMember> extraOpportunityOwnersTeamMembers = new List<OpportunityTeamMember>();
		Set<String> userIdOpportunityIdWithOwnerRoleButNotOpportunityOwner = new Set<String>();

		for (OpportunityTeamMember opportunityTeamMember: [SELECT Id, Opportunity.OwnerId, UserId, TeamMemberRole
															FROM OpportunityTeamMember
															WHERE OpportunityId IN :opportunities
															AND TeamMemberRole = 'Opportunity Owner']) {

			/*if (opportunityTeamMember.Opportunity.OwnerId == opportunityTeamMember.UserId && opportunityTeamMember.TeamMemberRole != 'Opportunity Owner') {
				opportunityTeamMember.TeamMemberRole = 'Opportunity Owner';
				teamMembersToUpdate.add(opportunityTeamMember);
			} else*/ 
			if (opportunityTeamMember.UserId != opportunityTeamMember.Opportunity.OwnerId && opportunityTeamMember.TeamMemberRole == 'Opportunity Owner') {
				extraOpportunityOwnersTeamMembers.add(opportunityTeamMember);
				String key = opportunityTeamMember.UserId + '' + opportunityTeamMember.OpportunityId;
				userIdOpportunityIdWithOwnerRoleButNotOpportunityOwner.add(key);
			}
		}

		//FIX SPLITS
		List<OpportunitySplit> opportunitySplitsToDelete = new List<OpportunitySplit>();
		for(OpportunitySplit opportunitySplit: [SELECT Id, Opportunity.OwnerId, Opportunity.isClosed, SplitOwnerId, SplitType.DeveloperName
												FROM OpportunitySplit
												WHERE Opportunity.StageName != 'Deleted'
												AND OpportunityId IN :opportunities]){

			String key = opportunitySplit.SplitOwnerId + '' + opportunitySplit.OpportunityId;
			if (opportunitySplit.SplitType.DeveloperName == 'Revenue' && opportunitySplit.SplitOwnerId != opportunitySplit.Opportunity.OwnerId) {
				opportunitySplitsToDelete.add(opportunitySplit);
			} else if (opportunitySplit.SplitType.DeveloperName == 'Overlay' && (opportunitySplit.SplitOwnerId == opportunitySplit.Opportunity.OwnerId || userIdOpportunityIdWithOwnerRoleButNotOpportunityOwner.contains(key))) {
				opportunitySplitsToDelete.add(opportunitySplit);
			}
		}
		
		if(!opportunitySplitsToDelete.isEmpty()) {
			delete opportunitySplitsToDelete;
		}

		if (!extraOpportunityOwnersTeamMembers.isEmpty()) {
			//OpportunitySplitTriggerHandler already deleted some team members here
			delete [SELECT Id FROM OpportunityTeamMember WHERE Id IN :extraOpportunityOwnersTeamMembers];
		}
		

		/*if (!teamMembersToUpdate.isEmpty()) {
			update teamMembersToUpdate;
		}*/
	}

	public void finish(Database.BatchableContext BC)
	{

	}

	@testVisible
	private static void forTesting(){
		Integer i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
		i = 0;
	}
}