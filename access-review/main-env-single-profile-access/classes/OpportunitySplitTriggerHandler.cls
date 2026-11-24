public class OpportunitySplitTriggerHandler implements ITriggerHandler {
	@testVisible
	private static final String SPLIT_TYPE_REVENUE = 'Revenue';
	private static final String SPLIT_TYPE_OVERLAY = 'Overlay';

	public static Boolean isTriggerDisabled = false;

	public void BeforeInsert(List<SObject> newItems) {}

	public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

	public void BeforeDelete(Map<Id, SObject> oldItems) {}

	public void AfterInsert(Map<Id, SObject> newItems) {
		deleteOpportunitySplitForOldOwnerOnClosedOpportunities((Map<Id, OpportunitySplit>) newItems);
	}

	public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

	public void AfterDelete(Map<Id, SObject> oldItems) {
		deleteExtraOpportunityOwnersTeamMembers(((Map<Id, OpportunitySplit>) oldItems).values());
	}

	public void AfterUndelete(Map<Id, SObject> oldItems) {}

	private void deleteOpportunitySplitForOldOwnerOnClosedOpportunities(Map<Id, OpportunitySplit> opportunitySplitsById) {
		Set<Id> opportunityIds = new Set<Id>();
		Set<String> newSplitsOpportunityIdUserIdKey = new Set<String>();
		for (OpportunitySplit opportunitySplit: opportunitySplitsById.values()) {
			opportunityIds.add(opportunitySplit.OpportunityId);
			newSplitsOpportunityIdUserIdKey.add((opportunitySplit.SplitOwnerId + '' + opportunitySplit.OpportunityId));
		}

		List<OpportunitySplit> opportunitySplitsToDelete = new List<OpportunitySplit>();
		Set<Id> opportunityIdsToCheckTeamMember = new Set<Id>();
		Map<String, OpportunitySplit> revenueSplitsOpportunityIdUserIdKey = new Map<String, OpportunitySplit>();

		for(OpportunitySplit opportunitySplit: [SELECT Id, Opportunity.OwnerId, SplitOwnerId, SplitType.DeveloperName, OpportunityId, SplitNote, SplitPercentage
												FROM OpportunitySplit
												WHERE Opportunity.StageName != 'Deleted'
												AND OpportunityId IN :opportunityIds
												ORDER BY SplitType.DeveloperName DESC]){

			if (opportunitySplit.SplitType.DeveloperName == SPLIT_TYPE_REVENUE && opportunitySplit.SplitOwnerId != opportunitySplit.Opportunity.OwnerId) {
				opportunitySplitsToDelete.add(opportunitySplit);
				//we need to make sure the query of Opportunity Splits are ordered so Revenues appear first
				revenueSplitsOpportunityIdUserIdKey.put((opportunitySplit.SplitOwnerId + '' + opportunitySplit.OpportunityId), opportunitySplit);
			} else if (opportunitySplit.SplitType.DeveloperName == SPLIT_TYPE_OVERLAY && 
						(opportunitySplit.SplitOwnerId == opportunitySplit.Opportunity.OwnerId
						//If the system had a revenue split for the same user in the same opportunity it was due to bad data (he was the previous owner with 2 splits - 1 revenue, 1 - overlay), so lets delete it was well
						|| revenueSplitsOpportunityIdUserIdKey.containsKey((opportunitySplit.SplitOwnerId + '' + opportunitySplit.OpportunityId)))) {
				opportunitySplitsToDelete.add(opportunitySplit);
			}

			if (opportunitySplit.SplitType.DeveloperName == SPLIT_TYPE_REVENUE && opportunitySplitsById.containsKey(opportunitySplit.Id)) {
				opportunityIdsToCheckTeamMember.add(opportunitySplit.OpportunityId);
			}
		}

		
		List<OpportunityTeamMember> teamMembersToUpdate = new List<OpportunityTeamMember>();
		List<OpportunitySplit> opportunitySplitsToUpdate = new List<OpportunitySplit>();
		if (!opportunityIdsToCheckTeamMember.isEmpty()) {
			Id opportunitySplitTypeOverlayId = [SELECT Id FROM OpportunitySplitType WHERE DeveloperName = 'Overlay'].Id;

			for (OpportunityTeamMember opportunityTeamMember: [SELECT Id, Opportunity.OwnerId, UserId, TeamMemberRole
																FROM OpportunityTeamMember
																WHERE TeamMemberRole != 'Opportunity Owner'
																AND OpportunityId IN :opportunityIdsToCheckTeamMember]) {

				String userIdOpportunityIdKey = opportunityTeamMember.UserId + '' + opportunityTeamMember.OpportunityId;
				if(opportunityTeamMember.Opportunity.OwnerId == opportunityTeamMember.UserId && newSplitsOpportunityIdUserIdKey.contains(userIdOpportunityIdKey)) {
					opportunityTeamMember.TeamMemberRole = 'Opportunity Owner';
					teamMembersToUpdate.add(opportunityTeamMember);
				} else if (opportunityTeamMember.Opportunity.OwnerId != opportunityTeamMember.UserId && revenueSplitsOpportunityIdUserIdKey.containsKey(userIdOpportunityIdKey)) {
					OpportunitySplit splitToChangeToOverlay = revenueSplitsOpportunityIdUserIdKey.get(userIdOpportunityIdKey);
					OpportunitySplit newOverlaySplit = new OpportunitySplit();
					newOverlaySplit.SplitOwnerId = splitToChangeToOverlay.SplitOwnerId;
					newOverlaySplit.SplitTypeId = opportunitySplitTypeOverlayId;
					newOverlaySplit.SplitPercentage = splitToChangeToOverlay.SplitPercentage;
					newOverlaySplit.SplitNote = splitToChangeToOverlay.SplitNote;
					newOverlaySplit.OpportunityId = splitToChangeToOverlay.OpportunityId;
					opportunitySplitsToUpdate.add(newOverlaySplit);
				}
			}
		}

		if (!opportunitySplitsToDelete.isEmpty()) {
			delete opportunitySplitsToDelete;
		}

		if (!opportunitySplitsToUpdate.isEmpty()) {
			insert opportunitySplitsToUpdate;
		}

		if (!teamMembersToUpdate.isEmpty()) {
			update teamMembersToUpdate;
		}
	}

	private void deleteExtraOpportunityOwnersTeamMembers(List<OpportunitySplit> opportunitySplits) {
		Set<Id> opportunityIds = new Set<Id>();
		for (OpportunitySplit opportunitySplit: opportunitySplits) {
			opportunityIds.add(opportunitySplit.OpportunityId);
		}

		List<OpportunityTeamMember> extraOpportunityOwnersTeamMembers = new List<OpportunityTeamMember>();
		for (OpportunityTeamMember opportunityTeamMember: [SELECT Id, Opportunity.OwnerId, UserId,OpportunityId
															FROM OpportunityTeamMember
															WHERE TeamMemberRole = 'Opportunity Owner'
															AND OpportunityId IN :opportunityIds]) {

			if (opportunityTeamMember.UserId != opportunityTeamMember.Opportunity.OwnerId) {
				extraOpportunityOwnersTeamMembers.add(opportunityTeamMember);
			}
		}

		if(!extraOpportunityOwnersTeamMembers.isEmpty()) {
			delete extraOpportunityOwnersTeamMembers;
		}
	}

	public Boolean IsDisabled() {
		Inactivate_Trigger_On_Object__mdt mc = Inactivate_Trigger_On_Object__mdt.getInstance('OpportunitySplit');
		return isTriggerDisabled || (mc != null && !mc.Activate__c);
	}
}