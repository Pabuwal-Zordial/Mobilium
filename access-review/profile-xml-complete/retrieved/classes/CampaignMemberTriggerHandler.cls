public class CampaignMemberTriggerHandler implements ITriggerHandler
{
    private enum Action { ADD, REMOVE }
    
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
 
    public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems)
    {
        updateRelatedCampaignField((Map<Id, CampaignMember>) newItems, Action.ADD);
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void AfterDelete(Map<Id, SObject> oldItems)
    {
		updateRelatedCampaignField((Map<Id, CampaignMember>) oldItems, Action.REMOVE);
    }
 
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {
		updateRelatedCampaignField((Map<Id, CampaignMember>) oldItems, Action.ADD);
    }
    
    private void updateRelatedCampaignField(Map<Id, CampaignMember> campaignMembers, CampaignMemberTriggerHandler.Action action)
    {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        for (CampaignMember cm : campaignMembers.values())
        {
            if (cm.ContactId != null)
            {
                contactIds.add(cm.ContactId);
            }
            else if (cm.LeadId != null)
            {
                leadIds.add(cm.LeadId);
            }
        }
        
        if (contactIds.isEmpty() && leadIds.isEmpty())
            return;
        
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        if (!contactIds.isEmpty())
	        contacts = new Map<Id, Contact>([SELECT Id, Campaign_Contact_Source__c FROM Contact WHERE Id IN :contactIds]);

        Map<Id, Lead> leads = new Map<Id, Lead>();
        if (!leadIds.isEmpty())
        	leads = new Map<Id, Lead>([SELECT Id, Campaign_Lead_Source__c FROM Lead WHERE Id IN :leadIds]);
            
        if (contacts.isEmpty() && leads.isEmpty())
            return;
        
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Lead> leadsToUpdate = new List<Lead>();
        for (CampaignMember cm : campaignMembers.values())
        {
            if (contacts.containsKey(cm.ContactId))
            {
                Contact c = contacts.get(cm.ContactId);
                if (action == CampaignMemberTriggerHandler.Action.ADD && c.Campaign_Contact_Source__c == null)
                {
                    c.Campaign_Contact_Source__c = cm.CampaignId;
	                contactsToUpdate.add(c);
                }
                else if (action == CampaignMemberTriggerHandler.Action.REMOVE && c.Campaign_Contact_Source__c == cm.CampaignId)
                {
                    c.Campaign_Contact_Source__c = null;
	                contactsToUpdate.add(c);
                }
            }
            else if (leads.containsKey(cm.LeadId))
            {
                Lead l = leads.get(cm.LeadId);
                if (action == CampaignMemberTriggerHandler.Action.ADD && l.Campaign_Lead_Source__c == null)
                {
                    l.Campaign_Lead_Source__c = cm.CampaignId;
                    leadsToUpdate.add(l);
                }
                else if (action == CampaignMemberTriggerHandler.Action.REMOVE && l.Campaign_Lead_Source__c == cm.CampaignId)
                {
                    l.Campaign_Lead_Source__c = null;
                    leadsToUpdate.add(l);
                }
            }
        }
        
        if (!contactsToUpdate.isEmpty())
            Database.update(contactsToUpdate, false);
        
        if (!leadsToUpdate.isEmpty())
            Database.update(leadsToUpdate, false);
    }
}