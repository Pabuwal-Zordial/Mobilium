/*************************************************************************************
Name                    clsHandler_multicurrency
Developed By            West Monroe Partners
Purpose                 The following are the requirements for the trigger handler
                            * On Opportunity closure, should multiply the conversion factor
                            for Quote line fields of the primary quote
Created date            4/26/2017
History
------------------------------------------------------------------------------------
VERSION  	AUTHOR 	DATE      		DETAIL
1.0			SS		4/25/2017		Refer class header
*************************************************************************************/
public class clsHandler_multicurrency {
    public static boolean bln_multicurrency_executed = false;
    /*************************************************************************************
    Method Name             processMultiCurrency
    Developed By            West Monroe Partners
    Purpose                 * For the opporutnity do the following:
								* Fetch the currency of the record
                                    * If USD - Ignore
                                    * If not - fetch the currency record and the conversion rate
                                * Fetch the primary quote of the opportunity
                                * Fetch the quote lines of the primary quote
                                * Multiply the following fields with the conversion factor
                                    * SBQQ__NetTotal__c
                                    * SBQQ__AdditionalDiscount__c
                                    * SBQQ__RegularPrice__c
    Created date            4/25/2017
	Parameters				list<Opportunity> - the list of opportunity IDs from the trigger
							that have been updated
                            list<Opportunity> - the list of opportunity IDs from the trigger
							that have the old values before update
    Important note          Logic doesnt require to handle bulk
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		4/25/2017		Refer method header
    *************************************************************************************/
    public void processMultiCurrency(list<Opportunity> list_Opportunity_afterUpdate,
                                     map<Id,Opportunity> map_Opportunity_beforeUpdate
                                    ){

        if(!bln_multicurrency_executed){
            //list of quote lines to update
            list<SBQQ__QuoteLine__c> list_updateQuoteLine = new list<SBQQ__QuoteLine__c>();
            //the list of opportunity that needs processing
            list<Opportunity> list_toProcessOpportunity = new list<Opportunity>();

            //looping through the trigger.new list
            for(Opportunity iterating_newOpportunity : list_Opportunity_afterUpdate){
                if((
                        map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).Total_POs_Achieved__c == 0
                        &&
                        iterating_newOpportunity.Total_POs_Achieved__c == 1
                )
                ||
                (
                    iterating_newOpportunity.Total_POs_Achieved__c > 0
                    &&
                    map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).SBQQ__PrimaryQuote__c != iterating_newOpportunity.SBQQ__PrimaryQuote__c
                )
                ){
                    //check the currency on the record
                    //if USD ignore
                    if(iterating_newOpportunity.Currency_Table__c != Label.Default_Currency){
                        //The running currency is not USD
                        //Hence adding to the list
                        list_toProcessOpportunity.add(iterating_newOpportunity);
                    }
                }
            }

            //checking if we have to deal with opporutnities as per condition
            if(!list_toProcessOpportunity.isEmpty()){

                map<Id,Currency_table__c> map_currencyMaster = new map<Id, Currency_Table__c>();
                map<Id,SBQQ__Quote__c> map_primaryQuoteMaster = new map<Id, SBQQ__Quote__c>();

                //calling the method to fetch all currency values
                map_currencyMaster = fetchCurrencyMaster();

                //get primary quote and quote line items of the opportunity
                map_primaryQuoteMaster = fetchPrimaryQuoteAndLineItems(list_toProcessOpportunity);

                //iterating through the list of quotes and modifying the list price
                for(SBQQ__Quote__c iterating_quote : map_primaryQuoteMaster.values()){
                    //iterating through the list of quote line items
                    for(SBQQ__QuoteLine__c iterating_quoteLine : iterating_quote.SBQQ__LineItems__r){
                        System.debug('>>>>>>>>>' + iterating_quoteLine.Quote_Line_Total_Selected_Currency__c);
                        System.debug('>>>>>>>>>' + iterating_quoteLine.SBQQ__ListPrice__c);
                        System.debug('>>>>>>>>>' + map_currencyMaster.get(iterating_quote.SBQQ__Opportunity2__r.Currency_table__c));
                        if(
                            iterating_quoteLine.SBQQ__ListPrice__c != null
                            &&
                            map_currencyMaster.get(iterating_quote.SBQQ__Opportunity2__r.Currency_table__c).Conversion_Rate__c != null
                            &&
                            map_currencyMaster.get(iterating_quote.SBQQ__Opportunity2__r.Currency_table__c).Conversion_Rate__c != 0
                        ){
                            if(iterating_quoteLine.SBQQ__Product__r.SBQQ__PricingMethod__c == 'Cost'){
                                Double tempNew =  iterating_quoteLine.Quote_Line_List_price_prior__c * (1/map_currencyMaster.get(iterating_quote.SBQQ__Opportunity2__r.Currency_table__c).Conversion_Rate__c);
                                System.debug('Prior ' +  iterating_quoteLine.Quote_Line_List_price_prior__c);
                                System.debug('Conversion factor' +  iterating_quoteLine.Quote_Line_List_price_prior__c);
                                System.debug('temp ' +  tempNew);
                                System.debug('old markup ' +  iterating_quoteLine.SBQQ__MarkupRate__c);
                                if(iterating_quoteLine.SBQQ__UnitCost__c > 0 ) {
                                  iterating_quoteLine.SBQQ__MarkupRate__c = ((tempNew - iterating_quoteLine.SBQQ__UnitCost__c)/iterating_quoteLine.SBQQ__UnitCost__c)* 100;
                                }
                                System.debug('new markup ' +  iterating_quoteLine.SBQQ__MarkupRate__c);
                            }else
							{
								if (iterating_quoteLine.Quote_Line_List_price_prior__c != null)
								{
                                	iterating_quoteLine.SBQQ__ListPrice__c = iterating_quoteLine.Quote_Line_List_price_prior__c * (1/map_currencyMaster.get(iterating_quote.SBQQ__Opportunity2__r.Currency_table__c).Conversion_Rate__c);
								}
							}
                            list_updateQuoteLine.add(iterating_quoteLine);
                            System.debug('>>>>>>>>>' + iterating_quoteLine.Quote_Line_Total_Selected_Currency__c);
                            System.debug('>>>>>>>>>' + iterating_quoteLine.SBQQ__ListPrice__c);
                            System.debug('>>>>>>>>>' + map_currencyMaster.get(iterating_quote.SBQQ__Opportunity2__r.Currency_table__c));
                        }
                    }
                }

                //checking if the list is not empty
                if(!list_updateQuoteLine.isEmpty()){
                    update list_updateQuoteLine;
                    bln_multicurrency_executed = true;
                }
            }
        }
    }

    /*************************************************************************************
    Method Name             fetchPrimaryQuoteAndLineItems
    Developed By            West Monroe Partners
    Purpose                 * Fetch all line items and the primary quote of the given
                            opportunity
    Created date            4/26/2017
    Parameters              list<Opportunity>
    Output type				map<Id, SBQQ__Quote__c>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		4/26/2017		Refer method header
    *************************************************************************************/
    private map<Id,SBQQ__Quote__c> fetchPrimaryQuoteAndLineItems(list<Opportunity> list_toProcessOpportunity){

        map<Id,SBQQ__Quote__c> map_oppWithPrimaryQuoteAndLines = new map<Id,SBQQ__Quote__c>();
        //fetch the primary quote of the related opporutnities
        for(SBQQ__Quote__c iterating_quote : [ SELECT
                                                    Id,
                                                    SBQQ__Opportunity2__c,
                                                    SBQQ__Opportunity2__r.Currency_table__c,
                                                    (SELECT
                                                            Id,
                                                            SBQQ__Quote__c,
                                                            SBQQ__Product__r.SBQQ__PricingMethod__c,
                                                            SBQQ__ListPrice__c,
                                                            SBQQ__MarkupAmount__c,
                                                            Quote_Line_List_price_prior__c,
                                                            SBQQ__UnitCost__c,
                                                            SBQQ__MarkupRate__c,
                                                            Quote_Line_Total_Selected_Currency__c,
                                                            SBQQ__NetTotal__c
                                                     FROM
                                                            SBQQ__LineItems__r
                                                    )
                                                FROM
                                                    SBQQ__Quote__c
                                                WHERE
                                                    SBQQ__Opportunity2__c IN:list_toProcessOpportunity
                                             ]
        ){
            map_oppWithPrimaryQuoteAndLines.put(iterating_quote.SBQQ__Opportunity2__c, iterating_quote);
        }

        return map_oppWithPrimaryQuoteAndLines;
    }

    /*************************************************************************************
    Method Name             fetchCurrencyMaster
    Developed By            West Monroe Partners
    Purpose                 * Fetch all currency master and return a map of id and currency
                              master records
    Created date            4/26/2017
    Parameters              none
    Output type				map<Id, Currency_table__c>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		4/26/2017		Refer method header
    *************************************************************************************/
    private map<Id,Currency_Table__c> fetchCurrencyMaster(){
        //variables required for the class
        map<Id, Currency_Table__c> map_currencyMaster = new map<Id, Currency_Table__c>();

        //querying the table
        for(Currency_Table__c iterating_currency : [ SELECT
                                                          Id,
                                                          Name,
                                                          Conversion_Rate__c
                                                     FROM
                                                          Currency_Table__c
                                                   ]
        ){
            map_currencyMaster.put(iterating_currency.Id, iterating_currency);
        }

        return map_currencyMaster;
    }
}