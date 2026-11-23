public with sharing class ProposalCodesRelatedListController
{
	@AuraEnabled
	public static ProjectUtils.Response getRelatedRecords(Id recordId)
	{
		try
		{
			List<ProposalCodeWrapper> proposalCodes = new List<ProposalCodeWrapper>();
			for (Proposal_Code__c proposalCode : ProposalCodeGeneratorSelector.getProposalCodesByOpportinityId(new Set<Id> { recordId }))
			{
				proposalCodes.add(new ProposalCodeWrapper(proposalCode));
			}

			return new ProjectUtils.Response(true, 'Success', proposalCodes);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public class ProposalCodeWrapper
	{
		@AuraEnabled public String name { get; set; }
		@AuraEnabled public String link { get; set; }

		public ProposalCodeWrapper(Proposal_Code__c record)
		{
			this.name = record.Name;
			this.link = '/' + record.Id;
		}
	}
}