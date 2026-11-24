public class AcvBulkUpdateBatch_C implements Database.Batchable<sObject> {

  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Business_Unit__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.ACV_Temp_Status__c = 'Primary Quote Created' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC]);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope)
  {
        List<SBQQ__Quote__c> primaryQuotes = (List<SBQQ__Quote__c>)scope;

        List<Opportunity> toUpdateList = new List<Opportunity> ();

        String genericProduct = '';
        String genericPriceBook = '01s41000008bmbUAAQ';

        if(Test.isRunningTest()) {
            genericProduct = [SELECT Id FROM Product2 LIMIT 1].Id;
            genericPriceBook = Test.getStandardPricebookId();
        }

        for (SBQQ__Quote__c pq : primaryQuotes)
        {
            if(!Test.isRunningTest()) {
                genericProduct = '';
                genericPriceBook = '01s41000008bmbUAAQ';

                if(pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('ROAMING')) { genericProduct = '01t410000031LqmAAE'; }
                else if (pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('RISK')) { genericProduct = '01t1K000006HVCoQAO'; }
                else if (pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('SECURITY')) { genericProduct = '01t41000005HaeHAAS'; }
                else if (pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('Testing')) { genericProduct = '01t1K000006I3YSQA0'; }
                else if (pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('Engagement and Experience')) { genericProduct = '01t1K000006IpsIQAS'; }
            }

            System.debug(pq.Id);

            QuoteReader quoteReader = new QuoteReader();
            QuoteModel quoteModel = quoteReader.read(pq.Id);

            ProductReader productReader = new ProductReader();
            ProductModel productModel = productReader.read(genericProduct, genericPriceBook,'USD');

            List<ProductModel> productModels = new List<ProductModel>();
            productModels.add(productModel);

            ProductAdder adder = new ProductAdder();
            quoteModel = adder.add(quoteModel, productModels, 0);

            QuoteSaver saver = new QuoteSaver();
            QuoteModel savedQuote = saver.save(quoteModel);

            Opportunity opp = new Opportunity(Id = pq.SBQQ__Opportunity2__c, ACV_Temp_Status__c = 'Product Added');
            toUpdateList.add(opp);
        }
        update toUpdateList;
    
  }

  public void finish(Database.BatchableContext BC)
  {

  }

}