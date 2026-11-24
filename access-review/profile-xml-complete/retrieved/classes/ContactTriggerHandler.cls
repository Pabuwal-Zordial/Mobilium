public class ContactTriggerHandler implements ITriggerHandler
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
 
    public void BeforeInsert(List<SObject> newItems) {
        updateURLFields((List<Contact>) newItems);
    }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        updateURLFields((List<Contact>) newItems.values());
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {}
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    private void updateURLFields(List<Contact> newContacts)
    {
        for (Contact c : newContacts)
        {
            if (c.Hubspot_Last_Referring_Website_Long__c != null)
            {
                c.Hubspot_Last_Referring_Website__c = c.Hubspot_Last_Referring_Website_Long__c.substringBefore('?').abbreviate(252);
            }
            if (c.Hubspot_Last_Webpage_Seen_Long__c != null)
            {
                c.Hubspot_Last_Webpage_Seen__c = c.Hubspot_Last_Webpage_Seen_Long__c.substringBefore('?').abbreviate(252);
            }
        }
    }
}