/**
 * @description Controller for the White Space Heat Grid Lightning Web Component.
 * Supports both Portfolio Mode (Executive Matrix) and Single Account Plan Mode.
 */
public without sharing class WhiteSpaceHeatMapController {

    public class HeatMapResponse {
        @AuraEnabled public List<OfferingHeader> offerings { get; set; }
        @AuraEnabled public List<AccountPlanRow> rows { get; set; }
        @AuraEnabled public List<String> fiscalYears { get; set; }
        @AuraEnabled public String selectedFiscalYear { get; set; }
        @AuraEnabled public SummaryKPIs kpis { get; set; }
        @AuraEnabled public Boolean isSinglePlanMode { get; set; }
    }

    public class OfferingHeader {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String code { get; set; }
        @AuraEnabled public String productFamily { get; set; }
        @AuraEnabled public Decimal sortOrder { get; set; }
        @AuraEnabled public Decimal totalOurSpend { get; set; }
        @AuraEnabled public Decimal totalWhiteSpace { get; set; }
    }

    public class AccountPlanRow {
        @AuraEnabled public String planId { get; set; }
        @AuraEnabled public String planName { get; set; }
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String fiscalYear { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal ourRevenue { get; set; }
        @AuraEnabled public Decimal totalWhiteSpace { get; set; }
        @AuraEnabled public Decimal totalCustomerSpend { get; set; }
        @AuraEnabled public Decimal shareOfWallet { get; set; }
        @AuraEnabled public Decimal openPipeline { get; set; }
        @AuraEnabled public Decimal closedWonRevenue { get; set; }
        @AuraEnabled public List<AssessmentCell> cells { get; set; }
    }

    public class AssessmentCell {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String planId { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String offeringId { get; set; }
        @AuraEnabled public String offeringName { get; set; }
        @AuraEnabled public String offeringCode { get; set; }
        @AuraEnabled public Decimal ourSpend { get; set; }
        @AuraEnabled public Decimal competitorSpend { get; set; }
        @AuraEnabled public Decimal internalSpend { get; set; }
        @AuraEnabled public Decimal unknownSpend { get; set; }
        @AuraEnabled public Decimal totalCustomerSpend { get; set; }
        @AuraEnabled public Decimal whiteSpaceValue { get; set; }
        @AuraEnabled public Decimal shareOfWallet { get; set; }
        @AuraEnabled public String statusBadge { get; set; }
        @AuraEnabled public String statusLabel { get; set; }
        @AuraEnabled public String badgeClass { get; set; }
        @AuraEnabled public String comments { get; set; }
    }

    public class SummaryKPIs {
        @AuraEnabled public Integer totalPlans { get; set; }
        @AuraEnabled public Decimal totalOurRevenue { get; set; }
        @AuraEnabled public Decimal totalWhiteSpace { get; set; }
        @AuraEnabled public Decimal totalCustomerSpend { get; set; }
        @AuraEnabled public Decimal avgShareOfWallet { get; set; }
        @AuraEnabled public Decimal totalOpenPipeline { get; set; }
    }

    /**
     * @description Retrieves the 2D Heat Map dataset for portfolio or single account plan view.
     * Note: Not cacheable to guarantee live updates on refresh and spend edits.
     */
    @AuraEnabled
    public static HeatMapResponse getHeatMapData(Id accountPlanId, String fiscalYear) {
        HeatMapResponse response = new HeatMapResponse();
        response.offerings = new List<OfferingHeader>();
        response.rows = new List<AccountPlanRow>();
        response.fiscalYears = new List<String>();
        response.kpis = new SummaryKPIs();
        response.isSinglePlanMode = (accountPlanId != null);

        // 1. Fetch available Fiscal Years from Account Plans
        Set<String> fySet = new Set<String>();
        for (AggregateResult ar : [SELECT Fiscal_Year__c fy FROM Account_Plan__c WHERE Fiscal_Year__c != null GROUP BY Fiscal_Year__c ORDER BY Fiscal_Year__c DESC]) {
            String fy = (String) ar.get('fy');
            fySet.add(fy);
            response.fiscalYears.add(fy);
        }

        // Determine default fiscal year if not passed
        if (String.isBlank(fiscalYear)) {
            if (response.fiscalYears.contains('FY2027')) {
                fiscalYear = 'FY2027';
            } else if (!response.fiscalYears.isEmpty()) {
                fiscalYear = response.fiscalYears[0];
            } else {
                fiscalYear = 'FY2027';
            }
        }
        response.selectedFiscalYear = fiscalYear;

        // 2. Fetch Active Offerings
        List<Offering__c> activeOfferings = [
            SELECT Id, Name, Offering_Code__c, Product_Family__c, Sort_Order__c
            FROM Offering__c
            WHERE Active__c = true
            ORDER BY Sort_Order__c ASC NULLS LAST, Name ASC
        ];

        Map<Id, OfferingHeader> offeringHeaderMap = new Map<Id, OfferingHeader>();
        for (Offering__c off : activeOfferings) {
            OfferingHeader header = new OfferingHeader();
            header.id = off.Id;
            header.name = off.Name;
            header.code = off.Offering_Code__c;
            header.productFamily = off.Product_Family__c;
            header.sortOrder = off.Sort_Order__c != null ? off.Sort_Order__c : 0;
            header.totalOurSpend = 0;
            header.totalWhiteSpace = 0;
            response.offerings.add(header);
            offeringHeaderMap.put(off.Id, header);
        }

        // 3. Fetch Account Plans (filtered by single ID or Fiscal Year)
        List<Account_Plan__c> plans;
        if (accountPlanId != null) {
            plans = [
                SELECT Id, Name, Account__c, Account__r.Name, Fiscal_Year__c, Status__c,
                       Our_Revenue__c, Total_White_Space__c, Total_Customer_Spend__c,
                       Share_of_Wallet__c, Open_Pipeline_Value__c, Closed_Won_Revenue__c
                FROM Account_Plan__c
                WHERE Id = :accountPlanId
                LIMIT 1
            ];
            if (!plans.isEmpty()) {
                response.selectedFiscalYear = plans[0].Fiscal_Year__c;
            }
        } else {
            plans = [
                SELECT Id, Name, Account__c, Account__r.Name, Fiscal_Year__c, Status__c,
                       Our_Revenue__c, Total_White_Space__c, Total_Customer_Spend__c,
                       Share_of_Wallet__c, Open_Pipeline_Value__c, Closed_Won_Revenue__c
                FROM Account_Plan__c
                WHERE Fiscal_Year__c = :fiscalYear
                ORDER BY Account__r.Name ASC NULLS LAST
            ];
        }

        if (plans.isEmpty()) {
            response.kpis.totalPlans = 0;
            response.kpis.totalOurRevenue = 0;
            response.kpis.totalWhiteSpace = 0;
            response.kpis.totalCustomerSpend = 0;
            response.kpis.avgShareOfWallet = 0;
            response.kpis.totalOpenPipeline = 0;
            return response;
        }

        Set<Id> planIds = (new Map<Id, Account_Plan__c>(plans)).keySet();

        // 4. Fetch White Space Assessments for these plans
        List<White_Space_Assessment__c> assessments = [
            SELECT Id, Name, Account_Plan__c, Account_Plan__r.Account__r.Name,
                   Offering__c, Offering__r.Name, Offering__r.Offering_Code__c,
                   Our_Spending__c, Competitor_Spending__c, Internal_Spending__c, Unknown_Spending__c,
                   Total_Customer_Spending__c, White_Space_Value__c, Share_of_Wallet__c,
                   Status__c, Comments__c
            FROM White_Space_Assessment__c
            WHERE Account_Plan__c IN :planIds
        ];

        // Group assessments by PlanId -> OfferingId
        Map<Id, Map<Id, White_Space_Assessment__c>> planOfferingMap = new Map<Id, Map<Id, White_Space_Assessment__c>>();
        for (White_Space_Assessment__c wsa : assessments) {
            if (!planOfferingMap.containsKey(wsa.Account_Plan__c)) {
                planOfferingMap.put(wsa.Account_Plan__c, new Map<Id, White_Space_Assessment__c>());
            }
            planOfferingMap.get(wsa.Account_Plan__c).put(wsa.Offering__c, wsa);
        }

        // 5. Build Grid Rows & Populate KPIs
        Decimal totalOurRev = 0;
        Decimal totalWS = 0;
        Decimal totalCustSpend = 0;
        Decimal totalOpenPip = 0;
        Decimal sumShareOfWallet = 0;

        for (Account_Plan__c plan : plans) {
            AccountPlanRow row = new AccountPlanRow();
            row.planId = plan.Id;
            row.planName = plan.Name;
            row.accountId = plan.Account__c;
            row.accountName = plan.Account__r != null ? plan.Account__r.Name : plan.Name;
            row.fiscalYear = plan.Fiscal_Year__c;
            row.status = plan.Status__c;
            row.ourRevenue = plan.Our_Revenue__c != null ? plan.Our_Revenue__c : 0;
            row.totalWhiteSpace = plan.Total_White_Space__c != null ? plan.Total_White_Space__c : 0;
            row.totalCustomerSpend = plan.Total_Customer_Spend__c != null ? plan.Total_Customer_Spend__c : 0;
            row.shareOfWallet = plan.Share_of_Wallet__c != null ? plan.Share_of_Wallet__c.setScale(1) : 0;
            row.openPipeline = plan.Open_Pipeline_Value__c != null ? plan.Open_Pipeline_Value__c : 0;
            row.closedWonRevenue = plan.Closed_Won_Revenue__c != null ? plan.Closed_Won_Revenue__c : 0;
            row.cells = new List<AssessmentCell>();

            totalOurRev += row.ourRevenue;
            totalWS += row.totalWhiteSpace;
            totalCustSpend += row.totalCustomerSpend;
            totalOpenPip += row.openPipeline;
            sumShareOfWallet += row.shareOfWallet;

            Map<Id, White_Space_Assessment__c> planAssessments = planOfferingMap.containsKey(plan.Id) ?
                planOfferingMap.get(plan.Id) : new Map<Id, White_Space_Assessment__c>();

            // Ensure every offering has a cell for this plan row
            for (Offering__c off : activeOfferings) {
                White_Space_Assessment__c wsa = planAssessments.get(off.Id);
                AssessmentCell cell = buildCell(wsa, plan, off);
                row.cells.add(cell);

                // Add to column totals
                OfferingHeader hdr = offeringHeaderMap.get(off.Id);
                if (hdr != null) {
                    hdr.totalOurSpend += cell.ourSpend;
                    hdr.totalWhiteSpace += cell.whiteSpaceValue;
                }
            }

            response.rows.add(row);
        }

        // Summary KPIs
        response.kpis.totalPlans = plans.size();
        response.kpis.totalOurRevenue = totalOurRev;
        response.kpis.totalWhiteSpace = totalWS;
        response.kpis.totalCustomerSpend = totalCustSpend;
        response.kpis.totalOpenPipeline = totalOpenPip;
        response.kpis.avgShareOfWallet = plans.size() > 0 ? (sumShareOfWallet / plans.size()).setScale(1) : 0;

        return response;
    }

    /**
     * @description Updates or creates spend amounts for a White Space Assessment and returns the recalculated cell.
     */
    @AuraEnabled
    public static AssessmentCell updateAssessmentSpend(
        Id assessmentId,
        Id planId,
        Id offeringId,
        Decimal ourSpend,
        Decimal competitorSpend,
        Decimal internalSpend,
        Decimal unknownSpend,
        String comments
    ) {
        if (assessmentId == null && (planId == null || offeringId == null)) {
            throw new AuraHandledException('Assessment ID or Plan ID and Offering ID must be provided.');
        }

        White_Space_Assessment__c wsaToSave;
        if (assessmentId != null) {
            wsaToSave = new White_Space_Assessment__c(
                Id = assessmentId,
                Our_Spending__c = ourSpend != null ? ourSpend : 0,
                Competitor_Spending__c = competitorSpend != null ? competitorSpend : 0,
                Internal_Spending__c = internalSpend != null ? internalSpend : 0,
                Unknown_Spending__c = unknownSpend != null ? unknownSpend : 0,
                Comments__c = comments
            );
            update wsaToSave;
        } else {
            // Find existing or create new
            List<White_Space_Assessment__c> existing = [
                SELECT Id FROM White_Space_Assessment__c
                WHERE Account_Plan__c = :planId AND Offering__c = :offeringId
                LIMIT 1
            ];
            if (!existing.isEmpty()) {
                assessmentId = existing[0].Id;
                wsaToSave = new White_Space_Assessment__c(
                    Id = assessmentId,
                    Our_Spending__c = ourSpend != null ? ourSpend : 0,
                    Competitor_Spending__c = competitorSpend != null ? competitorSpend : 0,
                    Internal_Spending__c = internalSpend != null ? internalSpend : 0,
                    Unknown_Spending__c = unknownSpend != null ? unknownSpend : 0,
                    Comments__c = comments
                );
                update wsaToSave;
            } else {
                wsaToSave = new White_Space_Assessment__c(
                    Account_Plan__c = planId,
                    Offering__c = offeringId,
                    Our_Spending__c = ourSpend != null ? ourSpend : 0,
                    Competitor_Spending__c = competitorSpend != null ? competitorSpend : 0,
                    Internal_Spending__c = internalSpend != null ? internalSpend : 0,
                    Unknown_Spending__c = unknownSpend != null ? unknownSpend : 0,
                    Comments__c = comments
                );
                insert wsaToSave;
                assessmentId = wsaToSave.Id;
            }
        }

        // Re-query with formula values
        White_Space_Assessment__c updatedWsa = [
            SELECT Id, Name, Account_Plan__c, Account_Plan__r.Account__r.Name,
                   Offering__c, Offering__r.Name, Offering__r.Offering_Code__c,
                   Our_Spending__c, Competitor_Spending__c, Internal_Spending__c, Unknown_Spending__c,
                   Total_Customer_Spending__c, White_Space_Value__c, Share_of_Wallet__c,
                   Status__c, Comments__c
            FROM White_Space_Assessment__c
            WHERE Id = :assessmentId
            LIMIT 1
        ];

        Account_Plan__c plan = [
            SELECT Id, Name, Account__r.Name
            FROM Account_Plan__c
            WHERE Id = :updatedWsa.Account_Plan__c
            LIMIT 1
        ];

        Offering__c off = [
            SELECT Id, Name, Offering_Code__c
            FROM Offering__c
            WHERE Id = :updatedWsa.Offering__c
            LIMIT 1
        ];

        return buildCell(updatedWsa, plan, off);
    }

    /**
     * @description Creates a new expansion Opportunity directly tied to an Assessment and its parent Account Plan.
     */
    @AuraEnabled
    public static String createOpportunityFromAssessment(
        Id assessmentId,
        String oppName,
        Decimal amount,
        Date closeDate,
        String stageName
    ) {
        if (assessmentId == null || String.isBlank(oppName) || closeDate == null || String.isBlank(stageName)) {
            throw new AuraHandledException('Please provide all required Opportunity fields.');
        }

        White_Space_Assessment__c wsa = [
            SELECT Id, Account_Plan__c, Account_Plan__r.Account__c, Offering__r.Name
            FROM White_Space_Assessment__c
            WHERE Id = :assessmentId
            LIMIT 1
        ];

        if (wsa.Account_Plan__r.Account__c == null) {
            throw new AuraHandledException('The parent Account Plan does not have an Account linked.');
        }

        Opportunity opp = new Opportunity();
        opp.AccountId = wsa.Account_Plan__r.Account__c;
        opp.Account_Plan__c = wsa.Account_Plan__c;
        opp.White_Space_Assessment__c = wsa.Id;
        opp.Name = oppName;
        opp.Amount = amount != null ? amount : 0;
        opp.CloseDate = closeDate;
        opp.StageName = stageName;

        insert opp;
        return opp.Id;
    }

    /**
     * @description Helper to build an AssessmentCell object with calculated badge statuses.
     */
    private static AssessmentCell buildCell(White_Space_Assessment__c wsa, Account_Plan__c plan, Offering__c off) {
        AssessmentCell cell = new AssessmentCell();
        cell.offeringId = off.Id;
        cell.offeringName = off.Name;
        cell.offeringCode = off.Offering_Code__c;
        cell.planId = plan.Id;
        cell.accountName = plan.Account__r != null ? plan.Account__r.Name : plan.Name;

        if (wsa != null) {
            cell.id = wsa.Id;
            cell.name = wsa.Name;
            cell.ourSpend = wsa.Our_Spending__c != null ? wsa.Our_Spending__c : 0;
            cell.competitorSpend = wsa.Competitor_Spending__c != null ? wsa.Competitor_Spending__c : 0;
            cell.internalSpend = wsa.Internal_Spending__c != null ? wsa.Internal_Spending__c : 0;
            cell.unknownSpend = wsa.Unknown_Spending__c != null ? wsa.Unknown_Spending__c : 0;
            cell.totalCustomerSpend = wsa.Total_Customer_Spending__c != null ? wsa.Total_Customer_Spending__c : (cell.ourSpend + cell.competitorSpend + cell.internalSpend + cell.unknownSpend);
            cell.whiteSpaceValue = wsa.White_Space_Value__c != null ? wsa.White_Space_Value__c : (cell.competitorSpend + cell.internalSpend + cell.unknownSpend);
            cell.shareOfWallet = wsa.Share_of_Wallet__c != null ? wsa.Share_of_Wallet__c.setScale(1) : (cell.totalCustomerSpend > 0 ? ((cell.ourSpend / cell.totalCustomerSpend) * 100).setScale(1) : 0);
            cell.comments = wsa.Comments__c;
        } else {
            cell.id = null;
            cell.name = null;
            cell.ourSpend = 0;
            cell.competitorSpend = 0;
            cell.internalSpend = 0;
            cell.unknownSpend = 0;
            cell.totalCustomerSpend = 0;
            cell.whiteSpaceValue = 0;
            cell.shareOfWallet = 0;
            cell.comments = null;
        }

        // Determine 4-color status classification
        if (cell.ourSpend > 0 && cell.shareOfWallet >= 50) {
            cell.statusBadge = 'CLIENT_WON';
            cell.statusLabel = 'Client / Won (' + cell.shareOfWallet + '%)';
            cell.badgeClass = 'badge-won'; // Green
        } else if (cell.competitorSpend > 0 && cell.competitorSpend >= cell.ourSpend) {
            cell.statusBadge = 'COMPETITOR_DOMINANT';
            cell.statusLabel = 'Competitor Entrenched';
            cell.badgeClass = 'badge-competitor'; // Red
        } else if (cell.internalSpend > 0 || (cell.ourSpend > 0 && cell.shareOfWallet < 50)) {
            cell.statusBadge = 'INTERNAL_DIY';
            cell.statusLabel = 'Internal DIY / Partial';
            cell.badgeClass = 'badge-diy'; // Amber / Yellow
        } else {
            cell.statusBadge = 'OPEN_WHITE_SPACE';
            cell.statusLabel = 'Open White Space';
            cell.badgeClass = 'badge-open'; // White / Light Grey
        }

        return cell;
    }
}
