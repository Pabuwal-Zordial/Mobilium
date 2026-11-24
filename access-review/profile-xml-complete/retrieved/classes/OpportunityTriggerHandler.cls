public class OpportunityTriggerHandler implements ITriggerHandler
{
	// Allows unit tests (or other code) to disable this trigger for the transaction
	public static Boolean TriggerDisabled = false;

	/*
		Checks to see if the trigger has been disabled either by custom setting or by running code
	*/
	public Boolean IsDisabled()
	{
		/*if (TriggerSettings__c.AccountTriggerDisabled__c = true)
			return true;
		else
			return TriggerDisabled;*/
		return false;
	}

	public void BeforeInsert(List<SObject> newItems)
	{
		updateAcronym((List<Opportunity>) newItems);
	}

	public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
	{
		Map<Id, Opportunity> opportunitiesToValidateAcronym = new Map<Id, Opportunity> ();
		for (Opportunity record : ((List<Opportunity>) newItems.values()))
		{
			this.updateNonStandardConditions(record);

			Opportunity oldRecord = (Opportunity) oldItems.get(record.Id);
			if (record.Customer_Acronym__c <> oldRecord.Customer_Acronym__c && oldRecord.Customer_Acronym__c <> null)
			{
				opportunitiesToValidateAcronym.put(record.Id, record);
			}

			this.syncOpportnityEntityCode(record, oldRecord);
		}
		updateAcronym((List<Opportunity>) newItems.values(), (Map<Id, Opportunity>) oldItems);
		emptyRecordType((List<Opportunity>) newItems.values(), (Map<Id, Opportunity>) oldItems);
		this.validateAcronym(opportunitiesToValidateAcronym);
	}

	public void BeforeDelete(Map<Id, SObject> oldItems) {}

	public void AfterInsert(Map<Id, SObject> newItems) {}

	public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
	{
		Set<Id> changedEntityNumberOppIds = new Set<Id>();

		for (Opportunity record : ((List<Opportunity>) newItems.values()))
		{
			Opportunity oldRecord = (Opportunity) oldItems.get(record.Id);
			if (record.Entity_Number__c <> oldRecord.Entity_Number__c)
			{
				changedEntityNumberOppIds.add(record.Id);
			}
		}

		this.syncPoposalCodeEntityNumber(changedEntityNumberOppIds);
	}

	public void AfterDelete(Map<Id, SObject> oldItems) {}

	public void AfterUndelete(Map<Id, SObject> oldItems) {}

	private void updateAcronym(List<Opportunity> opps)
	{
		updateAcronym(opps, new Map<Id, Opportunity>());
	}

	private void emptyRecordType(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpp)
	{
		for (Opportunity opp : newOpps)
		{
			if (opp.IsClosed == false && oldOpp.get(opp.Id).IsClosed == true)
			{
				opp.RecordTypeId = null;
			}
		}
	}

	private void updateAcronym(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps)
	{
		Set<Id> changeRequestOppIds = new Set<Id>();
		Map<Id, Opportunity> oppsByChangeRequestOpps = new Map<Id, Opportunity>();
		for (Opportunity o : newOpps)
		{
			Opportunity oldO = (oldOpps.containsKey(o.Id) ? oldOpps.get(o.Id) : new Opportunity());
			if (o.Parent_Opportunity__c != oldO.Parent_Opportunity__c)
			{
				if (o.Parent_Opportunity__c != null)
				{
					changeRequestOppIds.add(o.Parent_Opportunity__c);
					oppsByChangeRequestOpps.put(o.Parent_Opportunity__c, o);
				}
				else
				{
					o.Customer_Acronym__c = null;
				}
			}
		}

		if (changeRequestOppIds.isEmpty())
		{
			return;
		}

		for (Opportunity o : [SELECT Id, Customer_Acronym__c FROM Opportunity WHERE Id IN :changeRequestOppIds])
		{
			oppsByChangeRequestOpps.get(o.Id).Customer_Acronym__c = o.Customer_Acronym__c;
		}
	}

	private void syncOpportnityEntityCode(Opportunity record, Opportunity oldRecord)
	{
		if (String.isNotBlank(record.Project_Code__c) && record.Entity_Number__c <> oldRecord.Entity_Number__c & String.isNotBlank(record.Entity_Number__c) && String.isNotBlank(oldRecord.Entity_Number__c))
		{
			record.Project_Code__c = record.Entity_Number__c.substring(0, 2) + record.Project_Code__c.substring(2);
		}
	}

	private void updateNonStandardConditions(Opportunity record)
	{
		if(record.Opportunity_Approval_Type__c == 'Non-Standard' && record.Hardware_delivery_involved__c == 'Yes'){
			Set<String> multipicklistValues = new Set<String>();
            if (record.NON_STANDARD_CONDITIONS__c != null) {
                multipicklistValues.addAll(record.NON_STANDARD_CONDITIONS__c.split(';'));
            }

            multipicklistValues.add('Commercial or COTS 3rd party HW/SW” STANDARD Vendor LIST in PS template + Margin is < 25% (like Oracle, HP, Dell, Couchbase, Posgress, Cloudera, Dialogic, etc.)');

            record.NON_STANDARD_CONDITIONS__c = String.join(new List<String>(multipicklistValues), ';');

		}
	}

	private void syncPoposalCodeEntityNumber(Set<Id> opportunitiesIds)
	{
		if (!opportunitiesIds.isEmpty())
		{
			ProposalCodeService.syncEntityNumber(opportunitiesIds);
		}
	}

	private void validateAcronym(Map<Id, Opportunity> records)
	{
		if (!records.isEmpty())
		{
			for (Proposal_Code__c proposalCode : ProposalCodeGeneratorSelector.getProposalCodesByOpportinityId(records.keySet()))
			{
				records.get(proposalCode.Opportunity__c).addError('Cannot change customer acronym on opportunities with related proposal codes.');
			}
		}
	}
}