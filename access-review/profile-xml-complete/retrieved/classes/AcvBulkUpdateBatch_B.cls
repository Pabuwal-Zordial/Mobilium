public class AcvBulkUpdateBatch_B implements Database.Batchable<sObject> {

  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT Id, Amount, CloseDate, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Amount Saved']);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope)
  {
		List<Opportunity> oppList = (List<Opportunity>)scope;

		List<Opportunity> toUpdateList = new List<Opportunity> ();
		List<SBQQ__Quote__c> quotesToInsert = new List<SBQQ__Quote__c>();

		for (Opportunity opp : oppList)
		{
			SBQQ__Quote__c pq = new SBQQ__Quote__c();
			pq.SBQQ__Opportunity2__c = opp.Id;
			pq.SBQQ__Primary__c = false;
			pq.SBQQ__StartDate__c= opp.CloseDate;
			quotesToInsert.add(pq);

			opp.ACV_Temp_Status__c = 'Primary Quote Created';
			toUpdateList.add(opp);
		}
		insert quotesToInsert;
		update toUpdateList;
  }

  public void finish(Database.BatchableContext BC)
  {

  }

}