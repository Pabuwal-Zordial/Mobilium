@isTest
public class ACV_MigrationTest {
    @testSetup
    static void setupData() 
    {
        Opportunity opp = new Opportunity(
            ACV_Temp_Status__c = 'To Import',
            Amount = 101.00,
            Name = 'Test Opportunity',
            StageName = 'Validate the Opportunity',
            CloseDate = Date.newInstance(2000, 10, 10),
            Business_Unit__c = 'Security',
            Current_Quarter_Billing__c = 10,
            Cross_sell1__c = 'Cross sell',
            Security_Products__c = Opportunity.Security_Products__c.getDescribe().getPicklistValues()[0].getValue(),
            Type = 'POC-Proof of Concept',
            Total_Security_Forecast_QC__c = 101.00
        );

        insert opp;

        Product2 product = new Product2(
            Name = 'Testing Product 5', 
            Family = 'Implementation Services',
            Risk_BU_Product_Line__c = System.Label.Business_Operations
        );
        insert product;

        PricebookEntry pricebook = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = product.Id, 
            UnitPrice = 10000, 
            isActive = false 
        );
        insert pricebook;
    }

    @isTest
    private static void A_CopyAmountToTempFieldTest()
    {
        Test.startTest();
            ACV_Migration.A_CopyAmountToTempField();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Amount Saved');
    }

    @isTest
    private static void A_CopyAmountToTempField_BatchCallTest()
    {
        Test.startTest();
            ACV_Migration.A_CopyAmountToTempField_BatchCall();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Amount Saved');
    }

    @isTest
    private static void B_CreatePrimaryQuoteTest()
    {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Amount Saved';
        update opp;

        Test.startTest();
            ACV_Migration.B_CreatePrimaryQuote();
        Test.stopTest();

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.areEqual(quotes.size(), 1);
        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Primary Quote Created');
    }

    @isTest
    private static void B_CreatePrimaryQuote_BatchCallTest()
    {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Amount Saved';
        update opp;

        Test.startTest();
            ACV_Migration.B_CreatePrimaryQuote_BatchCall();
        Test.stopTest();

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.areEqual(quotes.size(), 1);
        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Primary Quote Created');
    }

    @isTest
    private static void C_createQuoteLineItensTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Primary Quote Created';
        update opp;

        createQuote(opp);

        Test.startTest();
            ACV_Migration.C_createQuoteLineItens();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Product Added');

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c];
        Assert.areEqual(quoteLines.size(), 1);
    }

    @isTest
    private static void C_createQuoteLineItens_BatchCallTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Primary Quote Created';
        update opp;

        createQuote(opp);

        Test.startTest();
            ACV_Migration.C_createQuoteLineItens_BatchCall();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Product Added');

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c];
        Assert.areEqual(quoteLines.size(), 1);
    }

    @isTest
    private static void D_updateQuoteLineItensTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Product Added';
        opp.ACV_Temp_Amount__c = 100;
        opp.Conversion_Rate__c = 10;
        update opp;

        SBQQ__Quote__c quote = createQuote(opp);
        createQuoteLineItem(quote);

        Test.startTest();
            ACV_Migration.D_updateQuoteLineItens();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Quote Calculated');

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Target_Local_Sales_Unit_Price__c FROM SBQQ__QuoteLine__c];
        Assert.areEqual(quoteLines.size(), 1);
        Assert.isTrue(quoteLines[0].Target_Local_Sales_Unit_Price__c > 0);
    }

    @isTest
    private static void D_updateQuoteLineItens_BatchCallTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Product Added';
        opp.ACV_Temp_Amount__c = 100;
        opp.Conversion_Rate__c = 10;
        update opp;

        SBQQ__Quote__c quote = createQuote(opp);
        createQuoteLineItem(quote);

        Test.startTest();
            ACV_Migration.D_updateQuoteLineItens_BatchCall();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Quote Calculated');

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Target_Local_Sales_Unit_Price__c FROM SBQQ__QuoteLine__c];
        Assert.areEqual(quoteLines.size(), 1);
        Assert.isTrue(quoteLines[0].Target_Local_Sales_Unit_Price__c > 0);
    }

    @isTest
    private static void D1_calculateQuoteLineItens_BatchCallTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Quote Calculated';
        opp.ACV_Temp_Amount__c = 100;
        opp.Conversion_Rate__c = 10;
        update opp;

        SBQQ__Quote__c quote = createQuote(opp);
        createQuoteLineItem(quote);

        Test.startTest();
            ACV_Migration.D1_calculateQuoteLineItens_BatchCall();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Quote Calculated');

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Target_Local_Sales_Unit_Price__c, SBQQ__NetTotal__c FROM SBQQ__QuoteLine__c];
        Assert.areEqual(quoteLines.size(), 1);
        Assert.isTrue(quoteLines[0].Target_Local_Sales_Unit_Price__c > 0);
    }

    @isTest
    private static void E_ApprovePrimaryQuoteTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Quote Calculated';
        opp.ACV_Temp_Amount__c = 100;
        opp.Conversion_Rate__c = 10;
        update opp;

        SBQQ__Quote__c quote = createQuote(opp);
        createQuoteLineItem(quote);

        Test.startTest();
            ACV_Migration.E_ApprovePrimaryQuote();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Quote Approved');

        List<SBQQ__Quote__c> quotes = [SELECT SBQQ__Status__c, SBQQ__Primary__c FROM SBQQ__Quote__c];
        Assert.areEqual(quotes.size(), 1);
        Assert.areEqual(quotes[0].SBQQ__Status__c, 'Approved');
        Assert.areEqual(quotes[0].SBQQ__Primary__c, true);
    }

    @isTest
    private static void E_ApprovePrimaryQuote_BatchCallTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Quote Calculated';
        opp.ACV_Temp_Amount__c = 100;
        opp.Conversion_Rate__c = 10;
        update opp;

        SBQQ__Quote__c quote = createQuote(opp);
        createQuoteLineItem(quote);

        Test.startTest();
            ACV_Migration.E_ApprovePrimaryQuote_BatchCall();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Quote Approved');

        List<SBQQ__Quote__c> quotes = [SELECT SBQQ__Status__c, SBQQ__Primary__c FROM SBQQ__Quote__c];
        Assert.areEqual(quotes.size(), 1);
        Assert.areEqual(quotes[0].SBQQ__Status__c, 'Approved');
        Assert.areEqual(quotes[0].SBQQ__Primary__c, true);
    }

    @isTest
    private static void F_updateProjectRelatedToOpportunityTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Quote Approved';
        update opp;

        Test.startTest();
            ACV_Migration.F_updateProjectRelatedToOpportunity();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Process Completed');

        List<Project__c> projects = [SELECT Id, PO_Date__c, Contract_Date__c, HW_delivery_Date__c, HW_Install_Date__c, SW_delivery_Date__c, RFA_Date__c, UAT_Date__c, Stability_Date__c, FA_Date__c, KPI_Date__c, Retention_Date__c FROM Project__c WHERE Opportunity__c = :opp.Id];
        Assert.areEqual(projects.size(), 1);
        Assert.areEqual(projects[0].PO_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].Contract_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].HW_delivery_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].HW_Install_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].SW_delivery_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].RFA_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].UAT_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].Stability_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].FA_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].KPI_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].Retention_Date__c, opp.CloseDate);

        List<Milestone__c> milestones = [SELECT Id, PO__c, Contract__c FROM Milestone__c WHERE Project__c IN :projects];
        Assert.isTrue(milestones.size() > 0);
        for(Milestone__c milestone: milestones) {
            Assert.areEqual(milestone.PO__c, 100);
        }
    }

    @isTest
    private static void F_updateProjectRelatedToOpportunity_BatchCallTest()
    {
        Opportunity opp = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        opp.ACV_Temp_Status__c = 'Quote Approved';
        update opp;

        Test.startTest();
            ACV_Migration.F_updateProjectRelatedToOpportunity_BatchCall();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, ACV_Temp_Amount__c, ACV_Temp_Status__c, Amount FROM Opportunity];
        Assert.areEqual(opps.size(), 1);
        Assert.areEqual(opps[0].ACV_Temp_Status__c, 'Process Completed');

        List<Project__c> projects = [SELECT Id, PO_Date__c, Contract_Date__c, HW_delivery_Date__c, HW_Install_Date__c, SW_delivery_Date__c, RFA_Date__c, UAT_Date__c, Stability_Date__c, FA_Date__c, KPI_Date__c, Retention_Date__c FROM Project__c WHERE Opportunity__c = :opp.Id];
        Assert.areEqual(projects.size(), 1);
        Assert.areEqual(projects[0].PO_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].Contract_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].HW_delivery_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].HW_Install_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].SW_delivery_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].RFA_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].UAT_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].Stability_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].FA_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].KPI_Date__c, opp.CloseDate);
        Assert.areEqual(projects[0].Retention_Date__c, opp.CloseDate);

        List<Milestone__c> milestones = [SELECT Id, PO__c, Contract__c FROM Milestone__c WHERE Project__c IN :projects];
        Assert.isTrue(milestones.size() > 0);
        for(Milestone__c milestone: milestones) {
            Assert.areEqual(milestone.PO__c, 100);
        }
    }

    private static SBQQ__Quote__c createQuote(Opportunity opp) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = false;
        quote.SBQQ__StartDate__c = opp.CloseDate;
        insert quote;
        return quote;
    }

    private static SBQQ__QuoteLine__c createQuoteLineItem(SBQQ__Quote__c quote) {
        SBQQ__QuoteLine__c quoteLineItem = new SBQQ__QuoteLine__c(
            Target_Local_Sales_Unit_Price__c = 101.00,
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id
        );
        insert quoteLineItem;
        return quoteLineItem;
    }
}