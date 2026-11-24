public class AcvBulkUpdateBatch_A implements Database.Batchable<sObject> {

  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT Id, Amount, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'To Import']);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope)
  {
		List<Opportunity> opportunities = (List<Opportunity>)scope;

		for (Opportunity opp : opportunities)
		{
			opp.ACV_Temp_Amount__c = opp.Amount;
			opp.ACV_Temp_Status__c = 'Amount Saved';
		}

		update opportunities;
  }

  public void finish(Database.BatchableContext BC)
  {
 
  }   

}