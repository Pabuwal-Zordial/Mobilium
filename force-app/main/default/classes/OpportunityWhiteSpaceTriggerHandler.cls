/**
 * @description Trigger handler for Opportunity that:
 * 1. Auto-links Account_Plan__c and White_Space_Assessment__c when opportunities
 *    are created directly in Salesforce.
 * 2. Automatically updates linked White_Space_Assessment__c records when an opportunity
 *    is Closed Won, adding won amount to Our_Spending__c and absorbing white space.
 */
public with sharing class OpportunityWhiteSpaceTriggerHandler {

    public static void handleBeforeInsert(List<Opportunity> newOpps) {
        autoLinkPlanAndAssessment(newOpps);
    }

    public static void handleBeforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        autoLinkPlanAndAssessment(newOpps);
    }

    public static void handleAfterInsert(List<Opportunity> newOpps) {
        processWonOpportunities(newOpps, null);
    }

    public static void handleAfterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        processWonOpportunities(newOpps, oldMap);
    }

    /**
     * @description Automatically links Account Plan and White Space Assessment
     * when opportunities are created directly via standard Salesforce UI.
     */
    private static void autoLinkPlanAndAssessment(List<Opportunity> opps) {
        Set<Id> assessmentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> planIds = new Set<Id>();

        for (Opportunity opp : opps) {
            if (opp.White_Space_Assessment__c != null && opp.Account_Plan__c == null) {
                assessmentIds.add(opp.White_Space_Assessment__c);
            }
            if (opp.AccountId != null && opp.Account_Plan__c == null && opp.CloseDate != null) {
                accountIds.add(opp.AccountId);
            }
            if (opp.Account_Plan__c != null && opp.White_Space_Assessment__c == null) {
                planIds.add(opp.Account_Plan__c);
            }
        }

        // 1. If White Space Assessment is populated, auto-set parent Account Plan
        if (!assessmentIds.isEmpty()) {
            Map<Id, White_Space_Assessment__c> wsaMap = new Map<Id, White_Space_Assessment__c>([
                SELECT Id, Account_Plan__c 
                FROM White_Space_Assessment__c 
                WHERE Id IN :assessmentIds
            ]);
            for (Opportunity opp : opps) {
                if (opp.White_Space_Assessment__c != null && opp.Account_Plan__c == null && wsaMap.containsKey(opp.White_Space_Assessment__c)) {
                    opp.Account_Plan__c = wsaMap.get(opp.White_Space_Assessment__c).Account_Plan__c;
                }
            }
        }

        // 2. If Account and CloseDate are populated but Account Plan is blank, auto-match by Fiscal Year
        if (!accountIds.isEmpty()) {
            List<Account_Plan__c> plans = [
                SELECT Id, Account__c, Fiscal_Year__c 
                FROM Account_Plan__c 
                WHERE Account__c IN :accountIds
            ];
            Map<String, Id> planKeyMap = new Map<String, Id>();
            for (Account_Plan__c p : plans) {
                planKeyMap.put(p.Account__c + '_' + p.Fiscal_Year__c, p.Id);
            }

            for (Opportunity opp : opps) {
                if (opp.AccountId != null && opp.Account_Plan__c == null && opp.CloseDate != null) {
                    String targetFY = 'FY' + String.valueOf(opp.CloseDate.year());
                    String key = opp.AccountId + '_' + targetFY;
                    if (planKeyMap.containsKey(key)) {
                        opp.Account_Plan__c = planKeyMap.get(key);
                        planIds.add(opp.Account_Plan__c);
                    }
                }
            }
        }

        // 3. If Account_Plan__c is present but White_Space_Assessment__c is blank,
        // match Assessment via keywords in Opportunity Name
        if (!planIds.isEmpty()) {
            List<White_Space_Assessment__c> planAssessments = [
                SELECT Id, Account_Plan__c, Offering__r.Offering_Code__c, Offering__r.Name, Offering__r.Product_Family__c
                FROM White_Space_Assessment__c
                WHERE Account_Plan__c IN :planIds
            ];
            Map<Id, List<White_Space_Assessment__c>> assessmentsByPlan = new Map<Id, List<White_Space_Assessment__c>>();
            for (White_Space_Assessment__c wsa : planAssessments) {
                if (!assessmentsByPlan.containsKey(wsa.Account_Plan__c)) {
                    assessmentsByPlan.put(wsa.Account_Plan__c, new List<White_Space_Assessment__c>());
                }
                assessmentsByPlan.get(wsa.Account_Plan__c).add(wsa);
            }

            for (Opportunity opp : opps) {
                if (opp.Account_Plan__c != null && opp.White_Space_Assessment__c == null && assessmentsByPlan.containsKey(opp.Account_Plan__c)) {
                    String oppNameLower = String.isNotBlank(opp.Name) ? opp.Name.toLowerCase() : '';
                    List<White_Space_Assessment__c> candidates = assessmentsByPlan.get(opp.Account_Plan__c);

                    for (White_Space_Assessment__c cand : candidates) {
                        String code = String.isNotBlank(cand.Offering__r.Offering_Code__c) ? cand.Offering__r.Offering_Code__c.toLowerCase() : '';

                        Boolean matched = false;
                        if (code.contains('5g') && (oppNameLower.contains('5g') || oppNameLower.contains('standalone') || oppNameLower.contains('slice'))) {
                            matched = true;
                        } else if (code.contains('sec') && (oppNameLower.contains('sec') || oppNameLower.contains('firewall') || oppNameLower.contains('threat'))) {
                            matched = true;
                        } else if (code.contains('net') && (oppNameLower.contains('net') || oppNameLower.contains('roam') || oppNameLower.contains('probe') || oppNameLower.contains('technica'))) {
                            matched = true;
                        } else if (code.contains('rsk') && (oppNameLower.contains('risk') || oppNameLower.contains('fraud') || oppNameLower.contains('revenue'))) {
                            matched = true;
                        } else if (code.contains('cust') && (oppNameLower.contains('cust') || oppNameLower.contains('churn') || oppNameLower.contains('campaign'))) {
                            matched = true;
                        }

                        if (matched) {
                            opp.White_Space_Assessment__c = cand.Id;
                            break;
                        }
                    }
                }
            }
        }
    }

    /**
     * @description Processes Closed Won opportunities and updates White Space Assessments.
     */
    private static void processWonOpportunities(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Opportunity> newlyWonOpps = new List<Opportunity>();
        Set<Id> assessmentIds = new Set<Id>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = (oldMap != null) ? oldMap.get(opp.Id) : null;
            Boolean wasWon = (oldOpp != null) ? oldOpp.IsWon : false;
            Boolean isNowWon = opp.IsWon;

            if (isNowWon && !wasWon && opp.White_Space_Assessment__c != null && opp.Amount != null && opp.Amount > 0) {
                newlyWonOpps.add(opp);
                assessmentIds.add(opp.White_Space_Assessment__c);
            }
        }

        if (!newlyWonOpps.isEmpty()) {
            applyWonAmountToAssessments(assessmentIds, newlyWonOpps);
        }
    }

    public static void applyWonAmountToAssessments(Set<Id> assessmentIds, List<Opportunity> opps) {
        Map<Id, White_Space_Assessment__c> wsaMap = new Map<Id, White_Space_Assessment__c>([
            SELECT Id, Name, Our_Spending__c, Competitor_Spending__c, Internal_Spending__c, Unknown_Spending__c, Comments__c
            FROM White_Space_Assessment__c
            WHERE Id IN :assessmentIds
        ]);

        Map<Id, White_Space_Assessment__c> toUpdateMap = new Map<Id, White_Space_Assessment__c>();

        for (Opportunity opp : opps) {
            if (!wsaMap.containsKey(opp.White_Space_Assessment__c)) {
                continue;
            }

            White_Space_Assessment__c wsa = toUpdateMap.containsKey(opp.White_Space_Assessment__c) ?
                toUpdateMap.get(opp.White_Space_Assessment__c) :
                wsaMap.get(opp.White_Space_Assessment__c);

            Decimal wonAmount = (opp.Amount != null) ? opp.Amount : 0;
            if (wonAmount <= 0) {
                continue;
            }

            Decimal ourSpend = (wsa.Our_Spending__c != null) ? wsa.Our_Spending__c : 0;
            Decimal compSpend = (wsa.Competitor_Spending__c != null) ? wsa.Competitor_Spending__c : 0;
            Decimal diySpend = (wsa.Internal_Spending__c != null) ? wsa.Internal_Spending__c : 0;
            Decimal unkSpend = (wsa.Unknown_Spending__c != null) ? wsa.Unknown_Spending__c : 0;

            // 1. Increase Our Spending by won amount
            ourSpend += wonAmount;

            // 2. Absorb from White Space buckets
            Decimal remainingToDeduct = wonAmount;

            // First absorb from Competitor
            if (remainingToDeduct > 0 && compSpend > 0) {
                if (compSpend >= remainingToDeduct) {
                    compSpend -= remainingToDeduct;
                    remainingToDeduct = 0;
                } else {
                    remainingToDeduct -= compSpend;
                    compSpend = 0;
                }
            }

            // Next absorb from Internal DIY
            if (remainingToDeduct > 0 && diySpend > 0) {
                if (diySpend >= remainingToDeduct) {
                    diySpend -= remainingToDeduct;
                    remainingToDeduct = 0;
                } else {
                    remainingToDeduct -= diySpend;
                    diySpend = 0;
                }
            }

            // Next absorb from Unknown
            if (remainingToDeduct > 0 && unkSpend > 0) {
                if (unkSpend >= remainingToDeduct) {
                    unkSpend -= remainingToDeduct;
                    remainingToDeduct = 0;
                } else {
                    remainingToDeduct -= unkSpend;
                    unkSpend = 0;
                }
            }

            // Append win note to comments
            String winNote = '[Won Deal: ' + opp.Name + ' ($' + String.valueOf(wonAmount.setScale(0)) + ')]';
            String newComments = String.isNotBlank(wsa.Comments__c) ? wsa.Comments__c + ' ' + winNote : winNote;

            wsa.Our_Spending__c = ourSpend;
            wsa.Competitor_Spending__c = compSpend;
            wsa.Internal_Spending__c = diySpend;
            wsa.Unknown_Spending__c = unkSpend;
            wsa.Comments__c = newComments;

            toUpdateMap.put(wsa.Id, wsa);
        }

        if (!toUpdateMap.isEmpty()) {
            update toUpdateMap.values();
        }
    }
}
