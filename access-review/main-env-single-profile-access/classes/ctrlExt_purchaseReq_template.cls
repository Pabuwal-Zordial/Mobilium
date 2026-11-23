/*************************************************************************************
Name                    ctrlExt_purchaseReq_template
Developed By            West Monroe Partners
Purpose                 Refer individual method headers
Created date            5/2/2017
*************************************************************************************/
public class ctrlExt_purchaseReq_template {
	//class variables
	private final sObject mysObject;
	public Project__c runningProject{get; set;}
	public Quote_template__mdt quoteTemplate {get; set;}
	public map<String,list<SBQQ__QuoteLine__c>> map_groupToLineItemMapping{get; set;}
	public list<SBQQ__QuoteLine__c>list_nonGroupedItems {get; set;}
	public map<String, Double> map_groupToTotals{get; set;}
	public Boolean bln_isGrouped{get; set;}
	public list<String> list_quoteGroup{get; set;}
	public SBQQ__Quote__c sbqq_quote{get; set;}
    public string str_TAMNames{get; set;}
	// The extension constructor initializes the private member
     // variable mysObject by using the getRecord method from the standard
     // controller.
	public ctrlExt_purchaseReq_template(ApexPages.StandardController stdController) {
		 list<SBQQ__QuoteLine__c> list_relatedQuotelinesIds 		 = new list<SBQQ__QuoteLine__c>();
		 runningProject 									 = new Project__c();
		 this.mysObject 									 = (sObject)stdController.getRecord();
		 map_groupToLineItemMapping		 					 = new map<String,list<SBQQ__QuoteLine__c>>();
		 list_nonGroupedItems								 = new list<SBQQ__QuoteLine__c>();
		 bln_isGrouped										 = true;
		 map_groupToTotals   								 = new map<String, Double>();
		 list_quoteGroup 									 = new list<String>();
		 sbqq_quote 										 = new SBQQ__Quote__c();
		 quoteTemplate 									     = new Quote_template__mdt();
         str_TAMNames                                        = '';
		 //getting related quote line related to the opportunity products
		 getQuoteTemplateCustomMetadata();
		 fetchRelatedOpportunityProducts((Id)mysObject.get('Id'));
         Project__c instProject = [SELECT Id, Opportunity__c FROM Project__c WHERE Id=:(Id)mysObject.get('Id')];
         getTAMSFromOpportunityTeam(instProject.Opportunity__c);
	}
	/*************************************************************************************
    Method Name             getQuoteTemplateCustomMetadata()
    Developed By            West Monroe Partners
    Purpose                 fetching the custom setting values from the 
    Created date            3/16/2017
	Parameters				N/A
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/16/2017		Refer method header
    **********************************************************************************/
    private void getQuoteTemplateCustomMetadata(){
            quoteTemplate = [SELECT
                                    MasterLabel,
                                    Address__c,
                                    Address1__c,
                                    Address2__c,
                                    Phone__c,
                                    Fax__c,
                                    Contact_Information__c,
                                    QuoteDocChildRelationship__c,
                                    Footer_Note_1__c,
                                    Foot_note_2__c
                             FROM Quote_template__mdt
                             LIMIT 1];
    
    }

    /*************************************************************************************
    Method Name             getTAMSFromOpportunityTeam()
    Developed By            West Monroe Partners
    Purpose                 fetching the names of the TAMs who are associated in the opportunity team
    Created date            6/5/2017
    Parameters			    opp id
    Output type		        void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0		    SS		6/5/2017	    Refer method header
    **********************************************************************************/
    private void getTAMSFromOpportunityTeam(Id opportunityId){
        //querying the tam members from opportunity team
        for(OpportunityTeamMember iterating_member : [ SELECT 
                                                            Id,
                                                            TeamMemberRole,
                                                            User.Name
                                                      FROM
                                                            OpportunityTeamMember
                                                      WHERE
                                                            TeamMemberRole =:Label.TAM
                                                            AND
                                                            OpportunityId =: opportunityId
                                                     ]
        ){
            if(str_TAMNames != '')
                str_TAMNames = str_TAMNames + ',' + iterating_member.User.Name;
            else
                str_TAMNames = iterating_member.User.Name;
        }
    }

	/*************************************************************************************
    Method Name             getPrimaryQuote()
    Developed By            West Monroe Partners
    Purpose                 fetching the primary quote from the opportunity to which the project is related
    Created date            5/2/2017
    Parameters			   project id
    Output type		  map<String,list<OpportunityLineItem>>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0		    SS		5/2/2017		Refer method header
    2.0         SS      6/5/2017        Added new fields to support Sridhar's request
    **********************************************************************************/
    private void getPrimaryQuote(String quoteId){
		sbqq_quote = [SELECT Id,
						 Name,
						 SBQQ__Opportunity2__c,
						 SBQQ__SalesRep__r.Name, 
						 SBQQ__BillingPostalCode__c,
						 Quote_Total_Selected_Currency__c,
						 CreatedDate,SBQQ__BillingState__c,
						 SBQQ__ShippingName__c,
						 SBQQ__BillingName__c,
						 SBQQ__BillingStreet__c,
						 SBQQ__BillingCity__c,
						 SBQQ__BillingCountry__c,
						 Selected_Currency__c,
						 SBQQ__DeliveryMethod__c,
						 SBQQ__PaymentTerms__c,
						 SBQQ__ExpirationDate__c,
						 SBQQ__ShippingPostalCode__c,
						 SBQQ__ShippingStreet__c,
						 SBQQ__ShippingState__c,
						 SBQQ__ShippingCity__c,
						 SBQQ__ShippingCountry__c,
						 SBQQ__SalesRep__c, 
                         X3P_Services_Costs__c,
                         Shipping_Handling_Costs__c,
                         SBQQ__StartDate__c,
						 SBQQ__SalesRep__r.Email,
                         Annual_Maintenance_AMC_Margin__c,
						 SBQQ__PrimaryContact__r.name,
						 SBQQ__PrimaryContact__r.Email, 
						 SBQQ__PrimaryContact__r.Phone, 
						 SBQQ__PrimaryContact__r.Fax,
						 SBQQ__PrimaryContact__c,
						 SBQQ__ListAmount__c,
						 SBQQ__NetAmount__c,
						 SBQQ__CustomerAmount__c,
                         SBQQ__Opportunity2__r.OLD_Incoterms__c,
                         End_User_City__c,
                         End_User_Country__c,
                         End_User_Name__c,
                         End_User_Zip__c,
                         End_User_State__c,
                         End_User_Street__c
					FROM SBQQ__Quote__c 
					WHERE ID=:(Id)quoteId];
    }
    /*************************************************************************************
    Method Name             fetchRelatedOpportunityProducts()
    Developed By            West Monroe Partners
    Purpose                 fetching the opportunity products related to the projects
    Created date            5/2/2017
    Parameters			    project id
    Output type		        map<String,list<OpportunityLineItem>>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0		SS		    5/2/2017		Refer method header
    2.0         SS      6/5/2017        Added new fields to support Sridhar's request
    **********************************************************************************/
    private void fetchRelatedOpportunityProducts(Id projectId){
	    list<Id> list_relatedIds = new  list<Id>();
	    String relatedQuoteId = '';
	    for(OpportunityLineItem iterating_lineItem : [ SELECT Id,
	    											   SBQQ__QuoteLine__c,
												   SBQQ__QuoteLine__r.SBQQ__Quote__c	  
											 FROM OpportunityLineItem
											 WHERE 
											 	Project__c =: projectId
	    									    ]){
			list_relatedIds.add(iterating_lineItem.SBQQ__QuoteLine__c);
			if(relatedQuoteId.length() == 0)
				relatedQuoteId = iterating_lineItem.SBQQ__QuoteLine__r.SBQQ__Quote__c;
	    }
	    //getting the values from the primary quote
	    System.debug('>>>>');
	    System.debug('>>>>' + relatedQuoteId);
	    if(relatedQuoteId.length() > 0)
	    		getPrimaryQuote(relatedQuoteId);
	   //Looping through the Quote line items
        for(SBQQ__QuoteLine__c iterating_quoteLine : [  SELECT
                                                            SBQQ__ProductCode__c,
                                                            SBQQ__Group__c,
                                                            SBQQ__Group__r.Name,
                                                            SBQQ__Group__r.SBQQ__Number__c,
                                                            SBQQ__Description__c,
                                                            SBQQ__Quantity__c,
                                                            Part_Category_Formula__c,
                                                            SBQQ__SubscriptionTerm__c,
                                                            QL_Unit_Price_Selected_Currency__c,
                                                            Additional_Disc_Selected_Currency__c,
                                                            Quote_Line_Total_Selected_Currency__c,
                                                            SBQQ__UnitCost__c,
						 									SBQQ__PackageCost__c,
	                                                       Generic_SKU__c 
                                                        FROM SBQQ__QuoteLine__c
                                                        WHERE
                                                            Id IN:list_relatedIds
                                                        ORDER BY SBQQ__Group__r.SBQQ__Number__c ASC
                                                     ]
        ){
            //No group exists
            if(iterating_quoteLine.SBQQ__Group__c == null){
                list_nonGroupedItems.add(iterating_quoteLine);
                bln_isGrouped = false;
            }else{
            	//Group exists
                //Check if the group is already added to the map
                if(map_groupToLineItemMapping.containsKey(iterating_quoteLine.SBQQ__Group__r.Name)){
                    //Already exist
                    //getting the list of line items to add the new line items
                    list<SBQQ__QuoteLine__c> list_SBQQQuoteLine = map_groupToLineItemMapping.get(iterating_quoteLine.SBQQ__Group__r.Name);
                    list_SBQQQuoteLine.add(iterating_quoteLine);
                    map_groupToLineItemMapping.put(iterating_quoteLine.SBQQ__Group__r.Name, list_SBQQQuoteLine);
                    //populating the totals of the groups
                    map_groupToTotals.put(iterating_quoteLine.SBQQ__Group__r.Name, map_groupToTotals.get(iterating_quoteLine.SBQQ__Group__r.Name) + iterating_quoteLine.Quote_Line_Total_Selected_Currency__c);
                }else{
                    //Group does not exist in the map
                     list<SBQQ__QuoteLine__c> list_SBQQQuoteLine = new list<SBQQ__QuoteLine__c>();
                     list_SBQQQuoteLine.add(iterating_quoteLine);
                     map_groupToLineItemMapping.put(iterating_quoteLine.SBQQ__Group__r.Name, list_SBQQQuoteLine);
                     map_groupToTotals.put(iterating_quoteLine.SBQQ__Group__r.Name, iterating_quoteLine.Quote_Line_Total_Selected_Currency__c);                    
                     list_quoteGroup.add(iterating_quoteLine.SBQQ__Group__r.Name);
                }
            }
        }
    }
    
}