public class CampaignTriggerHandler implements ITriggerHandler
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
 
    public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {
        setCampaignMemberStatusPerType((List<Campaign>) newItems.values());
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        setCampaignMemberStatusPerType((List<Campaign>) newItems.values(), (Map<Id, Campaign>) oldItems);
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    private void setCampaignMemberStatusPerType(List<Campaign> newCampaigns)
    {
        setCampaignMemberStatusPerType(newCampaigns, new Map<Id, Campaign>());
    }
    
    private void setCampaignMemberStatusPerType(List<Campaign> newCampaigns, Map<Id, Campaign> oldCampaigns)
    {
        List<Campaign> campaignsToWork = new List<Campaign>();
        Set<Id> campaignIds = new Set<Id>();
        for (Campaign c : newCampaigns)
        {
            Campaign oldC = (oldCampaigns.containsKey(c.Id) ? oldCampaigns.get(c.Id) : new Campaign());
            if (c.Type != null && c.Type != oldC.Type)
            {
                campaignsToWork.add(c);
                if (c.Id != null)
                {
                    campaignIds.add(c.Id);
                }
            }
        }
        
        if (campaignsToWork.isEmpty())
        {
            return;
        }
        
        List<CampaignMemberStatus> dummyStatus = new List<CampaignMemberStatus>();
        if (!campaignIds.isEmpty())
        {
            List<CampaignMemberStatus> cms = [SELECT Id FROM CampaignMemberStatus WHERE CampaignId IN :campaignIds];
            if (!cms.isEmpty())
            {
                for (Id cId : campaignIds)
                {
                    dummyStatus.add(
                        new CampaignMemberStatus(CampaignId = cId, Label = 'Dummy', HasResponded = true, IsDefault = true, SortOrder = 100)
                    );
                }
                
                insert dummyStatus;
                
                delete cms;
            }
        }
        
        Map<String, List<CampaignMemberStatus>> statusPerType = setStatusPerTypeMap();
        
        List<CampaignMemberStatus> cmsToInsert = new List<CampaignMemberStatus>();
        for (Campaign c : campaignsToWork)
        {
            for (CampaignMemberStatus cms : statusPerType.get(c.Type))
            {
                cms.CampaignId = c.Id;
                cmsToInsert.add(cms);
            }
        }
        
        if (!cmsToInsert.isEmpty())
        {
            insert cmsToInsert;
        }
        
        if (!dummyStatus.isEmpty())
        {
            delete dummyStatus;
        }
    }
    
    @TestVisible
    private static Map<String, List<CampaignMemberStatus>> setStatusPerTypeMap()
    {
        return new Map<String, List<CampaignMemberStatus>> {
            'Outbound' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'New', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Meeting Not Scheduled', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 5)
            },
            'Inbound' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'No Contact', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Contact Requested', HasResponded = true, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 5)
            },
            'Email Marketing' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'Not Sent', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Sent', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Open', HasResponded = false, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Clicked', HasResponded = false, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Clicked Blog', HasResponded = false, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Clicked to Download', HasResponded = false, IsDefault = false, SortOrder = 5),
                new CampaignMemberStatus(Label = 'Clicked to Contact us', HasResponded = false, IsDefault = false, SortOrder = 6),
                new CampaignMemberStatus(Label = 'Downloaded', HasResponded = false, IsDefault = false, SortOrder = 7),
                new CampaignMemberStatus(Label = 'Contact Requested', HasResponded = true, IsDefault = false, SortOrder = 8),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 9),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 10),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 11),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 12)
            },
            'Mobileum Event' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'Not Invited', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Invited', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Registered', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Attended', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'No Show', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Declined', HasResponded = true, IsDefault = false, SortOrder = 5),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 6),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 7),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 8),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 9)
            },
            'Industry Event' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'Meeting Not Scheduled', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 4)
            },
            'Webinar' => new List<CampaignMemberStatus> {
                
                new CampaignMemberStatus(Label = 'Registered', HasResponded = true, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Not Invited', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Invited', HasResponded = false, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Attended Live', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'No Show', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Contact Requested', HasResponded = true, IsDefault = false, SortOrder = 5),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 6),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 7),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 8),
                new CampaignMemberStatus(Label = 'Watched Recording', HasResponded = true, IsDefault = false, SortOrder = 9),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 10)
            },
            'Ebook' => new List<CampaignMemberStatus> {
                
                new CampaignMemberStatus(Label = 'Downloaded', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Not Downloaded', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Contact Requested', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 5),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 6)
            },
            'Report' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'Downloaded', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Not Downloaded', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Contact Requested', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 5),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 6)
            },
            'Case Study' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'Downloaded', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Not Downloaded', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Contact Requested', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 5),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 6)
            },
            'Datasheet' => new List<CampaignMemberStatus> {
                new CampaignMemberStatus(Label = 'Downloaded', HasResponded = false, IsDefault = true, SortOrder = 0),
                new CampaignMemberStatus(Label = 'Not Downloaded', HasResponded = false, IsDefault = false, SortOrder = 1),
                new CampaignMemberStatus(Label = 'Contact Requested', HasResponded = true, IsDefault = false, SortOrder = 2),
                new CampaignMemberStatus(Label = 'Meeting Scheduled', HasResponded = true, IsDefault = false, SortOrder = 3),
                new CampaignMemberStatus(Label = 'Meeting Attended', HasResponded = true, IsDefault = false, SortOrder = 4),
                new CampaignMemberStatus(Label = 'Meeting - No Show', HasResponded = true, IsDefault = false, SortOrder = 5),
                new CampaignMemberStatus(Label = 'Meeting Declined', HasResponded = true, IsDefault = false, SortOrder = 6)
            }
        };
    }
}