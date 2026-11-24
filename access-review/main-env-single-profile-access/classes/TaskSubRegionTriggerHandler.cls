public class TaskSubRegionTriggerHandler implements ITriggerHandler {


  public static Boolean isTriggerDisabled = false;

  public void BeforeInsert(List<SObject> newItems) 
  {
  updateSubRegion(newItems);
  
  }

   public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) 
  {
  updateSubRegion(newItems.values());
  
  }
  public void BeforeDelete(Map<Id, SObject> oldItems) {}
  
  public void AfterInsert(Map<Id, SObject> oldItems) 
  {
  
  }
  

  public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

  public void AfterDelete(Map<Id, SObject> oldItems) {}
  

  public void AfterUndelete(Map<Id, SObject> oldItems) {}
  
  public Boolean IsDisabled() {
    Inactivate_Trigger_On_Object__mdt mc = Inactivate_Trigger_On_Object__mdt.getInstance('Task');
    return isTriggerDisabled || (mc != null && !mc.Activate__c);
  }
  
  private static void updateSubRegion(List<Task> newTasks) {

    Set<Id> whatIds = new Set<Id>();
    Set<Id> whoIds = new Set<Id>();

    for (Task t : newTasks) {
        if (t.WhatId != null) whatIds.add(t.WhatId);
        if (t.WhoId != null) whoIds.add(t.WhoId);
    }

    // Query Opps and Accounts (whatId can be either)
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
        [SELECT Id, Sub_Region__c FROM Opportunity WHERE Id IN :whatIds]
    );

    Map<Id, Account> acctMap = new Map<Id, Account>(
        [SELECT Id, Sub_Region__c FROM Account WHERE Id IN :whatIds]
    );

    // Query Leads + Contacts (whoId)
    Map<Id, Lead> leadMap = new Map<Id, Lead>(
        [SELECT Id, Lead_Sub_Region__c FROM Lead WHERE Id IN :whoIds]
    );

    Map<Id, Contact> contactMap = new Map<Id, Contact>(
        [SELECT Id, Sub_Region__c FROM Contact WHERE Id IN :whoIds]
    );

    for (Task t : newTasks) {
        if (t.WhatId != null) {
            if (oppMap.containsKey(t.WhatId)) {
                t.Sub_Region__c = oppMap.get(t.WhatId).Sub_Region__c;
            } else if (acctMap.containsKey(t.WhatId)) {
                t.Sub_Region__c = acctMap.get(t.WhatId).Sub_Region__c;
            }
        } else if (t.WhoId != null) {
            if (leadMap.containsKey(t.WhoId)) {
                t.Sub_Region__c = leadMap.get(t.WhoId).Lead_Sub_Region__c;
            } else if (contactMap.containsKey(t.WhoId)) {
                t.Sub_Region__c = contactMap.get(t.WhoId).Sub_Region__c;
            }
        }
    }
}


}