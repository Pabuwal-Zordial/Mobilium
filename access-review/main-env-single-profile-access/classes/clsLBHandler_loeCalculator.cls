/*************************************************************************************
Name                    clsLBHandler_loeCalculator
Developed By            West Monroe Partners
Created date            5/15/2017
*************************************************************************************/
public class clsLBHandler_loeCalculator {
	/*************************************************************************************
    Method Name             fetchQuoteLineProducts
    Developed By            West Monroe Partners
    Purpose                 Returns the quote line items for the present quote ID
    Created date            5/15/2017
	Parameters              Id -- quoteId
	Output type				list<SBQQ__QuoteLine__c>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		5/15/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static list<SBQQ__QuoteLine__c> fetchQuoteLineProducts (Id quoteId){
    	System.debug('In fetchQuoteLineProducts  >> ' + quoteId);
    	list<SBQQ__QuoteLine__c> list_relatedQuoteLines = new list<SBQQ__QuoteLine__c>();

    	//looping through the list of related quote lines
    	for(SBQQ__QuoteLine__c iterating_QuoteLine :   [SELECT
    														Id,
    														Deployment_Hours__c,
    														Documentation_Hours__c,
    														General_Hours__c,
    														Integration_Hours__c,
    														Internal_Testing_Hours__c,
    														Production_Launch_Support_Hours__c,
    														Soft_Staging_Hours__c,
    														UAT_Hours__c,
    														LoE_Instructions__c,
    														SBQQ__Product__c,
    														SBQQ__ProductCode__c,
    														SBQQ__ProductName__c,
															SBQQ__Product__r.LoE_Accepted__c,
															LoE_Accounted__c
    													FROM
    														SBQQ__QuoteLine__c
    													WHERE
    														SBQQ__Quote__c =:quoteId
															AND
															SBQQ__Product__r.LoE_Accepted__c = true
    													]){
    		//setting null values to be 0
    		if(iterating_QuoteLine.Deployment_Hours__c == null)
    			iterating_QuoteLine.Deployment_Hours__c = 0;
    		if(iterating_QuoteLine.Documentation_Hours__c == null)
    			iterating_QuoteLine.Documentation_Hours__c = 0;
    		if(iterating_QuoteLine.General_Hours__c == null)
    			iterating_QuoteLine.General_Hours__c = 0;
    		if(iterating_QuoteLine.Integration_Hours__c == null)
    			iterating_QuoteLine.Integration_Hours__c = 0;
    		if(iterating_QuoteLine.Internal_Testing_Hours__c == null)
    			iterating_QuoteLine.Internal_Testing_Hours__c = 0;
    		if(iterating_QuoteLine.Production_Launch_Support_Hours__c == null)
    			iterating_QuoteLine.Production_Launch_Support_Hours__c = 0;
    		if(iterating_QuoteLine.Soft_Staging_Hours__c == null)
    			iterating_QuoteLine.Soft_Staging_Hours__c = 0;
    		if(iterating_QuoteLine.UAT_Hours__c == null)
    			iterating_QuoteLine.UAT_Hours__c = 0;
    		//Adding to the list
    		list_relatedQuoteLines.add(iterating_QuoteLine);
    	}
    	return list_relatedQuoteLines;
    }
    /*************************************************************************************
    Method Name             fetchColumnHeaders
    Developed By            West Monroe Partners
    Purpose                 Returns the column headers from custom metadata type
    Created date            5/15/2017
	Output type				list<String>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		5/15/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static list<String> fetchColumnHeaders(){
    	list<String> list_customMetadataHeaders 					= new list<String>();
    	for(LoE_Phases__mdt iterating_header : 						[SELECT
    																			Id,
    																			MasterLabel,
    																			Display_Order__c
    																	 FROM
    																	 		LoE_Phases__mdt
    																	 ORDER BY Display_Order__c ASC
    																	]){
    		list_customMetadataHeaders.add(iterating_header.MasterLabel);
    	}
    	return list_customMetadataHeaders;
    }
    /*************************************************************************************
    Method Name             fetchCommonProducts
    Developed By            West Monroe Partners
    Purpose                 Returns the common headers from custom metadata type
    Created date            5/15/2017
	Output type				list<LoE_Calculator__mdt>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		5/15/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static list<LoE_Calculator__mdt> fetchCommonProducts(){
    	list<LoE_Calculator__mdt> list_customMetadataProducts 					= new list<LoE_Calculator__mdt>();
    	for(LoE_Calculator__mdt iterating_header : 						[SELECT
    																		Id,
    																		MasterLabel,
    																		Display_Order__c,
    																		isGeneralType__c
    																 FROM
    																 		LoE_Calculator__mdt
    																 ORDER BY Display_Order__c ASC
    																]){
    		list_customMetadataProducts.add(iterating_header);
    	}
    	return list_customMetadataProducts;
    }
	/*************************************************************************************
    Method Name             fetchSaveAccesss
    Developed By            West Monroe Partners
    Purpose                 Returns if the running user belongs to PSO group
    Created date            6/9/2017
	Output type				Boolean
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		6/9/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
	public static boolean fetchSaveAccesss(){
		list<Id> listOfIds = new list<Id>();
		for(GroupMember iterating_groupMember : [
													SELECT
															Id
													FROM
															GroupMember
													WHERE
															UserOrGroupId =:UserInfo.getUserId()
														AND
															Group.Name =:System.Label.PSO

												]
		){
			listOfIds.add(iterating_groupMember.Id);
		}

		if(listOfIds.isEmpty())
			return false;
		else
			return true;
	}
    /*************************************************************************************
    Method Name             fetchPrimaryQuote
    Developed By            West Monroe Partners
    Purpose                 Returns the common fields from primary quote
    Created date            5/17/2017
	Output type				SBQQ__Quote__c
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		5/17/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static SBQQ__Quote__c fetchPrimaryQuote(Id quoteId){
    	SBQQ__Quote__c inst_SBQQ_Quote = new SBQQ__Quote__c();
	//getting the quote from the utility class
	list<sObject> list_allRecords = clsUtility.queryRecordWithFilter('SBQQ__Quote__c', '', 'Id =\''+string.valueOf(quoteId) + '\'');
	//the first in the list is the quote record
	inst_SBQQ_Quote = (SBQQ__Quote__c) list_allRecords[0];

    	return inst_SBQQ_Quote;
    }
    /*************************************************************************************
    Method Name             saveQuoteAndLines
    Developed By            West Monroe Partners
    Purpose                 Returns the common fields from primary quote
    Created date            5/19/2017
    Parameters				SBQQ__Quote__c and list<SBQQ__QuoteLine__c>
	Output type				SBQQ__Quote__c
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		5/17/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static void saveQuoteAndLines(SBQQ__Quote__c primaryQuote, list<SBQQ__QuoteLine__c> list_quoteLines){
    	//saving quote
    	update primaryQuote;
    	//saving quote lines
    	update list_quoteLines;
    }
}