public inherited sharing class ProposalCodeGeneratorSelector
{
	public static Decimal getProjectNumber(Id acronym)
	{
		List<Proposal_Code__c> proposalCodes =
		[
			SELECT Id, Project_Number__c
			FROM Proposal_Code__c
			WHERE Customer_Acronym__c = :acronym
			ORDER BY Project_Number__c DESC
			LIMIT 1
		];

		return proposalCodes.isEmpty() ? 0 : proposalCodes[0].Project_Number__c;
	}

	public static Decimal getProjectNumberByOpportunityId(Id opportunityId)
	{
		List<Proposal_Code__c> proposalCodes =
		[
			SELECT Id, Project_Number__c
			FROM Proposal_Code__c
			WHERE Opportunity__c = :opportunityId
			ORDER BY Project_Number__c DESC
			LIMIT 1
		];

		return proposalCodes.isEmpty() ? null : proposalCodes[0].Project_Number__c;
	}

	public static Decimal getProjectNumberExtension(Id acronym, Decimal projectNumber, Set<String> opportunityTypes)
	{
		List<Proposal_Code__c> proposalCodes =
		[
			SELECT Id, Project_Number__c, Project_Number_Extension__c
			FROM Proposal_Code__c
			WHERE Customer_Acronym__c = :acronym AND Project_Number__c = :projectNumber AND Opportunity_Type__c IN :opportunityTypes
			ORDER BY Project_Number_Extension__c DESC
			LIMIT 1
		];

		return proposalCodes.isEmpty() ? 0 : proposalCodes[0].Project_Number_Extension__c;
	}

	public static List<Proposal_Code__c> getMasterProposalCodesByOpportinityId(Set<Id> opportunitiesIds)
	{
		return [SELECT Id, Name, Entity_Number__c, Opportunity__r.Entity_Number__c FROM Proposal_Code__c WHERE Opportunity__c IN :opportunitiesIds AND Is_Master_Code__c = true];
	}

	public static List<Proposal_Code__c> getProposalCodesByOpportinityId(Set<Id> opportunitiesIds)
	{
		return [SELECT Id, Opportunity__c, Name, Entity_Number__c, Opportunity__r.Entity_Number__c FROM Proposal_Code__c WHERE Opportunity__c IN :opportunitiesIds];
	}
}