public class AcvBulkUpdateBatch_F implements Database.Batchable<sObject> {

  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT Id, Amount, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity  WHERE ACV_Temp_Status__c = 'Quote Approved']);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope)
  {
	  	List<Opportunity> opportunities = (List<Opportunity>)scope;

		Map<Id, Opportunity> oppList = new Map<Id, Opportunity>(opportunities);

		List<Project__c> existingProjects = [SELECT ID,
											Opportunity__c,
											PO_Date__c,
											Contract_Date__c,
											HW_delivery_Date__c, 
											RFA_Date__c,
											UAT_Date__c,
											Stability_Date__c,
											FA_Date__c,
											KPI_Date__c,
											Retention_Date__c,
											Opportunity__r.CloseDate
											FROM
											Project__c
											WHERE 
											Opportunity__c IN :oppList.keySet()
											ORDER BY CreatedDate ASC
										];

		Map<Id, Project__c> oppIdExistingProjectMap = new Map<Id, Project__c>();

		for(Project__c p : existingProjects)
		{
			if (p.Opportunity__c != null && !oppIdExistingProjectMap.containsKey(p.Opportunity__c))
			{
				oppIdExistingProjectMap.put(p.Opportunity__c, p);
			}
		}


		Set<Id> projectIdSet = new Set<Id>();

		for(Project__c p : oppIdExistingProjectMap.values())
		{
			p.PO_Date__c = p.Opportunity__r.CloseDate;
			p.Contract_Date__c =  p.Opportunity__r.CloseDate;
			p.HW_delivery_Date__c =  p.Opportunity__r.CloseDate;
			p.HW_Install_Date__c =  p.Opportunity__r.CloseDate;
			p.SW_delivery_Date__c =  p.Opportunity__r.CloseDate;
			p.RFA_Date__c =  p.Opportunity__r.CloseDate;
			p.UAT_Date__c =  p.Opportunity__r.CloseDate;
			p.Stability_Date__c =  p.Opportunity__r.CloseDate;
			p.FA_Date__c =  p.Opportunity__r.CloseDate;
			p.KPI_Date__c =  p.Opportunity__r.CloseDate;
			p.Retention_Date__c =  p.Opportunity__r.CloseDate;
			projectIdSet.add(p.Id);
		}

		List<Milestone__c> mList = [SELECT Id,PO__c, Contract__c FROM Milestone__c WHERE  project__c IN :projectIdSet];

		for(Milestone__c m :mList)
		{
			m.PO__c = 100;
		}

		update oppIdExistingProjectMap.values();
		update mList;

		List<Opportunity> listToUpdate = new List<Opportunity>();

		for (Opportunity opp : oppList.values())
		{
			listToUpdate.add(new Opportunity(Id = opp.Id, ACV_Temp_Status__c = 'Process Completed'));
		}
		update listToUpdate;
	
  }

  public void finish(Database.BatchableContext BC)
  {

  }

}