@isTest
private class ContentDocumentTest {
   static testMethod void UnitTest() {
           
       Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Super Sales User'];
        User salesUser_1 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
           EmailEncodingKey='UTF-8', LastName='SalesUserTesting1', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = salesUserProfile.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser12234@mbil1212.com');
            insert salesUser_1;
       System.runAs(salesUser_1){ 
           Pricebook2 inst_priceBook = new Pricebook2();
           inst_priceBook = new Pricebook2(Name = 'Test Class pricebook', Description = 'Test Class pricebook', IsActive = true );
            insert inst_priceBook;
           Currency_Table__c inst_Currency_Table = new Currency_Table__c();
           inst_Currency_Table = new Currency_Table__c(
                                                            Name = 'INR',
                                                            Conversion_Rate__c = 0.15
                                                            );
          
           //DML - currency
           insert inst_Currency_Table;

           
           Account a = new Account();
           a.name = 'Test Account';
           insert a; 
           Opportunity test_opportunity = new Opportunity(AccountId=a.Id,
                                                          Name = 'Test Opportunity',
                                                          StageName ='White Space',
                                                          CloseDate = System.today(),
                                                          //CurrencyIsoCode = 'USD',
                                                          Probability_to_Close_Picklist__c = '0%',
                                                          Type = 'TL-Term License',
                                                          Amount = 0.00,
                                                          Pricebook2Id = inst_priceBook.id,
                                                          Business_Unit__c = 'Roaming',
                                                          Currency_Table__c = inst_Currency_Table.id,
                                                          Total_Roaming_Forecast_QC__c = 1234
                                                         );
           insert test_opportunity;                 
                                 
         Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='Header_Picture1', 
            PathOnClient ='/Header_Picture1.jpg',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion_1;
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
       ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=a.id;
        contentlink.ShareType= 'V';
        contentlink.ContentDocumentId=contentVersion_2.ContentDocumentId;

        insert contentlink;
           If (test_opportunity.StageName == 'Closed'){
        delete contentlink;
        delete  documents;   
           }

                                }
    
     
  }
}