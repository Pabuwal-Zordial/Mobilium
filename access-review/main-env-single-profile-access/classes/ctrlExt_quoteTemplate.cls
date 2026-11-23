/*************************************************************************************
Name                    ctrlExt_quoteTemplate
Developed By            West Monroe Partners
Purpose                 Refer individual method headers
Created date            3/16/2017
*************************************************************************************/
public class ctrlExt_quoteTemplate {

	private final sObject mysObject;
    public Quote_template__mdt quoteTemplate {get; set;}
    public Integer newQuoteDocumentVersion{get; set;}
    public map<String,list<SBQQ__QuoteLine__c>> map_groupToLineItemMapping{get; set;}
    public list<SBQQ__QuoteLine__c> list_nonGroupedItems{get; set;}
    public map<String, Double> map_groupToTotals{get; set;}
    public Boolean bln_isGrouped{get; set;}
    public String str_documentTempName{get; set;}
    public SBQQ__Quote__c sbqq_quote{get; set;}
    public list<String> list_quoteGroup{get; set;}
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public ctrlExt_quoteTemplate(ApexPages.StandardController stdController) {

        //The running quote ID
        sbqq_quote = new SBQQ__Quote__c();
        this.mysObject = (sObject)stdController.getRecord();
        quoteTemplate = new Quote_template__mdt();
        newQuoteDocumentVersion = 1;
        map_groupToLineItemMapping = new map<String,list<SBQQ__QuoteLine__c>>();
        list_nonGroupedItems  = new list<SBQQ__QuoteLine__c>();
        map_groupToTotals   = new map<String, Double>();
        bln_isGrouped = true;
        str_documentTempName = '';
        list_quoteGroup = new list<String>();
        Datetime dt = System.now();
        //getting the quote
        sbqq_quote = [SELECT Id,Name,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.OLD_Incoterms__c,SBQQ__SalesRep__r.Name, SBQQ__BillingPostalCode__c, Quote_Total_Selected_Currency__c,CreatedDate,SBQQ__BillingState__c,SBQQ__ShippingName__c,SBQQ__BillingName__c,SBQQ__BillingStreet__c,SBQQ__BillingCity__c,SBQQ__BillingCountry__c,Selected_Currency__c,SBQQ__DeliveryMethod__c,SBQQ__PaymentTerms__c,SBQQ__ExpirationDate__c,SBQQ__ShippingPostalCode__c,SBQQ__ShippingStreet__c,SBQQ__ShippingState__c,SBQQ__ShippingCity__c,SBQQ__ShippingCountry__c,SBQQ__SalesRep__c, SBQQ__SalesRep__r.Email,SBQQ__PrimaryContact__r.name,SBQQ__PrimaryContact__r.Email, SBQQ__PrimaryContact__r.Phone, SBQQ__PrimaryContact__r.Fax,SBQQ__PrimaryContact__c,SBQQ__ListAmount__c,SBQQ__NetAmount__c,SBQQ__CustomerAmount__c FROM SBQQ__Quote__c WHERE ID=:(Id)mysObject.get('Id')];
        //Concatenate the quote number with date and time
        str_documentTempName = sbqq_quote.name + '-' + dt.format('yyyyMMdd-HHmm');
        
        //getting the values from custom setting
        getQuoteTemplateCustomMetadata();
       //Getting the list of quote documents
       list<SBQQ__QuoteDocument__c> list_quoteDocument = new list<SBQQ__QuoteDocument__c>();
       //query the quote document
       list_quoteDocument = getQuoteDocument((Id)mysObject.get('Id'));
       //If document is present
       if(!list_quoteDocument.isEmpty()){
            newQuoteDocumentVersion = ((Integer)list_quoteDocument[0].SBQQ__Version__c + 1);
       }
       //query to get the line items related to the quote
       getAndPrepQuoteLineItems((Id)mysObject.get('Id'));
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
    Method Name             getQuoteDocument()
    Developed By            West Monroe Partners
    Purpose                 fetching the quote document for the running quote
    Created date            3/16/2017
	Parameters				N/A
	Output type				list<SBQQ__QuoteDocument__c>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/16/2017		Refer method header
    **********************************************************************************/
    private list<SBQQ__QuoteDocument__c> getQuoteDocument(Id quoteID){
        //list to send back to the controller
        list<SBQQ__QuoteDocument__c> list_SBQQQuoteDocument = new list<SBQQ__QuoteDocument__c>();

        //Querying the quote documents related to the running quote
        for(SBQQ__QuoteDocument__c iterating_doc :    [ SELECT
                                                            Id,
                                                            SBQQ__Version__c,
                                                            SBQQ__Quote__c
                                                        FROM 
                                                            SBQQ__QuoteDocument__c
                                                        WHERE
                                                            SBQQ__Quote__c =: quoteID
                                                        ORDER BY
                                                            SBQQ__Version__c DESC
                                                      ]
        ){
            list_SBQQQuoteDocument.add(iterating_doc);
        }

        return list_SBQQQuoteDocument;
    }
    /*************************************************************************************
    Method Name             getAndPrepQuoteLineItems()
    Developed By            West Monroe Partners
    Purpose                 fetching the quote line items for the running quote and prep them
    Created date            3/16/2017
	Parameters				N/A
	Output type             N/A
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/16/2017		Refer method header
    **********************************************************************************/
    private void getAndPrepQuoteLineItems(Id quoteID){

        //Looping through the Quote line items
        for(SBQQ__QuoteLine__c iterating_quoteLine : [  SELECT
                                                            SBQQ__ProductCode__c,
                                                            SBQQ__Group__c,
                                                            SBQQ__Group__r.Name,
                                                            SBQQ__Group__r.SBQQ__Number__c,
                                                            SBQQ__Description__c,
                                                            SBQQ__Quantity__c,
                                                            QL_Unit_Price_Selected_Currency__c,
                                                            Additional_Disc_Selected_Currency__c,
                                                            Quote_Line_Total_Selected_Currency__c,
                                                            SBQQ__PackageCost__c,
                                                            Gross_Profit_local_currency__c,
                                                            Package_Cost_local_Currency__c,
                                                            SBQQ__SubscriptionTerm__c,
                                                            SBQQ__EffectiveStartDate__c,
                                                            Gross_Profit2__c,
                                                            Gross_Profit_percentage__c
                                                        FROM SBQQ__QuoteLine__c
                                                        WHERE
                                                            SBQQ__Quote__c =:quoteID
                                                        ORDER BY SBQQ__Group__r.SBQQ__Number__c ASC
                                                     ]
        ){
            //No group exists
            if(iterating_quoteLine.SBQQ__Group__c == null){
                list_nonGroupedItems.add(iterating_quoteLine);
                bln_isGrouped = false;
            }else{//Group exists
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
    /*************************************************************************************
    Method Name             saveQuote()
    Developed By            West Monroe Partners
    Purpose                 ensuring that the template is saved in the document folder and the ID
                            is used to store the quote document
    Created date            3/21/2017
	Parameters				N/A
	Output type             N/A
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/21/2017		Refer method header
    **********************************************************************************/
    private string saveQuote(){
        try{
            //Saving the document
            Document instance_document = new Document();
            instance_document.folderId = Userinfo.getUserId();
            instance_document.name     = str_documentTempName+'.pdf';
            //Setting the blob contents of the file
            Blob body ; 
            ApexPages.PageReference pagePdf = new ApexPages.PageReference('/apex/vf_quoteTemplate'); 
            pagePdf.getParameters().put('id', sbqq_quote.id);
            pagePdf.setredirect(true);
            System.debug(pagePdf); 
            if(!Test.isRunningTest())
                body =  pagePdf.getContent();
            else    
                body = blob.valueOf('Unit Test');
            System.debug(body); 
            instance_document.IsPublic = false;
            instance_document.Type = 'pdf';
            instance_document.contentType = 'application/pdf';
            instance_document.body = body;
            System.debug('&&&&&&&&&&&&&&&&&&&&& >> ' + EncodingUtil.base64Encode(body));
            //instance_document.body     = EncodingUtil.base64Decode(EncodingUtil.base64Encode(body));
            System.debug('&&&&&&&&&&&&&&&&&&&&& >> ' + body);
            
            insert instance_document;
            //Inserting Quote document object
            String msg = saveQuoteDocument((String)instance_document.id);
            return (String)msg;
        }catch(Exception e){
           return e.getMessage();
        }
    }
    /*************************************************************************************
    Method Name             saveQuoteDocument()
    Developed By            West Monroe Partners
    Purpose                 ensuring that the template is saved in the document folder and the ID
                            is used to store the quote document
    Created date            3/21/2017
	Parameters				Document Id
	Output type             N/A
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/21/2017		Refer method header
    **********************************************************************************/
    private string saveQuoteDocument(string documentId){
        //Saving the quote document
        SBQQ__QuoteDocument__c inst_quoteDocument = new SBQQ__QuoteDocument__c();
        try{
            inst_quoteDocument.SBQQ__DocumentId__c = documentId;
            //inst_quoteDocument.SBQQ__ViewRecordId__c = documentId;
            inst_quoteDocument.SBQQ__Version__c      = newQuoteDocumentVersion;
            //inst_quoteDocument.SBQQ__Template__c     = 'Mobileum Quote Template';
            inst_quoteDocument.SBQQ__Quote__c        = sbqq_quote.Id;
            inst_quoteDocument.SBQQ__Opportunity__c  = sbqq_quote.SBQQ__Opportunity2__c;
            inst_quoteDocument.SBQQ__OutputFormat__c = 'PDF';
            inst_quoteDocument.SBQQ__ListAmount__c   = sbqq_quote.SBQQ__ListAmount__c;
            inst_quoteDocument.SBQQ__NetAmount__c   = sbqq_quote.SBQQ__NetAmount__c;
            inst_quoteDocument.SBQQ__CustomerAmount__c   = sbqq_quote.SBQQ__CustomerAmount__c;
            inst_quoteDocument.Name                        = str_documentTempName;
            inst_quoteDocument.SBQQ__Key__c                = sbqq_quote.Id+'_'+newQuoteDocumentVersion;
         
            insert inst_quoteDocument;
            return (String)inst_quoteDocument.Id;
        }catch(Exception e){
            return e.getMessage();
        }
    }
    /*************************************************************************************
    Method Name             saveMethod()
    Developed By            West Monroe Partners
    Purpose                 save method accessed from the page
    Created date            3/21/2017
	Parameters				Document Id
	Output type             N/A
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/21/2017		Refer method header
    **********************************************************************************/
    public PageReference saveMethod(){
        String msgFrmMethod = saveQuote();
        PageReference myVFPage;
        if(msgFrmMethod.length() == 18){
            myVFPage = new PageReference('/'+(Id)mysObject.get('Id'));
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,msgFrmMethod));
        }

        return myVFPage;
    }

    /*************************************************************************************
    Method Name             saveEmailMethod()
    Developed By            West Monroe Partners
    Purpose                 save method accessed from the page
    Created date            3/21/2017
	Parameters				Document Id
	Output type             N/A
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/21/2017		Refer method header
    **********************************************************************************/
    public PageReference saveEmailMethod(){
        String msgFrmMethod = saveQuote();
        PageReference myVFPage;
        if(msgFrmMethod.length() == 18){
            //myVFPage = new PageReference('/_ui/core/email/author/EmailAuthor?rtype=003&isdtp=vw&core.apexpages.devmode.url=1&doc_id='+msgFrmMethod+'&p3_lkid='+sbqq_quote.SBQQ__Opportunity2__c +'&p2_lkid='+sbqq_quote.SBQQ__PrimaryContact__c+'&retURL='+sbqq_quote.id);
            myVFPage = new PageReference('/apex/SBQQ__EmailDocument?id='+msgFrmMethod);
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,msgFrmMethod));
        }
        myVFPage.getParameters().put('isdtp','vw');
        myVFPage.setRedirect(true);
        return myVFPage;
    }
     /*************************************************************************************
    Method Name             quoteRedirect()
    Developed By            West Monroe Partners
    Purpose                 save method accessed from the page
    Created date            3/21/2017
	Parameters				Document Id
	Output type             N/A
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		3/21/2017		Refer method header
    **********************************************************************************/
    public Pagereference quoteRedirect(){
        PageReference myVFPage;
        myVFPage = new PageReference('/'+(Id)mysObject.get('Id'));
         return myVFPage;
    }
}