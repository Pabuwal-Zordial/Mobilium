public class OpportunityTeamMemberTriggerHandler implements ITriggerHandler
{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean IsDisabled()
    {
        /*if (TriggerSettings__c.AccountTriggerDisabled__c = true)
            return true;
        else
            return TriggerDisabled;*/
        return false;
    }
 
    public void BeforeInsert(List<SObject> newItems) {
        RestrictChange_trgIns((List<OpportunityTeamMember>) newItems);
        checkTeamMemberRoles((List<OpportunityTeamMember>) newItems);
    }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        RestrictChange_trgUpd((List<OpportunityTeamMember>) newItems.values());
        checkTeamMemberRoles((List<OpportunityTeamMember>) newItems.values());
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        RestrictChange_trgDel((List<OpportunityTeamMember>) oldItems.values());
    }
 
    public void AfterInsert(Map<Id, SObject> newItems) {
        updateOpportunityTeamFields((Map<Id, OpportunityTeamMember>) newItems, null);
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        updateOpportunityTeamFields((Map<Id, OpportunityTeamMember>) newItems, null);
        delBDMfromOpportunity_trgUpd((Map<Id, OpportunityTeamMember>) newItems, (Map<Id, OpportunityTeamMember>) oldItems);
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {
        updateOpportunityTeamFields((Map<Id, OpportunityTeamMember>) oldItems, null);
        delBDMfromOpportunity_trgDel((Map<Id, OpportunityTeamMember>) oldItems);
    }
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    private static void delBDMfromOpportunity_trgDel(Map<Id, OpportunityTeamMember> oldOppTeamMembers)
    {
        Id OppID1;
        Id OppID3;
        for (OpportunityTeamMember oppTeam1: oldOppTeamMembers.values()) {
            string strteamrole1 = oppTeam1.TeamMemberRole;
            if (strteamrole1.contains('Business Development Manager'))
            {
                OppID1 = oppTeam1.OpportunityId;
                List < Opportunity > oppty1 = [select Id, Business_Development_Manager__c From Opportunity where Id =: OppID1];
                for (Opportunity opp1: oppty1) {
                    opp1.Business_Development_Manager__c = null;
                    update opp1;
                }
            }
        }
    }
    
    private static void delBDMfromOpportunity_trgUpd(Map<Id, OpportunityTeamMember> newOppTeamMembers, Map<Id, OpportunityTeamMember> oldOppTeamMembers)
    {
        Id OppID1;
        Id OppID3;
        for (OpportunityTeamMember oppTeam5: oldOppTeamMembers.values()) {
            string strTeamRole5 = oppTeam5.TeamMemberRole;
            /* ---added by sunita for null pointer exception---*/
            if(strteamrole5!='' && strteamrole5!=null)
            {
                    if (strteamrole5.contains('Business Development Manager')) {
                        for (OpportunityTeamMember oppTeam3: newOppTeamMembers.values()) {
                            string strteamrole3 = oppTeam3.TeamMemberRole;
                            if (!strteamrole3.contains('Business Development Manager')) {
                                OppID3 = oppTeam3.OpportunityId;
                            }
                        }
                    }
            }        
        }
        List<Opportunity> oppty3 = [select Id, Business_Development_Manager__c From Opportunity where Id =: OppID3];
        for (Opportunity opp3: oppty3) {
            opp3.Business_Development_Manager__c = null;
            update opp3;
        }
    }
    
    private static void RestrictChange_trgIns(List<OpportunityTeamMember> newOppTeamMembers)
    {
        Id OppID;
        Id OppID1;
        Id OppID2;
        Id OppID3;
        Profile ProfileName = [select Name from profile where id =: userinfo.getProfileId()];
        if (ProfileName.Name != 'System Administrator' && ProfileName.Name != 'Mobileum Salesops Team Profile') {
            for (OpportunityTeamMember oppTeam: newOppTeamMembers) {
                OppID = oppTeam.OpportunityId;
                Opportunity oppty = [select Id, StageName From Opportunity where Id =: OppID];
                string strStage1 = oppty.StageName;
                if ((strStage1.contains('Closed')) || (strStage1.contains('Won')))
                    oppTeam.adderror('Insertion is Not Allowed as Opportunity is Closed or Won');
            }
        }
    }
    
    private static void RestrictChange_trgUpd(List<OpportunityTeamMember> newOppTeamMembers)
    {
        Id OppID;
        Id OppID1;
        Id OppID2;
        Id OppID3;
        Profile ProfileName = [select Name from profile where id =: userinfo.getProfileId()];
        if (ProfileName.Name != 'System Administrator' && ProfileName.Name != 'Mobileum Salesops Team Profile') {
            for (OpportunityTeamMember oppTeam1: newOppTeamMembers) {
                OppID1 = oppTeam1.OpportunityId;
                Opportunity oppty1 = [select Id, StageName From Opportunity where Id =: OppID1];
                string strStage2 = oppty1.StageName;
                if ((strStage2.contains('Closed')) || (strStage2.contains('Won')))
                    oppTeam1.adderror('Updation is Not Allowed as Opportunity is Closed or Won');
            }
        }
    }
    
    private static void RestrictChange_trgDel(List<OpportunityTeamMember> oldOppTeamMembers)
    {
        Id OppID;
        Id OppID1;
        Id OppID2;
        Id OppID3;
        Profile ProfileName = [select Name from profile where id =: userinfo.getProfileId()];
        if (ProfileName.Name != 'System Administrator' && ProfileName.Name != 'Mobileum Salesops Team Profile') {
            for (OpportunityTeamMember oppTeam2: oldOppTeamMembers) {
                OppID2 = oppTeam2.OpportunityId;
                Opportunity oppty2 = [select Id, StageName From Opportunity where Id =: OppID2];
                string strStage3 = oppty2.StageName;
                if ((strStage3.contains('Closed')) || (strStage3.contains('Won')))
                    oppTeam2.adderror('Deletion is Not Allowed as Opportunity is Closed or Won');
            }
        }
    }

    private static void checkTeamMemberRoles(List<OpportunityTeamMember> newOppTeamMembers)
    {
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, Map<String, List<OpportunityTeamMember>>> newOtmsPerRolePerOpportunity = new Map<Id, Map<String, List<OpportunityTeamMember>>>();
        for (OpportunityTeamMember otm : newOppTeamMembers)
        {  
            opportunityIds.add(otm.OpportunityId);

            if (!newOtmsPerRolePerOpportunity.containsKey(otm.OpportunityId)) {
                newOtmsPerRolePerOpportunity.put(otm.OpportunityId, new Map<String, List<OpportunityTeamMember>>());
            }

            if (!newOtmsPerRolePerOpportunity.get(otm.OpportunityId).containsKey(otm.TeamMemberRole)) {
                newOtmsPerRolePerOpportunity.get(otm.OpportunityId).put(otm.TeamMemberRole, new List<OpportunityTeamMember>());
            }

            newOtmsPerRolePerOpportunity.get(otm.OpportunityId).get(otm.TeamMemberRole).add(otm);
        }

        if (opportunityIds.isEmpty()) return;

        List<AggregateResult> groupedResults = [SELECT OpportunityId, TeamMemberRole, COUNT(Id)total FROM OpportunityTeamMember WHERE OpportunityId IN :opportunityIds AND Id NOT IN :newOppTeamMembers GROUP BY OpportunityId, TeamMemberRole];
        
        if (groupedResults.isEmpty()) return;

        Map<Id, Map<String, Decimal>> existingOtmsPerRolePerOpportunity = new Map<Id, Map<String, Decimal>>();
        for (AggregateResult ar : groupedResults)
        {
            Id oppId = (Id) ar.get('OpportunityId');
            Decimal total = (Decimal) ar.get('total');
            String teamMemberRole = (String) ar.get('TeamMemberRole');

            if (!existingOtmsPerRolePerOpportunity.containsKey(oppId)) {
                existingOtmsPerRolePerOpportunity.put(oppId, new Map<String, Decimal>());
            }

            existingOtmsPerRolePerOpportunity.get(oppId).put(teamMemberRole, total);
        }

        for (OpportunityTeamMember otm : newOppTeamMembers)
        {
            if (existingOtmsPerRolePerOpportunity.containsKey(otm.OpportunityId) && existingOtmsPerRolePerOpportunity.get(otm.OpportunityId).containsKey(otm.teamMemberRole) 
                || newOtmsPerRolePerOpportunity.get(otm.OpportunityId).get(otm.TeamMemberRole).size() > 1) {

                if (otm.TeamMemberRole == 'Technical Account Manager')
                {
                    otm.addError('You cannot enter more than one TAM for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Additional Technical Account Manager')
                {
                    otm.addError('You cannot enter more than one Additional Technical Account Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Opportunity Owner')
                {
                    otm.addError('You cannot enter more than one Opportunity Owner for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Customer Success Manager')
                {
                    otm.addError('You cannot enter more than one Customer Success Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Customer Success General Manager')
                {
                    otm.addError('You cannot enter more than one Customer Success General Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'General Manager')
                {
                    otm.addError('You cannot enter more than one General Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Senior General Manager')
                {
                    otm.addError('You cannot enter more than one Senior General Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Business Development Manager')
                {
                    otm.addError('You cannot enter more than one Business Development Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Business Unit Lead Roaming')
                {
                    otm.addError('You cannot enter more than one Business Unit Lead Roaming for an opportunity.');
                }
                /*------added by sunita------------------------------------------*/ 
                else if (otm.TeamMemberRole == 'Business Unit Lead Engagement and Experience')
                {
                    otm.addError('You cannot enter more than one Business Unit Lead Engagement and Experience for an opportunity.');
                    
                }
                /*-----------------------------------------------------------------------*/
                else if (otm.TeamMemberRole == 'Business Unit Lead Risk')
                {
                    otm.addError('You cannot enter more than one Business Unit Lead Risk for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Business Unit Lead Testing')
                {
                    otm.addError('You cannot enter more than one Business Unit Lead Testing for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Technical Account Manager Roaming')
                {
                    otm.addError('You cannot enter more than one Technical Account Manager Roaming for an opportunity.');
                }
                /*---------------------------------added by sunita-------------------------*/
                else if (otm.TeamMemberRole == 'Technical Account Manager Experience and Engagement')
                {
                    otm.addError('You cannot enter more than one Technical Account Manager Experience and Engagement for an opportunity.');
                }
                /*--------------------------------------------------------------------------------*/
                else if (otm.TeamMemberRole == 'Technical Account Manager Risk')
                {
                    otm.addError('You cannot enter more than one Technical Account Manager Risk for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Technical Account Manager Testing')
                {
                    otm.addError('You cannot enter more than one Technical Account Manager Testing for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Commercial Specialist')
                {
                    otm.addError('You cannot enter more than one Commercial Specialist for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Renewal Specialist')
                {
                    otm.addError('You cannot enter more than one Renewal Specialist for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Cross Sell')
                {
                    otm.addError('You cannot enter more than one Cross Sell for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Key Account Manager')
                {
                    otm.addError('You cannot enter more than one Key Account Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Senior Vice President')
                {
                    otm.addError('You cannot enter more than one Senior Vice President for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay')
                {
                    otm.addError('You cannot enter more than one Overlay for an opportunity.');
                }
                /*---------------------------------added by sunita additional roles----------------------------*/  
                else if (otm.TeamMemberRole == 'Business Unit Lead Security')
                {
                    otm.addError('You cannot enter more than one Business Unit Lead Security for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Regional Sales Manager')
                {
                    otm.addError('You cannot enter more than one Regional Sales Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Solution Architect')
                {
                    otm.addError('You cannot enter more than one Solution Architect for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Technical Account Manager Security')
                {
                    otm.addError('You cannot enter more than one Technical Account Manager Security for an opportunity.');
                }
                /*else if (otm.TeamMemberRole == 'CCO')
                {
                    otm.addError('You cannot enter more than one CCO for an opportunity.');
                }*/
                else if (otm.TeamMemberRole == 'Super General Manager')
                {
                    otm.addError('You cannot enter more than one Super General Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 2')
                {
                    otm.addError('You cannot enter more than one Overlay 2 for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 3')
                {
                    otm.addError('You cannot enter more than one Overlay 3 for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 4')
                {
                    otm.addError('You cannot enter more than one Overlay4  for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 5')
                {
                    otm.addError('You cannot enter more than one Overlay 5 for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 6')
                {
                    otm.addError('You cannot enter more than one Overlay 6 for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'PC KAM')
                {
                    otm.addError('You cannot enter more than one PC KAM for an opportunity.');
                }
                
                else if (otm.TeamMemberRole == 'BU Overlay')
                {
                    otm.addError('You cannot enter more than one BU Overlay for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 7')
                {
                    otm.addError('You cannot enter more than one Overlay 7 for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'CRO')
                {
                    otm.addError('You cannot enter more than one CRO for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Global TAM')
                {
                    otm.addError('You cannot enter more than one Global TAM for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Additional Account Manager')
                {
                    otm.addError('You cannot enter more than one Additional Account Manager for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 8')
                {
                    otm.addError('You cannot enter more than one Overlay 8 for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 9')
                {
                    otm.addError('You cannot enter more than one Overlay 9 for an opportunity.');
                }
                else if (otm.TeamMemberRole == 'Overlay 10')
                {
                    otm.addError('You cannot enter more than one Overlay 10 for an opportunity.');
                }
                 else if (otm.TeamMemberRole == 'Overlay 11')
                {
                    otm.addError('You cannot enter more than one Overlay 11 for an opportunity.');
                }
                /*---------------------------------added by sunita additional roles----------------------------*/
            }
        }
    }

    private static void updateOpportunityTeamFields(Map<Id, OpportunityTeamMember> newOppTeamMembers, Map<Id, OpportunityTeamMember> oldOppTeamMembers)
    {
        Set<Id> opportunityIds = new Set<Id>();
        List <Opportunity> oppListToUpdate =  new List <Opportunity>();
        Map<Id, List<OpportunityTeamMember>> otmPerOpp = new Map<Id, List<OpportunityTeamMember>>();


        for (OpportunityTeamMember otm : newOppTeamMembers.values())
        {
            opportunityIds.add(otm.OpportunityId);
        }
        if (opportunityIds.isEmpty()) return;

        Map<Id, OpportunityTeamMember> databaseOppTeamMemb = new Map<Id, OpportunityTeamMember> ([SELECT OpportunityId, TeamMemberRole, UserId,User.Name,User.firstname,User.middlename,User.lastname FROM OpportunityTeamMember WHERE OpportunityId IN :opportunityIds]);

        for (OpportunityTeamMember otm : databaseOppTeamMemb.values())
        {
            if (otmPerOpp.containsKey(otm.OpportunityId))
            {
                otmPerOpp.get(otm.OpportunityId).add(otm);
            }
            else
            {
                otmPerOpp.put(otm.OpportunityId, new List<OpportunityTeamMember> { otm });
            }
        }

        for (Id oppId : otmPerOpp.keySet())
        {
            Opportunity opp = new Opportunity(Id = oppId);
            opp.TAM_1__c = null;
           //opp.TAM_2__c = null;
           // opp.CS_Manager__c = null;
           // opp.CS_GM__c = null;
            opp.GM__c = null;
            opp.General_Manager__c= null;
            //opp.Senior_GM__c = null;
            opp.Business_Development_Manager__c = null;
            opp.BULeadRoaming__c = null;
            opp.BusinessUnitLeadRisk__c = null;
            opp.Business_Unit_Lead_Engmnt_Exp__c = null;
            opp.Business_Unit_Lead_Testing__c = null;
            opp.Technical_Account_Manager_Roaming__c = null;
            opp.Technical_Account_Manager_Engmnt_Exp__c= null;
            opp.Technical_Account_Manager_Risk__c = null;
            opp.Technical_Account_Manager_Testing__c = null;
            opp.Commercial_Specialist__c = null;
            opp.Renewal_Specialist__c = null;
            //opp.Cross_Sell__c = null;
            opp.Key_Account_Manager__c = null;
            opp.Senior_Vice_President__c = null;
            opp.Overlay__c = null;
            opp.Additional_TAM__c= null;
            /*---------------------------------added by sunita additional roles----------------------------*/
            opp.Business_Unit_Lead_Security__c= null;
            opp.Regional_Sales_Manager__c= null;
            opp.Solution_Architect__c= null;
            opp.Technical_Account_Manager_Security__c= null;
            //opp.CCO__c= null;
            //opp.Super_General_Manager__c= null;
            
            opp.Overlay_2__c=null;
            opp.Overlay_3__c=null;
            opp.Overlay_4__c=null;
            opp.Overlay_5__c=null;
            opp.Overlay_6__c=null;
            opp.Overlay_7__c=null;
            opp.Overlay_9__c=null;
            opp.Overlay_10__c=null;
            opp.Overlay_11__c=null;
            opp.CRO__c=null;
            opp.Global_Tam__c=null;
            opp.Additional_AM__c=null;
            opp.Overlay_8__c=null;
            opp.BU_Overlay__c=null;
            opp.PC_KAM__c=null;
           /*---------------------------------added by sunita additional roles----------------------------*/
            for (OpportunityTeamMember otm : otmPerOpp.get(oppId))
            {
                if (otm.TeamMemberRole == 'Technical Account Manager')
                {
                    opp.TAM_1__c = otm.UserId;
                }
                /*else if (otm.TeamMemberRole == 'Additional Technical Account Manager')
                {
                    opp.TAM_2__c = otm.UserId;
                }*/
                else if (otm.TeamMemberRole == 'Opportunity Owner')
                {
                    opp.OwnerId = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Customer Success Manager')
                {
                   // opp.CS_Manager__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Customer Success General Manager')
                {
                   // opp.CS_GM__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'General Manager')
                {
                    opp.GM__c = otm.UserId;
                    opp.General_Manager__c= otm.UserId;
                }
                /*else if (otm.TeamMemberRole == 'Senior General Manager')
                {
                    opp.Senior_GM__c = otm.UserId;
                }*/
                else if (otm.TeamMemberRole == 'Business Development Manager')
                {
                    opp.Business_Development_Manager__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Business Unit Lead Roaming')
                {
                    opp.BULeadRoaming__c = otm.UserId;
                }
                
                else if (otm.TeamMemberRole == 'Business Unit Lead Risk')
                {
                    opp.BusinessUnitLeadRisk__c = otm.UserId;
                }
                /*------------------------------added by sunita-------------------*/
                else if (otm.TeamMemberRole == 'Business Unit Lead Engagement and Experience')
                {
                    opp.Business_Unit_Lead_Engmnt_Exp__c= otm.UserId;
                }
                /*------------------------------------------------------------------*/
                else if (otm.TeamMemberRole == 'Business Unit Lead Testing')
                {
                    opp.Business_Unit_Lead_Testing__c = otm.UserId;
                }
                /*------------------------------added by sunita-------------------*/
                else if (otm.TeamMemberRole == 'Technical Account Manager Experience and Engagement')
                {
                    opp.Technical_Account_Manager_Engmnt_Exp__c= otm.UserId;
                }
                /*------------------------------------------------------------------*/
                else if (otm.TeamMemberRole == 'Technical Account Manager Roaming')
                {
                    opp.Technical_Account_Manager_Roaming__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Technical Account Manager Risk')
                {
                    opp.Technical_Account_Manager_Risk__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Technical Account Manager Testing')
                {
                    opp.Technical_Account_Manager_Testing__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Commercial Specialist')
                {
                    opp.Commercial_Specialist__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Renewal Specialist')
                {
                    opp.Renewal_Specialist__c = otm.UserId;
                }
                /*else if (otm.TeamMemberRole == 'Cross Sell')
                {
                    opp.Cross_Sell__c = otm.UserId;
                }*/
                else if (otm.TeamMemberRole == 'Key Account Manager')
                {
                    opp.Key_Account_Manager__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Senior Vice President')
                {
                    opp.Senior_Vice_President__c = otm.UserId;
                }
                else if (otm.TeamMemberRole == 'Overlay')
                {
                   opp.Overlay__c = otm.UserId;
                   
                }
                
                else if (otm.TeamMemberRole == 'Additional Technical Account Manager')
                {
                   opp.Additional_TAM__c= otm.UserId;
                   
                }
                 /*---------------------------------added by sunita additional roles----------------------------*/
                 else if (otm.TeamMemberRole == 'Business Unit Lead Security')
                {
                   opp.Business_Unit_Lead_Security__c= otm.UserId;
                   
                }
                
                else if (otm.TeamMemberRole == 'Solution Architect')
                {
                   opp.Solution_Architect__c= otm.UserId;
                   
                }
                
                else if (otm.TeamMemberRole == 'Regional Sales Manager')
                {
                   opp.Regional_Sales_Manager__c= otm.UserId;
                   
                }
                
                else if (otm.TeamMemberRole == 'Technical Account Manager Security')
                {
                   opp.Technical_Account_Manager_Security__c= otm.UserId;
                   
                }
                /*else if (otm.TeamMemberRole == 'CCO')
                {
                   opp.CCO__c= otm.UserId;
                   
                }*/
                else if (otm.TeamMemberRole == 'Super General Manager')
                {
                  // opp.Super_General_Manager__c= otm.UserId;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 2')
                {
                  opp.Overlay_2__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 3')
                {
                  opp.Overlay_3__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 4')
                {
                  opp.Overlay_4__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 5')
                {
                  opp.Overlay_5__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 6')
                {
                  opp.Overlay_6__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 7')
                {
                  opp.Overlay_7__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'CRO')
                {
                  opp.CRO__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Global TAM')
                {
                  opp.Global_TAM__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Additional Account Manager')
                {
                  opp.Additional_AM__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 8')
                {
                  opp.Overlay_8__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 9')
                {
                  opp.Overlay_9__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'Overlay 10')
                {
                  opp.Overlay_10__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                 else if (otm.TeamMemberRole == 'Overlay 11')
                {
                  opp.Overlay_11__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
               else if (otm.TeamMemberRole == 'PC KAM')
                {
                  opp.PC_KAM__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                else if (otm.TeamMemberRole == 'BU Overlay')
                {
                  opp.BU_Overlay__c= otm.User.Firstname +' '+otm.User.lastname;
                   
                }
                
                 
                  /*---------------------------------added by sunita additional roles----------------------------*/
            }
            oppListToUpdate.add(opp);
        }

        update oppListToUpdate;
    }
}