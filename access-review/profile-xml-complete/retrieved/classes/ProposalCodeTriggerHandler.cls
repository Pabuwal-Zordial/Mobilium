public inherited sharing class ProposalCodeTriggerHandler implements ITriggerHandler
{
	public static Boolean TriggerDisabled = false;

	public Boolean IsDisabled()
	{
		return false; //TODO: replace by a custom setting configuration
	}

	public void BeforeInsert(List<SObject> newItems) {}

	public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

	public void BeforeDelete(Map<Id, SObject> oldItems) {}

	public void AfterInsert(Map<Id, SObject> newItems) {}

	public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

	public void AfterDelete(Map<Id, SObject> oldItems)
	{
		Set<String> proposalCodes = new Set<String>();
		Set<Id> opportunitiesIds = new Set<Id>();

		for (Proposal_Code__c record : ((List<Proposal_Code__c>) oldItems.values()))
		{
			proposalCodes.add(record.Name);
			opportunitiesIds.add(record.Opportunity__c);
		}

		this.cleanProposalCodesFromOpportunities(proposalCodes, opportunitiesIds);
	}

	public void AfterUndelete(Map<Id, SObject> oldItems) {}

	private void cleanProposalCodesFromOpportunities (Set<String> proposalCodes, Set<Id> opportunitiesIds)
	{
		List<Opportunity> opportunities = [SELECT Id, Project_Code__c FROM Opportunity WHERE Id IN :opportunitiesIds AND Project_Code__c IN :proposalCodes];
		for (Opportunity opportunity : opportunities)
		{
			opportunity.Project_Code__c = null;
		}

		if (!opportunities.isEmpty())
		{
			update opportunities;
		}
	}
}