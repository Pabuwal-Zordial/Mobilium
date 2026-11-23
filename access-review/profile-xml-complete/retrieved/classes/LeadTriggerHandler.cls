public class LeadTriggerHandler implements ITriggerHandler
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
        updateURLFields((List<Lead>) newItems);
        updateLeadSubRegionFields((List<Lead>) newItems);
    }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        updateURLFields((List<Lead>) newItems.values());
        updateLeadSubRegionFields((List<Lead>) newItems.values());
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {}
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    private void updateURLFields(List<Lead> newLeads)
    {
        for (Lead l : newLeads)
        {
            if (l.Hubspot_Last_Referring_Website_Long__c != null)
            {
                l.Hubspot_Last_Referring_Website__c = l.Hubspot_Last_Referring_Website_Long__c.substringBefore('?');
            }
            if (l.Hubspot_Last_Webpage_Seen_Long__c != null)
            {
                l.Hubspot_Last_Webpage_Seen__c = l.Hubspot_Last_Webpage_Seen_Long__c.substringBefore('?');
            }
            if (l.Website_Long__c != null)
            {
                l.Website = l.Website_Long__c.substringBefore('?');
            }
        }
    }
    
    private void updateLeadSubRegionFields(List<Lead> newLeads)
    {
    
    List<Territory__c> territorylist=[select id,Name,RecordTypeId,Parent_Territory__c,Parent_Territory__r.Name 
                                      from Territory__c where RecordTypeId='01241000001I4AFAA0'];
    
     for (Lead l : newLeads)
     {
        for(Territory__c terr : territorylist)
         {
         if(l.Lead_country__c!=null)
         {
             if(l.Lead_country__c==terr.Name)
             {
              l.Lead_Sub_Region__c=terr.Parent_Territory__r.Name;
             }
         }
         else if(l.Lead_country__c==null)
         {
           if(l.Country__c==terr.Id)
             {
              l.Lead_country__c=terr.Name;
              l.Lead_Sub_Region__c=l.Sub_Region__c;
              }
         }
         }
     }
    }
}