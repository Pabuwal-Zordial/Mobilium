public class AcvBulkUpdateBatch_E implements Database.Batchable<sObject> {

  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT ID, SBQQ__Opportunity2__c, SBQQ__Status__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.ACV_Temp_Status__c = 'Quote Calculated' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC]);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope)
  {
	  	List<SBQQ__Quote__c> primaryQuotes = (List<SBQQ__Quote__c>)scope;

		List<SBQQ__Quote__c> primaryQuotesToApprove = new List<SBQQ__Quote__c> ();
		List<Opportunity> toUpdateOpportunityList = new List<Opportunity> ();

		for (SBQQ__Quote__c pq : primaryQuotes)
		{
			pq.SBQQ__Status__c = 'Approved';
			pq.SBQQ__Primary__c = true;
			primaryQuotesToApprove.add(pq);
			toUpdateOpportunityList.add(new Opportunity(Id = pq.SBQQ__Opportunity2__c, ACV_Temp_Status__c = 'Quote Approved'));
		}
		update primaryQuotesToApprove;
		update toUpdateOpportunityList;
  }

  public void finish(Database.BatchableContext BC)
  {

  }

}