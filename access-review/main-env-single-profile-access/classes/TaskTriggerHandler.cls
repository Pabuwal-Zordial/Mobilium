public class TaskTriggerHandler implements ITriggerHandler
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
        alignRecordType((List<Task>) newItems);
		replaceCountryAndSubRegionIds((List<Task>) newItems);
    }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        alignRecordType((List<Task>) newItems.values(), (Map<Id, Task>) oldItems);
		replaceCountryAndSubRegionIds((List<Task>) newItems.values());
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {
		updateHubspotTask((List<Task>) newItems.values());
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}

    private void alignRecordType(List<Task> newTasks)
    {
        alignRecordType(newTasks, new Map<Id, Task>());
    }
    
    private void alignRecordType(List<Task> newTasks, Map<Id, Task> oldTasks)
    {
        List<Task> taskToWork = new List<Task>();
        for (Task t : newTasks)
        {
            Task oldT = (oldTasks.containsKey(t.Id) ? oldTasks.get(t.Id) : new Task());
            
            if (t.Type != oldT.Type)
            {
                taskToWork.add(t);
            }
        }
        
        if (taskToWork.isEmpty())
        {
			return;   
        }
        
        Map<String, Id> recordTypesByName = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Task'])
        {
            recordTypesByName.put(rt.DeveloperName, rt.Id);
        }
        
        if (recordTypesByName.isEmpty())
        {
            return;   
        }
        
        for (Task t : taskToWork)
        {
            if (recordTypesByName.containsKey(t.Type))
            {
	            t.RecordTypeId = recordTypesByName.get(t.Type);
            }
        }
    }
    
    private void updateHubspotTask(List<Task> newTasks)
    {
        Set<Id> tasksToUpdateIds = new Set<Id>();
        
        if (isntRunningUserHubspot())
            return;
        
        for (Task t : newTasks)
        {
            if (t.Type == 'Website')
            {
                tasksToUpdateIds.add(t.Id);
            }
        }
        
        if (tasksToUpdateIds.isEmpty())
            return;
        
        updateHubspotTask_Future(tasksToUpdateIds);
    }
    
    @future
    public static void updateHubspotTask_Future(Set<Id> tasksToUpdateIds)
    {
        List<Task> tasksToUpdate = [SELECT Id, Subject, Description, Landing_Page_Name__c, Country__c, Sub_Region__c, ActivityDate FROM Task WHERE Id IN :tasksToUpdateIds];
        
        if (tasksToUpdate.isEmpty())
            return;
        
        String defaultStatus = getDefaultStatus();
        Id defaultQueueId = getDefaultQueue();
        
        Map<Id, String> campaignActions = new Map<Id, String>();
        for (Task t : tasksToUpdate) 
        {
            t.Status = (t.ActivityDate < System.today() ? 'Completed' : defaultStatus);
            t.OwnerId = defaultQueueId;
            processTaskBody(t, campaignActions);
            if (t.Landing_Page_Name__c != null)
            {
                t.Subject = t.Subject + ' [' + t.Landing_Page_Name__c + ']';
            }
        }
        
        if(!campaignActions.isEmpty())
        {
            Map<Id, Campaign> campaignMap = new Map<Id, Campaign>([SELECT Id, Name FROM Campaign WHERE Id IN :campaignActions.values()]);
            
            if (!campaignMap.isEmpty())
            {
                for (Task t : tasksToUpdate) 
                {
                    if (!campaignActions.containsKey(t.Id)) continue;
                    
                    if (!campaignMap.containsKey(campaignActions.get(t.Id))) continue;
                    
                    t.Description = t.Description + '\r\n' + 'SF Campaign Name: ' + campaignMap.get(campaignActions.get(t.Id)).Name;
                }
            }
        }
		System.debug('Entrou no future');
		replaceCountryAndSubRegionIds(tasksToUpdate);

        update tasksToUpdate;
    }
    
    public static void processTaskBody(Task t, Map<Id, String> campaignActions)
    {
        // TODO add this if Agency cant fix this Comments&nbsp;
        // t.Description = t.Description.replace('Comments&nbsp;', 'Comments');
        List<String> formEntries = String.isEmpty(t.Description) ? new List<String>() : t.Description.split('\\n');

        for (String formLine : formEntries)
        {           
            List<String> formLineBits = new List<String>();

            if (formLine.contains(':')) formLineBits = formLine.split(': ', 2);
            else continue;

            String key = formLineBits[0];
            String value = formLineBits[1];
                
            try {
                value = value.trim();

                if (key == 'sfCampaignId') {
                    campaignActions.put(t.Id, value);
                } else if (key == 'Landing Page Name') {
                    setField(t, 'Landing_Page_Name__c', value);
                } else if (key == 'LandingPageUrl') {
                    setField(t, 'Landing_Page_Url__c', value);
                } else if (key == 'Email') {
                    setField(t, 'Email_Provided__c', value);
                } else if (key == 'Company') {
                    setField(t, 'Company__c', value);
                } else if (key == 'Department') {
                    setField(t, 'Department__c', value);
                } else if (key == 'Country') {
                    setField(t, 'Country__c', value);
                } // ADD MORE FIELDS TO MAP HERE IF NEEDED
            } catch(Exception e) {
                System.debug(loggingLevel.WARN, e);
            }
        }
    }

	public static void setField(sObject o, String fieldName, String fieldValue)
    {
        String fieldType = o.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getType().Name();
        
        if (fieldType == 'DATE') { 
            o.put(fieldName, Date.valueOf(fieldValue));
        } else if(fieldType == 'DATETIME') {
            o.put(fieldName, Datetime.valueOf(fieldValue));
        } else if(fieldType == 'DECIMAL' || fieldType == 'CURRENCY') {
            o.put(fieldName, Decimal.valueOf(fieldValue));
        } else if(fieldType == 'INTEGER') {
            o.put(fieldName, Integer.valueOf(fieldValue));
        } else if(fieldType == 'LONG') {
            o.put(fieldName, Long.valueOf(fieldValue));
        } else if(fieldType == 'DOUBLE') {
            o.put(fieldName, Double.valueOf(fieldValue));
        } else if(fieldType == 'BOOLEAN') {
            o.put(fieldName, fieldValue.toUpperCase() == 'TRUE');
        } else {// String
            o.put(fieldName, fieldValue);
        }
    }
    
    private Boolean isntRunningUserHubspot()
    {
        if (Test.isRunningTest()) return false;
        List<Profile> runningUserHubspot = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() AND Name = 'Hubspot'];
        return runningUserHubspot.isEmpty();
    }
    
    /*private static String getClosedStatus(Task t)
    {
		Boolean emailRecordType = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosById().get(t.RecordTypeId).getName() == 'Email';        
        return (emailRecordType ? 'Clicked' : 'Completed');
    }*/
    
    private static String getDefaultStatus()
    {
        String defaultStatus;
		for (Schema.PicklistEntry pv: Task.Status.getDescribe().getPicklistValues()) {
            if (pv.isDefaultValue()) {
                defaultStatus = pv.getValue();
                break;
            }
        }
        return defaultStatus;
    }
    
    private static Id getDefaultQueue()
    {
        Id queueId;
        try
        {
            queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Inside_Sales'].Id;
        }
        catch (Exception e) {}
        return queueId;
    }

	private static void replaceCountryAndSubRegionIds(List<Task> taskList)
	{
		Set<Id> countryIdSet = new Set<Id>();

		for (Task t : taskList)
		{
			if (t.Country__c != null && (t.Country__c instanceof Id) && ((Id)t.Country__c).getSObjectType() == Territory__c.getSObjectType())
			{
				countryIdSet.add(t.Country__c);
			}
		}

		if (countryIdSet.isEmpty())
		{
			return;
		}

		Map<Id, Territory__c> countryMap = new Map<Id, Territory__c>([SELECT ID, Name, RecordType.DeveloperName, Parent_Territory__c, Parent_Territory__r.Name FROM Territory__c WHERE RecordType.DeveloperName = 'Country' AND Id in :countryIdSet]);

		for (Task t : taskList)
		{
			String countryId = t.Country__c;

			if (countryId != null && (countryId instanceof Id) && ((Id)countryId).getSObjectType() == Territory__c.getSObjectType())
			{
				t.Country__c = countryMap.get(countryId)?.Name != null ? countryMap.get(countryId)?.Name : countryId;
				t.Sub_Region__c = countryMap.get(countryId)?.Parent_Territory__r?.Name;
				t.Description = t.Description.replace(countryId, t.Country__c);
			}
		}
	}
}