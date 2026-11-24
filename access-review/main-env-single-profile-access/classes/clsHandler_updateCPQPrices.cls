/*************************************************************************************
Name                    clsHandler_updateCPQPrices
Developed By            West Monroe Partners
Created date            5/23/2017
*************************************************************************************/
public without sharing class clsHandler_updateCPQPrices {

    //variables for the class
    private final sObject mysObject;
	// The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public clsHandler_updateCPQPrices(ApexPages.StandardController stdController) {
        this.mysObject = (sObject)stdController.getRecord();
        
    }
    /*************************************************************************************
    Method Name             refreshAction
    Developed By            West Monroe Partners
    Purpose                 Webservice method to be invoked when the button is clicked
    Created date            5/23/2017
	Parameters              Id -- opportunityId
	Output type				String -- in case there is an exception that needs to be dealt with
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		5/23/2017		Refer method header
    *************************************************************************************/
    public PageReference refreshAction(){
        //getting the type of the standardController
        String objectType =  this.mysObject.getSObjectType().getDescribe().getName(); 
        System.debug('the object type >> ' + objectType); 
        String returnString;
        //if it is an opportunity
        if(objectType == 'Opportunity'){
            //querying opportunity
            Opportunity inst_Opportunity = [SELECT Id,SBQQ__PrimaryQuote__c FROM Opportunity WHERE ID=:this.mysObject.id];
            if(inst_Opportunity.SBQQ__PrimaryQuote__c == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'No primary quote found for the opportunity'));
                return null;
            }
            else{
                 PageReference pageRef = new PageReference('/apex/SBQQ__sb?id='+inst_Opportunity.SBQQ__PrimaryQuote__c+'&qid='+inst_Opportunity.SBQQ__PrimaryQuote__c);
                 pageRef.setRedirect(true);
                 return pageRef;
            }
                //returnString = refreshCPQPrices(inst_Opportunity.SBQQ__PrimaryQuote__c);
        }else{
            //querying Churn product

            Churned_Product__c inst_churnProduct = [SELECT Id,Renewal_Opportunity__c,Renewal_Opportunity__r.SBQQ__PrimaryQuote__c FROM Churned_Product__c WHERE ID=:this.mysObject.id];
            if(inst_churnProduct.Renewal_Opportunity__r.SBQQ__PrimaryQuote__c == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'No primary quote found for the renewal opportunity'));
                return null;
            }else{
                 PageReference pageRef = new PageReference('/apex/SBQQ__sb?id='+inst_churnProduct.Renewal_Opportunity__r.SBQQ__PrimaryQuote__c+'&qid='+inst_churnProduct.Renewal_Opportunity__r.SBQQ__PrimaryQuote__c);
                 pageRef.setRedirect(true);
                 return pageRef;
            }
                //returnString = refreshCPQPrices(inst_churnProduct.Renewal_Opportunity__r.SBQQ__PrimaryQuote__c);
        }
    }
	/*************************************************************************************
    Method Name             refreshCPQPrices
    Developed By            West Monroe Partners
    Purpose                 Webservice method to be invoked when the button is clicked
    Created date            5/23/2017
	Parameters              Id -- opportunityId
	Output type				String -- in case there is an exception that needs to be dealt with
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		5/23/2017		Refer method header
    ***********************************************************************************
	private String refreshCPQPrices(String primaryQuoteId){
	    //collections required for the method
        list<SBQQ__QuoteLine__c> list_primaryQuoteLines = new list<SBQQ__QuoteLine__c>();
        //getting all the quote lines of the primary quote from the 
        //SBQQ__PrimaryQuote__c field on the opportunity
        //iterating through the list
        for(SBQQ__QuoteLine__c iteratingQuoteLine : [ SELECT 
                                                            Id
                                                      FROM 
                                                            SBQQ__QuoteLine__c
                                                      WHERE
                                                            SBQQ__Quote__c =:primaryQuoteId
                                                    ]
        ){
            //Adding to the list
            list_primaryQuoteLines.add(iteratingQuoteLine);
        }

        //using a try catch here
        //if successful, then send Success, else send the exception.getMessage()
        try{
            update list_primaryQuoteLines;
            return 'Success';
        }catch(Exception e){
            return e.getMessage();
        }
	}**/
}