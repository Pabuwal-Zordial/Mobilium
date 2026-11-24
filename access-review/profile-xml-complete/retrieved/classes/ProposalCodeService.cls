public inherited sharing class ProposalCodeService
{
	public static void syncEntityNumber(Set<Id> opportunitiesIds)
	{
		List<Proposal_Code__c> proposalCodesToUpdate = ProposalCodeGeneratorSelector.getProposalCodesByOpportinityId(opportunitiesIds);

		for (Proposal_Code__c proposalCode : proposalCodesToUpdate)
		{
			proposalCode.Entity_Number__c = proposalCode.Opportunity__r.Entity_Number__c;
			proposalCode.Name = proposalCode.Entity_Number__c.substring(0, 2) + proposalCode.Name.substring(2);
		}

		update proposalCodesToUpdate;
	}
}