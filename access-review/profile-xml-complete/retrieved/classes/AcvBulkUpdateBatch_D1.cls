public class AcvBulkUpdateBatch_D1 implements Database.Batchable<sObject> {

  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c, SBQQ__Opportunity2__r.Conversion_Rate__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.ACV_Temp_Status__c = 'Quote Calculated' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC]);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope)
  {
	List<SBQQ__Quote__c> primaryQuotes = (List<SBQQ__Quote__c>)scope;

	List<Opportunity> toUpdateList = new List<Opportunity> ();

		for (SBQQ__Quote__c pq : primaryQuotes)
		{
			QuoteReader quoteReader = new QuoteReader();
			QuoteModel quoteModel = quoteReader.read(pq.Id);

			QuoteCalculator calculator = new QuoteCalculator();
			calculator.calculate(quoteModel, 'MyCallback');

			QuoteSaver saver = new QuoteSaver();
			QuoteModel savedQuote = saver.save(quoteModel);

			Opportunity opp = new Opportunity(Id = pq.SBQQ__Opportunity2__c, ACV_Temp_Status__c = 'Quote Calculated');
			toUpdateList.add(opp);
		}
		update toUpdateList;
	
  }

  public void finish(Database.BatchableContext BC)
  {

  }

}