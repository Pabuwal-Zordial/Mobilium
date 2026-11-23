public class ACV_Migration 
{

	/*
		ACV_Temp_Status__c
		
		'To Import'
		'Amount Saved'
		'Primary Quote Created'
		'Product Added'
		'Product Amount Changed'
		'Quote Calculated'
		'Quote Approved'
		'Process Completed'

		//SELECT ID FROM Opportunity WHERE ACV_Temp_Status__c = 'To Import'
		ACV_Migration.A_CopyAmountToTempField_BatchCall();
		ACV_Migration.A_CopyAmountToTempField();
		
		//SELECT ID, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Amount Saved'
		ACV_Migration.B_CreatePrimaryQuote_BatchCall();
		ACV_Migration.B_CreatePrimaryQuote();
		
		\//SELECT ID, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Primary Quote Created'
		ACV_Migration.C_createQuoteLineItens_BatchCall();
		ACV_Migration.C_createQuoteLineItens();
		
		//SELECT ID, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Product Added'
		ACV_Migration.D_updateQuoteLineItens_BatchCall();
		ACV_Migration.D_updateQuoteLineItens();
		
		//SELECT ID, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Product Amount Changed'
		ACV_Migration.D1_calculateQuoteLineItens_BatchCall()
		ACV_Migration.D1_calculateQuoteLineItens()

		//SELECT ID, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Quote Calculated'
		ACV_Migration.E_ApprovePrimaryQuote_BatchCall();
		ACV_Migration.E_ApprovePrimaryQuote();
		
		//SELECT ID, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Quote Approved'
		ACV_Migration.F_updateProjectRelatedToOpportunity_BatchCall();
		ACV_Migration.F_updateProjectRelatedToOpportunity();

		//SELECT ID, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'Process Completed'
	*/


	// Before running this method set ACV_Temp_Status to 'To Import' on opportunities that we want to import
	// This method will copy the field Amount to ACV_Temp_Amount__c and set ACV_Temp_Status__c to 'Amount Saved'
	public static void A_CopyAmountToTempField()
	{
		List<Opportunity> oppList = [SELECT Id, Amount, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE ACV_Temp_Status__c = 'To Import'];
		//List<Opportunity> oppList = [SELECT Id, Amount, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE Id = '0061K00000gmFs8QAE'];

		List<Opportunity> toUpdateList = new List<Opportunity> ();

		for (Opportunity opp : oppList)
		{
			opp.ACV_Temp_Amount__c = opp.Amount;
			opp.ACV_Temp_Status__c = 'Amount Saved';
			toUpdateList.add(opp);
		}

		update toUpdateList;
	}

	public static void A_CopyAmountToTempField_BatchCall()
	{
		Database.executeBatch(new AcvBulkUpdateBatch_A(), 1);
	}

	// This method will create primary quotes for opportunities that have the ACV_Temp_Status__c set to 'Amount Saved'
	// Creates the primary quote and updates ACV_Temp_Status__c to 'Primary Quote Created'
	public static void B_CreatePrimaryQuote()
	{
		List<Opportunity> oppList = [SELECT Id, Amount, ACV_Temp_Amount__c, ACV_Temp_Status__c, CloseDate FROM Opportunity WHERE ACV_Temp_Status__c = 'Amount Saved'];
		//List<Opportunity> oppList = [SELECT Id, CloseDate, ACV_Temp_Status__c FROM Opportunity WHERE Id = '0061K00000gmFs8QAE'];

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

	public static void B_CreatePrimaryQuote_BatchCall()
	{
		Database.executeBatch(new AcvBulkUpdateBatch_B(), 1);
	}

	// Creates a single quoteLineIem per Primary Quote depending on related Opportunity Business Unit
	// Updates the related opportunity field ACV_Temp_Status__c to 'Product Added'
	public static void C_createQuoteLineItens()
	{
		List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Business_Unit__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.ACV_Temp_Status__c = 'Primary Quote Created' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];
		//List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Business_Unit__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = '0061K00000gmFs8QAE' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];

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

				if(pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('ROAMING'))
				{
					genericProduct = '01t410000031LqmAAE'; //check
				}
				else if (pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('RISK'))
				{
					genericProduct = '01t1K000006HVCoQAO'; //check
				}
				else if (pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('SECURITY'))
				{
					genericProduct = '01t41000005HaeHAAS';
				}
				else if (pq.SBQQ__Opportunity2__r.Business_Unit__c.containsIgnoreCase('Testing'))
				{
					genericProduct = '01t1K000006I3YSQA0'; //check
				}
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


	public static void C_createQuoteLineItens_BatchCall()
	{
		Database.executeBatch(new AcvBulkUpdateBatch_C(), 1);
	}

	// Updates the created quoteLineIem with the Opportunity Amount
	// Updates the related opportunity field ACV_Temp_Status__c to 'Product Amount Changed'
	public static void D_updateQuoteLineItens()
	{
		List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c, SBQQ__Opportunity2__r.Conversion_Rate__c, SBQQ__Opportunity2__r.Currency_Table__r.Name FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.ACV_Temp_Status__c = 'Product Added' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];
		//List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = '0061K00000gmFs8QAE' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];
		
		List<Opportunity> toUpdateList = new List<Opportunity> ();

		for (SBQQ__Quote__c pq : primaryQuotes)
		{
			QuoteReader quoteReader = new QuoteReader();
			QuoteModel quoteModel = quoteReader.read(pq.Id);

			quoteModel.lineItems[0].record.Target_Local_Sales_Unit_Price__c = pq.SBQQ__Opportunity2__r.ACV_Temp_Amount__c / pq.SBQQ__Opportunity2__r.Conversion_Rate__c;

			QuoteSaver saver = new QuoteSaver();
			QuoteModel savedQuote = saver.save(quoteModel);

			// QuoteCalculator calculator = new QuoteCalculator();
			// calculator.calculate(quoteModel, 'MyCallback');

			Opportunity opp = new Opportunity(Id = pq.SBQQ__Opportunity2__c, ACV_Temp_Status__c = 'Quote Calculated');
			toUpdateList.add(opp);
		}
		update toUpdateList;
	}

	public static void D_updateQuoteLineItens_BatchCall()
	{
		Database.executeBatch(new AcvBulkUpdateBatch_D(), 1);
	}
/*
	public static void D1_calculateQuoteLineItens()
	{
		List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.ACV_Temp_Status__c = 'Product Amount Changed' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];
		//List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = '0061K00000gmFs8QAE' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];
		
		List<Opportunity> toUpdateList = new List<Opportunity> ();

		for (SBQQ__Quote__c pq : primaryQuotes)
		{
			QuoteReader quoteReader = new QuoteReader();
			QuoteModel quoteModel = quoteReader.read(pq.Id);

			QuoteCalculator calculator = new QuoteCalculator();
			calculator.calculate(quoteModel, 'MyCallback');

			Opportunity opp = new Opportunity(Id = pq.SBQQ__Opportunity2__c, ACV_Temp_Status__c = 'Quote Calculated');
			toUpdateList.add(opp);
		}
		update toUpdateList;
	}
	*/
	public static void D1_calculateQuoteLineItens_BatchCall()
	{
		Database.executeBatch(new AcvBulkUpdateBatch_D1(), 1);
	}

	
	// This method will update primary quotes to approved and Opportunity ACV_Temp_Status__c to 'Quote Approved'
	public static void E_ApprovePrimaryQuote()
	{
		List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Status__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.ACV_Temp_Status__c = 'Quote Calculated' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];
		//List<SBQQ__Quote__c> primaryQuotes = [SELECT ID, SBQQ__Opportunity2__c, SBQQ__Status__c, SBQQ__Opportunity2__r.ACV_Temp_Amount__c, SBQQ__Opportunity2__r.ACV_Temp_Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = '0061K00000ij0fPQAQ' AND SBQQ__Primary__c = false ORDER BY CreatedDate DESC];

		List<SBQQ__Quote__c> primaryQuotesToApprove = new List<SBQQ__Quote__c> ();
		List<Opportunity> toUpdateOpportunityList = new List<Opportunity> ();

		for (SBQQ__Quote__c pq : primaryQuotes)
		{
			pq.SBQQ__Status__c = 'Approved';
			pq.SBQQ__Primary__c = true;
			primaryQuotesToApprove.add(pq);
			toUpdateOpportunityList.add(new Opportunity(Id = pq.SBQQ__Opportunity2__c, ACV_Temp_Status__c = 'Quote Approved'));
		}
		update primaryQuotesToApprove;
		update toUpdateOpportunityList;
	}

	public static void E_ApprovePrimaryQuote_BatchCall()
	{
		Database.executeBatch(new AcvBulkUpdateBatch_E(), 1);
	}


	public static void F_updateProjectRelatedToOpportunity()
	{
		Map<Id, Opportunity> oppList = new Map<Id, Opportunity>([SELECT Id, Amount, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity  WHERE ACV_Temp_Status__c = 'Quote Approved']);
		//Map<Id, Opportunity> oppList = new Map<Id, Opportunity>([SELECT Id, Amount, ACV_Temp_Amount__c, ACV_Temp_Status__c FROM Opportunity WHERE Id = '0061K00000gmFs8QAE']);

		List<Project__c> existingProjects = [SELECT ID,
											Opportunity__c,
											PO_Date__c,
											Contract_Date__c,
											HW_delivery_Date__c, 
											RFA_Date__c,
											UAT_Date__c,
											Stability_Date__c,
											FA_Date__c,
											KPI_Date__c,
											Retention_Date__c,
											Opportunity__r.CloseDate
											FROM
											Project__c
											WHERE 
											Opportunity__c IN :oppList.keySet()
											ORDER BY CreatedDate ASC
										];

		Map<Id, Project__c> oppIdExistingProjectMap = new Map<Id, Project__c>();

		for(Project__c p : existingProjects)
		{
			if (p.Opportunity__c != null && !oppIdExistingProjectMap.containsKey(p.Opportunity__c))
			{
				oppIdExistingProjectMap.put(p.Opportunity__c, p);
			}
		}


		Set<Id> projectIdSet = new Set<Id>();

		for(Project__c p : oppIdExistingProjectMap.values())
		{
			p.PO_Date__c = p.Opportunity__r.CloseDate;
			p.Contract_Date__c =  p.Opportunity__r.CloseDate;
			p.HW_delivery_Date__c =  p.Opportunity__r.CloseDate;
			p.HW_Install_Date__c =  p.Opportunity__r.CloseDate;
			p.SW_delivery_Date__c =  p.Opportunity__r.CloseDate;
			p.RFA_Date__c =  p.Opportunity__r.CloseDate;
			p.UAT_Date__c =  p.Opportunity__r.CloseDate;
			p.Stability_Date__c =  p.Opportunity__r.CloseDate;
			p.FA_Date__c =  p.Opportunity__r.CloseDate;
			p.KPI_Date__c =  p.Opportunity__r.CloseDate;
			p.Retention_Date__c =  p.Opportunity__r.CloseDate;
			projectIdSet.add(p.Id);
		}

		List<Milestone__c> mList = [SELECT Id,PO__c, Contract__c FROM Milestone__c WHERE  project__c IN :projectIdSet];

		for(Milestone__c m :mList)
		{
			m.PO__c = 100;
		}

		update oppIdExistingProjectMap.values();
		update mList;

		List<Opportunity> listToUpdate = new List<Opportunity>();

		for (Opportunity opp : oppList.values())
		{
			listToUpdate.add(new Opportunity(Id = opp.Id, ACV_Temp_Status__c = 'Process Completed'));
		}
		update listToUpdate;
	}

	public static void F_updateProjectRelatedToOpportunity_BatchCall()
	{
		Database.executeBatch(new AcvBulkUpdateBatch_F(), 1);
	}
}

	// public class AsyncChangePrices implements Queueable {
		
	// 	public SBQQ__Quote__c primaryQuote ;
	// 	public Opportunity opp ;

	// 	public AsyncChangePrices(SBQQ__Quote__c primaryQuote, Opportunity opp)
	// 	{
	//    		this.primaryQuote = primaryQuote ;
	//    		this.opp = opp ;
	// 	}

	// 	public void execute(QueueableContext context) {

	// 		// String genericProduct = '';
	// 		// String genericPriceBook = '01s41000008bmbUAAQ';

	// 		// System.debug(opp.Business_Unit__c);

	// 		// if(opp.Business_Unit__c.containsIgnoreCase('ROAMING'))
	// 		// {
	// 		// 	genericProduct = '01t410000031LqmAAE';
	// 		// }
	// 		// else if (opp.Business_Unit__c.containsIgnoreCase('RISK'))
	// 		// {
	// 		// 	genericProduct = '01t410000031LqmAAE';
	// 		// }
	// 		// else if (opp.Business_Unit__c.containsIgnoreCase('SECURITY'))
	// 		// {
	// 		// 	genericProduct = '01t41000005HaeHAAS';
	// 		// }
	// 		// else if (opp.Business_Unit__c.containsIgnoreCase('Testing'))
	// 		// {
	// 		// 	genericProduct = '01t1K000006I3YSQA0';
	// 		// }

	// 		QuoteReader quoteReader = new QuoteReader();
	// 		QuoteModel quoteModel = quoteReader.read(primaryQuote.Id);

	// 		// ProductReader productReader = new ProductReader();
	// 		// ProductModel productModel = productReader.read(genericProduct, genericPriceBook,'USD');

	// 		// List<ProductModel> productModels = new List<ProductModel>();

	// 		// productModels.add(productModel);
	// 		// ProductAdder adder = new ProductAdder();
	// 		// adder.add(quoteModel, productModels, 0);
	// 		quoteModel.lineItems[0].record.Target_Local_Sales_Unit_Price__c = 100000;
	// 		QuoteCalculator calculator = new QuoteCalculator();
	// 		calculator.calculate(quoteModel, 'MyCallback');
	// 	}
	// }
	// @future
	// static void changePrices(Id quoteId, Decimal Amount)
	// {
	// 	QuoteReader quoteReader = new QuoteReader();
	// 	QuoteModel quoteModel = quoteReader.read(quoteId);
	// 	quoteModel.lineItems[0].record.Target_Local_Sales_Unit_Price__c = Amount;

	// 	QuoteCalculator calculator = new QuoteCalculator();
	// 	calculator.calculate(quoteModel, 'MyCallback');

	// 	//pq.SBQQ__Status__c = 'Approved';
	// 	//update pq;
	// }


/*

SBQQ__Quote__c pq = new SBQQ__Quote__c();
pq.SBQQ__Opportunity2__c = '0061K00000gmFs8QAE';
pq.SBQQ__Primary__c = true;
pq.SBQQ__StartDate__c= Date.Today();
insert pq;


QuoteReader quoteReader = new QuoteReader();
QuoteModel quoteModel = quoteReader.read('a0n8F0000008RiWQAU');

String genericProduct = '01t1K000006I3YSQA0';
String genericPriceBook = '01s41000008bmbUAAQ';
ProductReader productReader = new ProductReader();
ProductModel productModel = productReader.read(genericProduct, genericPriceBook,'USD');

List<ProductModel> productModels = new List<ProductModel>();

productModels.add(productModel);
ProductAdder adder = new ProductAdder();
quoteModel = adder.add(quoteModel, productModels, 0);

quoteModel.lineItems[0].record.Target_Local_Sales_Unit_Price__c = 1000;

QuoteCalculator calculator = new QuoteCalculator();
calculator.calculate(quoteModel, 'MyCallback');

*/