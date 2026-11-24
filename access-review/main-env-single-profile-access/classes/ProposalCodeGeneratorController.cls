public without sharing class ProposalCodeGeneratorController
{
	private static final Set<String> OPPORTUNITY_TYPES_NUMERIC_EXTENSION_CODE = new Set<String>
	{
		'TL_Term_License', 'PL-Perpetual License', 'RS-Rev Share or Rec Rev', 'POC-Proof of Concept'
	};
	private static final Set<String> OPPORTUNITY_TYPES_M_EXTENTION_CODE = new Set<String>
	{
		'MR-Maintenance Renewal'
	};
	private static final Set<String> OPPORTUNITY_TYPES_C_EXTENTION_CODE = new Set<String>
	{
		'UP-Upgrade to Perpetual Lic', 'CR-Change Request'
	};
	private static final Set<String> OPPORTUNITY_TYPES_R_EXTENTION_CODE = new Set<String>
	{
		'R-Recurring Revenue'
	};

	@AuraEnabled
	public static ProjectUtils.Response initData(Id opportunityId)
	{
		try
		{
			Opportunity opportunity = getOpportunityById(opportunityId);

			Boolean isMasterCode = opportunity.Proposal_Code__r.isEmpty();

			Map<String, Object> result = new Map<String, Object>
			{
				'isMasterCode' => isMasterCode,
				'opportunityType' => isMasterCode ? opportunity.Type : ''
			};

			return new ProjectUtils.Response(true, 'Success', result);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	@AuraEnabled
	public static ProjectUtils.Response generateMasterCode(Id opportunityId)
	{
		Savepoint sp = Database.setSavepoint();

		try
		{
			Opportunity opportunity = getOpportunityById(opportunityId);
			validateOpportunityRecord(opportunity);

			Decimal newProjectNumber;
			Decimal newProjectNumberExtension;
			if (opportunity.Parent_Opportunity__c == null)
			{
				newProjectNumber = ProposalCodeGeneratorSelector.getProjectNumber(opportunity.Customer_Acronym__c) + 1;
				newProjectNumberExtension = 1;
			}
			else
			{
				Set<String> opportunityTypes = getExtensionTypes(opportunity.Type);
				newProjectNumber = ProposalCodeGeneratorSelector.getProjectNumberByOpportunityId(opportunity.Parent_Opportunity__c);
				if (newProjectNumber == null)
				{
					throw new ProjectCodeGeneratorControllerException('Cannot generate a proposal code, parent opportunity don\'t have a code created.');
				}

				newProjectNumberExtension = ProposalCodeGeneratorSelector.getProjectNumberExtension(opportunity.Customer_Acronym__c, newProjectNumber, opportunityTypes) + 1;
			}

			String entity = opportunity.Entity_Number__c.substring(0,2);
			String acronym = opportunity.Customer_Number__c;
			String projectNumber = String.valueOf(newProjectNumber).leftPad(2, '0');
			String projectNumberExtension = getProjectExtensionNumber(opportunity.Type, newProjectNumberExtension);

			Proposal_Code__c projectCode = new Proposal_Code__c
			(
				Opportunity__c = opportunityId,
				Name = entity + acronym + '.' + projectNumber + '.' + projectNumberExtension,
				Customer_Acronym__c = opportunity.Customer_Acronym__c,
				Entity_Number__c = opportunity.Entity_Number__c,
				Is_Master_Code__c = true,
				Opportunity_Type__c = opportunity.Type,
				Project_Number__c = newProjectNumber,
				Project_Number_Extension__c = newProjectNumberExtension
			);

			insert projectCode;

			opportunity.Project_Code__c = projectCode.Name;

			update opportunity;

			return new ProjectUtils.Response(true, 'Proposal code created: ' + projectCode.Name, projectCode.Name);
		}
		catch (DmlException dmlEx)
		{
			return new ProjectUtils.Response(false, dmlEx.getDmlMessage(0), dmlEx.getStackTraceString());
		}
		catch (Exception ex)
		{
			Database.rollback(sp);
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	@AuraEnabled
	public static ProjectUtils.Response generateExtensionCode(Id opportunityId, String opportunityType)
	{
		try
		{
			Opportunity opportunity = getOpportunityById(opportunityId);
			validateOpportunityRecord(opportunity);
			Set<String> opportunityTypes = getExtensionTypes(opportunityType);

			Decimal newProjectNumber = ProposalCodeGeneratorSelector.getProjectNumberByOpportunityId(opportunityId);
			Decimal newProjectNumberExtension = ProposalCodeGeneratorSelector.getProjectNumberExtension(opportunity.Customer_Acronym__c, newProjectNumber, opportunityTypes) + 1;

			String entity = opportunity.Entity_Number__c.substring(0,2);
			String acronym = opportunity.Customer_Number__c;
			String projectNumber = String.valueOf(newProjectNumber).leftPad(2, '0');
			String projectNumberExtension = getProjectExtensionNumber(opportunityType, newProjectNumberExtension);

			Proposal_Code__c projectCode = new Proposal_Code__c
			(
				Opportunity__c = opportunityId,
				Name = entity + acronym + '.' + projectNumber + '.' + projectNumberExtension,
				Customer_Acronym__c = opportunity.Customer_Acronym__c,
				Entity_Number__c = opportunity.Entity_Number__c,
				Is_Master_Code__c = false,
				Opportunity_Type__c = opportunityType,
				Project_Number__c = newProjectNumber,
				Project_Number_Extension__c = newProjectNumberExtension
			);

			insert projectCode;

			return new ProjectUtils.Response(true, 'Proposal code created: ' + projectCode.Name, projectCode.Name);
		}
		catch (DmlException dmlEx)
		{
			return new ProjectUtils.Response(false, dmlEx.getDmlMessage(0), dmlEx.getStackTraceString());
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	private static String getProjectExtensionNumber(String opportunityType, Decimal extensionNumber)
	{
		if (opportunityType == 'MR-Maintenance Renewal')
		{
			return 'M' + String.valueOf(extensionNumber).leftPad(2, '0');
		}
		else if (opportunityType == 'R-Recurring Revenue')
		{
			return 'R' + String.valueOf(extensionNumber).leftPad(2, '0');
		}
		else if (OPPORTUNITY_TYPES_C_EXTENTION_CODE.contains(opportunityType))
		{
			return 'C' + String.valueOf(extensionNumber).leftPad(2, '0');
		}
		else
		{
			return String.valueOf(extensionNumber).leftPad(3, '0');
		}
	}

	private static Set<String> getExtensionTypes(String opportunityType){
		if (OPPORTUNITY_TYPES_R_EXTENTION_CODE.contains(opportunityType))
		{
			return OPPORTUNITY_TYPES_R_EXTENTION_CODE;
		}
		else if (OPPORTUNITY_TYPES_M_EXTENTION_CODE.contains(opportunityType))
		{
			return OPPORTUNITY_TYPES_M_EXTENTION_CODE;
		}
		else if (OPPORTUNITY_TYPES_C_EXTENTION_CODE.contains(opportunityType))
		{
			return OPPORTUNITY_TYPES_C_EXTENTION_CODE;
		}
		else
		{
			return OPPORTUNITY_TYPES_NUMERIC_EXTENSION_CODE;
		}
	}

	private static Opportunity getOpportunityById(Id opportunityId)
	{
		return
		[
			SELECT Id, Type, Customer_Acronym__c, Customer_Number__c, Entity_Number__c, Parent_Opportunity__c,
				(SELECT Id, Project_Number__c FROM Proposal_Code__r WHERE Is_Master_Code__c = true)
			FROM Opportunity
			WHERE Id = :opportunityId
		];
	}

	private static void validateOpportunityRecord(Opportunity opportunity)
	{
		if (opportunity.Customer_Acronym__c == null)
		{
			throw new ProjectCodeGeneratorControllerException('Opportunity customer acronym is required.');
		}

		if (String.isBlank(opportunity.Entity_Number__c))
		{
			throw new ProjectCodeGeneratorControllerException('Opportunity entity number is required.');
		}
	}

	private class ProjectCodeGeneratorControllerException extends Exception {}
}