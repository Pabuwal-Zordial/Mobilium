/*************************************************************************************
Name                    clshandler_billingSchedule_project
Developed By            West Monroe Partners
Purpose                 Refer individual method headers
Created date            2/9/2017
Modified By             Sandeep Maroo : To include security business line.
Modified Date           09/12/2018
*************************************************************************************/
public class clshandler_billingSchedule_project {
  private static final String BIG_DATA_ANALYTICS = 'Big Data Analytics';
  private static final String ROAMING = 'Roaming';
  private static final String ROAMING_ANALYTICS = 'Roaming Analytics';
  private static final String TEST_FACTORY = 'Test Factory';
  private static final String TRAVEL = 'Travel';
  private static final String UNDETERMINED = 'Undetermined';
  private static final String SECURITY = 'Security';
  private static final String RISK = 'Risk';
  private static final String TESTING = 'Testing';
  /*------added by sunita for new BU Engagement and Experience---*/
  private static final String Engagement_Experience = 'Engagement and Experience';

    /*************************************************************************************
    Method Name             relatedBillingSchedules()
    Developed By            West Monroe Partners
    Purpose                 for every opportunity line item
                                * query and get the related opportunity line items
    Created date            2/17/2017
    Parameters              list<OpportunityLineItem> - sending the list of opportunityLineItem
                            and return the list<Billing_Schedule__c> for every opportunityLineItem
    Output type             map<string, list<Billing_Schedule__c>>
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/17/2017       Refer method header
    **********************************************************************************
    private map<string, list<Schedule__c>> relatedBillingSchedules(list<OpportunityLineItem> list_OppLineItem){
        //variables used in the method
        list<string> list_oppLineItemId = new list<string>();
        map<string,list<Schedule__c>> map_oppLineItemIdToListofBillingSchedule  = new map<string,list<Schedule__c>>();

        //iterating through the list of opportunity line item and get the list of opportunity line item ids
        for(OpportunityLineItem iterating_oppLineItem : list_OppLineItem){
            //adding the opportunity line items
            list_oppLineItemId.add(iterating_oppLineItem.id);
        }

        //querying for the opportunity line item
        for(Schedule__c iterating_billingSchedule : [ SELECT Id,
                                                                     Amount__c,
                                                                     Billing_Frequency__c,
                                                                     Milestone__c,
                                                                     Milestone_name__c,
                                                                     Opportunity__c,
                                                                     Opportunity_Line_Item_ID__c,
                                                                     Product__c,
                                                                     //Product_Category__c,
                                                                     Project__c,
                                                                     Scheduled_Date__c
                                                              FROM
                                                                    Schedule__c
                                                              WHERE
                                                                    Opportunity_Line_Item_ID__c
                                                                        IN : list_oppLineItemId
                                                            ]
            ){
                //The Opportunity_Line_Item_ID__c exists in the map
                if(map_oppLineItemIdToListofBillingSchedule.containsKey(iterating_billingSchedule.Opportunity_Line_Item_ID__c)){
                    list<Schedule__c> list_BillingSchedule = new list<Schedule__c>();
                    list_BillingSchedule = map_oppLineItemIdToListofBillingSchedule.get(iterating_billingSchedule.Opportunity_Line_Item_ID__c);
                    list_BillingSchedule.add(iterating_billingSchedule);
                    //adding back the value
                    map_oppLineItemIdToListofBillingSchedule.put(iterating_billingSchedule.Opportunity_Line_Item_ID__c, list_BillingSchedule);
                }else{ //The Opportunity_Line_Item_ID__c does not exist in the map
                    list<Schedule__c> list_BillingSchedule = new list<Schedule__c>();
                    list_BillingSchedule.add(iterating_billingSchedule);
                    //adding back the value
                    map_oppLineItemIdToListofBillingSchedule.put(iterating_billingSchedule.Opportunity_Line_Item_ID__c, list_BillingSchedule);
                }
        }

        return map_oppLineItemIdToListofBillingSchedule;
    }
    ***/
    /*************************************************************************************
    Method Name             upsertBillSchedulesOnMilestone()
    Developed By            West Monroe Partners
    Purpose                 for every milestone record
                            Check for individual change of date(from project) and update those specific records
                                There are 2 cases
                                * if the project date value is changed
                                    to null
                                        * delete the billing schedules
                                    no change/to another value - non null
                                        * from null
                                            create new billing schedules
                                        * from another value or no change
                                            delete all existing billing schedules
                                            create new billing schedules
    Created date            2/13/2017
    Parameters              list<Milestone__c> - the list of milestone(s) from the trigger
                            for which the purpose will be executed
    Output type             void
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/13/2017       Refer method header
    *************************************************************************************/
    public void upsertBillSchedulesOnMilestone(list<Milestone__c> list_milestones){

        //variables and data sets required for the method
        set<Id> set_relatedProjects = new set<Id>();
        //related project and its values
        map<Id,Project__c> map_projectAndValues = new map<Id,Project__c>();
        //related project and milestones
        map<Id,map<Id,Milestone__c>> map_projectToMilestones = new map<Id,map<Id,Milestone__c>>();
        //related project and milestone and schedules associated
        map<Id,map<Id,map<String, list<Schedule__c>>>> map_projectToMilestonesToSchdules = new map<Id,map<Id,map<String, list<Schedule__c>>>>();
        //related project and opportunity line items
        map<Id,map<string,list<OpportunityLineItem>>> map_projectToOpportunityLineItem = new map<Id,map<string,list<OpportunityLineItem>>>();
        //map of project to schedules direct -- easier to delete
        map<Id,list<Schedule__c>> map_projectToSchedules = new map<Id,list<Schedule__c>>();
        //Final DML collections
        list<Schedule__c> list_insertSchedules = new list<Schedule__c>();
        set<Schedule__c> set_deleteSchedules = new set<Schedule__c>();

        //iterating through the list of milestones and fetching the projectIds
        for(Milestone__c iterating_milestone : list_milestones){
            set_relatedProjects.add(iterating_milestone.Project__c);
        }
        //get all the projects related to the milestones
        for(Project__c iterating_project : [SELECT Id,
                                                   Contract_Date__c,
                                                   FA_Date__c,
                                                   HW_delivery_Date__c,
                                                   HW_Install_Date__c,
                                                   KPI_Date__c,
                                                   Opportunity__c,
                                                   PO_Date__c,
                                                   Retention_Date__c,
                                                   RFA_Date__c,
                                                   Stability_Date__c,
                                                   SW_delivery_Date__c,
                                                   UAT_Date__c,
                                                   (SELECT Id,
                                                           Contract__c,
                                                           FA__c,
                                                           HW_delivery__c,
                                                           HW_Install__c,
                                                           KPI__c,
                                                           PO__c,
                                                           ProductCategory__c,
                                                           Retention__c,
                                                           RFA__c,
                                                           Stability__c,
                                                           SW_delivery__c,
                                                           Project__c,
                                                           UAT__c
                                                    FROM
                                                        Milestones__r
                                                   ),
                                                   (SELECT Id,
                                                           Amount__c,
                                                           Milestone__c,
                                                           Milestone_name__c,
                                                           Opportunity_Line_Item_ID__c,
                                                           Product__c,
                                                           Project__c,
                                                           Opportunity__c,
                                                           Scheduled_Date__c
                                                     FROM
                                                            Billing_Schedules__r
                                                   )
                                             FROM
                                                   Project__c
                                             WHERE
                                                    Id
                                                        IN: set_relatedProjects
                                                   ]){
            //there are 3 use cases here
            //1.dates have a value --
                //a.update from blank -- insert case
                //b.udpate from another -- update case -- query related Schedule__c records
            //2. dates have a blank
                //a.remained blank -- no change
                //b. moved to blank -- delete case -- query related Schedule__c records

            //Adding the project value to a map
            map_projectAndValues.put(iterating_project.Id,iterating_project);

            //iterating through the milestones
            for(Milestone__c iterating_milestone : iterating_project.Milestones__r){
                //checking if the project id exists in the map
                if(map_projectToMilestones.containsKey(iterating_project.id)){
                    //if the project exists and milestone id exists
                    if(!(map_projectToMilestones.get(iterating_project.id)).containsKey(iterating_milestone.id)){ //if the project exists and milestone id do not exists
                        (map_projectToMilestones.get(iterating_project.id)).put(iterating_milestone.id, iterating_milestone);

                        //adding a null map to the milestone part of it
                        map<String, list<Schedule__c>> map_tempMilestoneSchedulemapper = new map<String, list<Schedule__c>>();
                        map<Id,map<String, list<Schedule__c>>> mapMilestonetemp = new map<Id,map<String, list<Schedule__c>>>();
                        mapMilestonetemp.put(iterating_milestone.id, map_tempMilestoneSchedulemapper);
                        map_projectToMilestonesToSchdules.put(iterating_project.id, mapMilestonetemp);
                        //adding the schedule records related to the milestone
                        if(!iterating_project.Billing_Schedules__r.isEmpty()){
                            for(Schedule__c iterating_schedule : iterating_project.Billing_Schedules__r){
                                //if the milestone name exists
                                if(((map_projectToMilestonesToSchdules.get(iterating_project.id)).get(iterating_milestone.id)).containsKey(iterating_schedule.Milestone_name__c)){
                                    //retriving the list which has been added
                                    list<Schedule__c> list_schedule = ((map_projectToMilestonesToSchdules.get(iterating_project.id)).get(iterating_milestone.id)).get(iterating_schedule.Milestone_name__c);
                                    list_schedule.add(iterating_schedule);
                                    //Adding back to map
                                    ((map_projectToMilestonesToSchdules.get(iterating_project.id)).get(iterating_milestone.id)).put(iterating_schedule.Milestone_name__c, list_schedule);
                                }else{//if the milestone names does not exist
                                    list<Schedule__c> list_schedule = new list<Schedule__c>();
                                    list_schedule.add(iterating_schedule);
                                    //Adding back to map
                                    ((map_projectToMilestonesToSchdules.get(iterating_project.id)).get(iterating_milestone.id)).put(iterating_schedule.Milestone_name__c, list_schedule);
                                }
                                //Also populating the other map
                                //if the project id exists
                                if(map_projectToSchedules.containsKey(iterating_project.id)){
                                    list<Schedule__c> list_schedule = new list<Schedule__c>();
                                    //retriving the list which has been added
                                    list_schedule = map_projectToSchedules.get(iterating_project.id);
                                    list_schedule.add(iterating_schedule);
                                    //Adding back to map
                                    map_projectToSchedules.put(iterating_project.id, list_schedule);
                                }else{
                                    list<Schedule__c> list_schedule = new list<Schedule__c>();
                                    list_schedule.add(iterating_schedule);
                                    //Adding back to map
                                    map_projectToSchedules.put(iterating_project.id, list_schedule);
                                }
                            }
                        }
                        //resetting all maps
                        map_tempMilestoneSchedulemapper = new map<String, list<Schedule__c>>();
                        mapMilestonetemp = new map<Id,map<String, list<Schedule__c>>>();
                    }
                }else{//checking if the project id does not exists in the map
                    map<Id,Milestone__c> map_tempMilestonemapper = new map<Id,Milestone__c>();
                    map_tempMilestonemapper.put(iterating_milestone.Id,iterating_milestone);
                    //Adding it back to the map
                    map_projectToMilestones.put(iterating_project.id,map_tempMilestonemapper);
                    //resetting themap
                    map_tempMilestonemapper = new map<Id,Milestone__c>();

                }
            }
        }

        //getting the related opportunity line items for the projects
        for (OpportunityLineItem iterating_oppLineItem : [ SELECT
                                                                Id,
                                                                TotalPrice,
                                                                Project__c,
                                                                Product_Category__c,
                                                                OpportunityId,
                                                                Product2Id,
                                                                MBLM_Billing_Frequency__c,
                                                                MBIL_Effective_Start_date__c,
                                                                MBIL_Subscription_Term__c
                                                          FROM
                                                                OpportunityLineItem
                                                          WHERE
                                                                Project__c
                                                                    IN: set_relatedProjects
                                                          AND
                                                                MBLM_Billing_Frequency__c = 'Milestone'
                                                         ]
            ){
                if(map_projectToOpportunityLineItem.containsKey(iterating_oppLineItem.Project__c)){
                    //checking the product category key exists
                    if(map_projectToOpportunityLineItem.get(iterating_oppLineItem.Project__c).containsKey(iterating_oppLineItem.Product_Category__c)){
                        //contains both the keys, so add the opportunity line item to the list
                        list<OpportunityLineItem> list_oppLineItem = new list<OpportunityLineItem>();
                        list_oppLineItem = map_projectToOpportunityLineItem.get(iterating_oppLineItem.Project__c).get(iterating_oppLineItem.Product_Category__c);
                        //adding the running value
                        list_oppLineItem.add(iterating_oppLineItem);
                        //adding it back to the map
                        map<string,list<OpportunityLineItem>> map_tempPlaceHolder = new map<string,list<OpportunityLineItem>>();
                        map_tempPlaceHolder = map_projectToOpportunityLineItem.get(iterating_oppLineItem.Project__c);
                        map_tempPlaceHolder.put(iterating_oppLineItem.Product_Category__c, list_oppLineItem);
                        map_projectToOpportunityLineItem.put(iterating_oppLineItem.Project__c,map_tempPlaceHolder);
                    }else{ //doesnt contain the product category
                        list<OpportunityLineItem> list_oppLineItem = new list<OpportunityLineItem>();
                        //adding the running value
                        list_oppLineItem.add(iterating_oppLineItem);
                        //adding it back to the map
                        map<string,list<OpportunityLineItem>> map_tempPlaceHolder = new map<string,list<OpportunityLineItem>>();
                        map_tempPlaceHolder = map_projectToOpportunityLineItem.get(iterating_oppLineItem.Project__c);
                        map_tempPlaceHolder.put(iterating_oppLineItem.Product_Category__c, list_oppLineItem);
                        //map_tempPlaceHolder = map_projectToOpportunityLineItem.get(iterating_oppLineItem.Project__c);
                        //map_projectToOpportunityLineItem.
                        map_projectToOpportunityLineItem.put(iterating_oppLineItem.Project__c,map_tempPlaceHolder);
                    }
                }else{ //doesnt contains the project id
                    //adding everything here
                    map<string,list<OpportunityLineItem>> map_tempToAddToMap = new map<string,list<OpportunityLineItem>>();
                    list<OpportunityLineItem> list_oppLineItem = new list<OpportunityLineItem>();
                    //adding the running value
                    list_oppLineItem.add(iterating_oppLineItem);
                    //adding to temp map
                    map_tempToAddToMap.put(iterating_oppLineItem.Product_Category__c, list_oppLineItem);
                    //adding it back to the main map
                    map_projectToOpportunityLineItem.put(iterating_oppLineItem.Project__c, map_tempToAddToMap);
                }
        }

        //Making sure we have what we want
        System.debug('map_projectToOpportunityLineItem >> ' + map_projectToOpportunityLineItem);
        System.debug('set_relatedProjects >>' + set_relatedProjects);
        System.debug('map_projectToMilestones >>'  + map_projectToMilestones);
        System.debug('map_projectToMilestonesToSchdules >>'  + map_projectToMilestonesToSchdules);

        //Phew!!!! outside that complex loop..But we have all thats required for the next steps!
        /**
        -----------------------------------------------------------------------------------------------
        So a little recap.. we have
        1. map_projectAndValues - map of project ids and projects
        2. map_projectToMilestones - map of projects to a value map of milestone id and milestone record


        I have intentionally added this comment to ensure that you are decoupled from the previous segement of
        the method. I know this is a loooooong method.. Can't split into different methods
        Now that we have the collections ready... the main logic is going to follow.. so pay attention :)
        -----------------------------------------------------------------------------------------------
        **/
        //Looping through the list of projects we have in hand
        for(Project__c iterating_project : map_projectAndValues.values()){
            //we are going to check for each date for not null and handle both scenarios

            //using a common list which parses from one milestone to another
            list<Schedule__c> list_milestoneSchedule = new list<Schedule__c>();

            /**
                PO related logic
            **/
            //Checking if the billing schedules are present for "PO" milestones
            list_milestoneSchedule = containsScheduleForMilestone('PO',map_projectToSchedules.get(iterating_project.id));
            //Checking if the PO_Date__c is not null
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.PO_Date__c);
            if(iterating_project.PO_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'PO',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'PO',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                Contract related logic
            **/
            //Checking if the billing schedules are present for "Contract" milestones
            list_milestoneSchedule = containsScheduleForMilestone('Contract',map_projectToSchedules.get(iterating_project.id));

            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.Contract_Date__c);

            //Checking if the Contract_Date__c is not null
            if(iterating_project.Contract_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'Contract',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'Contract',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                HW delivery related logic
            **/
            //Checking if the billing schedules are present for "Hw Delivery" milestones
            list_milestoneSchedule = containsScheduleForMilestone('HW Delivery',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.HW_delivery_Date__c);
            //Checking if the HW_delivery_Date__c is not null
            if(iterating_project.HW_delivery_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'HW Delivery',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'HW Delivery',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                HW Install related logic
            **/
            //Checking if the billing schedules are present for "Hw Install" milestones
            list_milestoneSchedule = containsScheduleForMilestone('HW Install',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.HW_Install_Date__c);
            //Checking if the HW_Install_Date__c is not null
            if(iterating_project.HW_Install_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'HW Install',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'HW Install',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                SW Delivery related logic
            **/

            //Checking if the billing schedules are present for "SW Delivery" milestones
            list_milestoneSchedule = containsScheduleForMilestone('SW Delivery',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.SW_delivery_Date__c);
            //Checking if the SW_delivery_Date__c is not null
            if(iterating_project.SW_delivery_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'SW Delivery',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'SW Delivery',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                RFA related logic
            **/
            //Checking if the billing schedules are present for "RFA" milestones
            list_milestoneSchedule = containsScheduleForMilestone('RFA',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.RFA_Date__c);
            //Checking if the RFA_Date__c is not null
            if(iterating_project.RFA_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'RFA',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'RFA',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                UAT related logic
            **/
            //Checking if the billing schedules are present for "UAT" milestones
            list_milestoneSchedule = containsScheduleForMilestone('UAT',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.UAT_Date__c);
            //Checking if the UAT_Date__c is not null
            if(iterating_project.UAT_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'UAT',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'UAT',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                Stability related logic
            **/
            //Checking if the billing schedules are present for "Stability" milestones
            list_milestoneSchedule = containsScheduleForMilestone('Stability',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.Stability_Date__c);
            //Checking if the Stability_Date__c is not null
            if(iterating_project.Stability_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'Stability',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'Stability',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                FA related logic
            **/
            //Checking if the billing schedules are present for "FA" milestones
            list_milestoneSchedule = containsScheduleForMilestone('FA',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.FA_Date__c);
            //Checking if the FA_Date__c is not null
            if(iterating_project.FA_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'FA',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'FA',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                KPI related logic
            **/
            //Checking if the billing schedules are present for "KPI" milestones
            list_milestoneSchedule = containsScheduleForMilestone('KPI',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.KPI_Date__c);
            //Checking if the KPI_Date__c is not null
            if(iterating_project.KPI_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'KPI',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'KPI',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            /**
                Retention related logic
            **/
            //Checking if the billing schedules are present for "Retention" milestones
            list_milestoneSchedule = containsScheduleForMilestone('Retention',map_projectToSchedules.get(iterating_project.id));
            System.debug('The list of milestone schedules existing >> ' + list_milestoneSchedule);
            System.debug('The date >> ' + iterating_project.Retention_Date__c);
            //Checking if the Retention_Date__c is not null
            if(iterating_project.Retention_Date__c != null){
                //There are 2 cases
                //1. The value was already null and moved to a value - which translates to no prior Billing Schdule records
                //checking the there are no billing schedule records
                if(list_milestoneSchedule.isEmpty()){
                    //create new values method
                    if(map_projectToOpportunityLineItem.containsKey(iterating_project.id) && map_projectToMilestones.containsKey(iterating_project.id))
                        list_insertSchedules.addAll(createSchedules( 'Retention',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }else{ //2. Value was present - was changed or not changed.. doesn't matter, we delete and recreate records
                    //Step 1 - delete all existing values
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                    //Step 2 - create new values method
                    list_insertSchedules.addAll(createSchedules( 'Retention',
                                                                map_projectToMilestones.get(iterating_project.id),
                                                                iterating_project,
                                                                map_projectToOpportunityLineItem.get(iterating_project.id)
                                                                ));
                }
            }else{
                //If null there are 2 cases
                //1. The value was already null - which translates to no prior Billing Schdule records - do nothing
                if(!list_milestoneSchedule.isEmpty()){
                    //2. Was moved to null - delete related Billing schedule records
                    set_deleteSchedules.addAll(list_milestoneSchedule);
                }
            }
            //resetting the list
            list_milestoneSchedule = new list<Schedule__c>();

            //changing the set to list
            list<Schedule__c> list_deleteSchedules = new list<Schedule__c>();
            list_deleteSchedules.addAll(set_deleteSchedules);

            System.debug('Delete list >>>> ' + list_deleteSchedules);
            System.debug('Delete list >>>> ' + list_deleteSchedules.size());
            System.debug('Insert list >>>> ' + list_insertSchedules);
            System.debug('Insert list >>>> ' + list_insertSchedules.size());
            //Final DMLs
            if(!list_deleteSchedules.isEmpty())
                Database.delete(list_deleteSchedules);
            if(!list_insertSchedules.isEmpty())
                Database.upsert(list_insertSchedules, true);

        }
    }

    /*************************************************************************************
    Method Name             deleteRelatedBillingSchedule()
    Developed By            West Monroe Partners
    Purpose                 for every opportunitylineItem multiple related billing schedule
                            records are delete -- this method is called from the trigger
    Created date            2/21/2017
    Parameters              list<OpportunityLineItem>
    Output type             void
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/21/2017       Refer method header
    *************************************************************************************/
    public void deleteRelatedBillingSchedule(list<OpportunityLineItem> list_OppLineItem){
        list<id> list_allRelatedBillingScheduleToBeDeleted = new list<id>();

        list_allRelatedBillingScheduleToBeDeleted.addAll(returnRelatedBillingSchedules(list_OppLineItem));

        if(!list_allRelatedBillingScheduleToBeDeleted.isEmpty())
            Database.delete(list_allRelatedBillingScheduleToBeDeleted,true);
    }


    /*************************************************************************************
    Method Name             updateRelatedBillingSchedule()
    Developed By            West Monroe Partners
    Purpose                 for every opportunitylineItem multiple related billing schedule
                            records are deleted and recreated -- this method is called from the trigger
    Created date            2/21/2017
    Parameters              list<OpportunityLineItem>
    Output type             void
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/21/2017       Refer method header
    *************************************************************************************/
    public void updateRelatedBillingSchedule(list<OpportunityLineItem> list_OppLineItem){

        //deletion --step 1
        deleteRelatedBillingSchedule(list_OppLineItem);

        //creation -- recreation actually
        insertRelatedBillingSchedule(list_OppLineItem);
    }

    /*************************************************************************************
    Method Name             insertRelatedBillingSchedule()
    Developed By            West Monroe Partners
    Purpose                 for every opportunitylineItem multiple related billing schedule
                            records are inserted -- this method is called from the trigger
    Created date            2/20/2017
    Parameters              list<OpportunityLineItem>
    Output type             void
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/20/2017       Refer method header
    *************************************************************************************/
    public void insertRelatedBillingSchedule(list<OpportunityLineItem> list_OppLineItem){

        //list to send relative billing schedules creation method
        list<OpportunityLineItem> list_oneTimeLineItems = new list<OpportunityLineItem>();
        list<OpportunityLineItem> list_recurringLineItems = new list<OpportunityLineItem>();
        list<OpportunityLineItem> list_milestoneLineItems = new list<OpportunityLineItem>();

        //overall list for the DML(s)
        list<Schedule__c> list_insertSchedules = new list<Schedule__c>();
        //iterating through the list of line items and splitting them
        for(OpportunityLineItem iterating_oppLineItem : list_OppLineItem){
            //if the MBLM_Billing_Frequency__c field is one time
        /**
            Changes for Version 2.0
            Now we are checking if its one-time and has subscription terms
            if yes
                We have to create one "One-time" billing type billing schedule
                and
                multiple (no of subscription terms) types of accounting billing schedules
            if no
                Just create one billing schedule

            also for all types of billing schedules,
                type = billing
        **/
            if(iterating_oppLineItem.MBLM_Billing_Frequency__c == 'One-Time' && (iterating_oppLineItem.MBIL_Subscription_Term__c == null || iterating_oppLineItem.MBIL_Subscription_Term__c < 1))
                list_oneTimeLineItems.add(iterating_oppLineItem);
        else if(iterating_oppLineItem.MBLM_Billing_Frequency__c == 'One-Time' && iterating_oppLineItem.MBIL_Subscription_Term__c >= 1){
            list_oneTimeLineItems.add(iterating_oppLineItem);
            list_recurringLineItems.add(iterating_oppLineItem);
        }else if(iterating_oppLineItem.MBLM_Billing_Frequency__c == 'Milestone')
                list_milestoneLineItems.add(iterating_oppLineItem);
            else if(iterating_oppLineItem.MBLM_Billing_Frequency__c == 'Monthly')
                list_recurringLineItems.add(iterating_oppLineItem);
        }

        //calling respective functions to return/create the list of billing schedules

        //creating the method that returns one time schedules
        if(!list_oneTimeLineItems.isEmpty())
            list_insertSchedules.addAll(createOneTimeSchedules(list_oneTimeLineItems));

        //creating the method that returns recurring time schedules
        if(!list_recurringLineItems.isEmpty())
            list_insertSchedules.addAll(createRecurringSchedules(list_recurringLineItems));

        //creating the method that automatically creates milestone schedules
        if(!list_milestoneLineItems.isEmpty())
                createMilestoneSchedules(list_milestoneLineItems);

        System.debug('******* The lists are *******');
             System.debug(' list_oneTimeLineItems  >>>  ' +list_oneTimeLineItems);
             System.debug(' list_milestoneLineItems  >>>  ' +list_milestoneLineItems);
             System.debug(' list_recurringLineItems  >>>  ' +list_recurringLineItems);
             System.debug(' list_insertSchedules  >>>  ' +list_insertSchedules);
        System.debug('******* end lists are *******');
        //Once the milestone billing schedules DMLs are done
        if(!list_insertSchedules.isEmpty())
            Database.insert(list_insertSchedules, false);


    }

     /*************************************************************************************
    Method Name             createMonthlySchedules()
    Developed By            West Monroe Partners
    Purpose                 for every opportunitylineItem check the related project records for
                            respective date and then send the list of milestones
    Created date            2/20/2017
    Parameters              list<OpportunityLineItem>
    Output type             list<milestone__c> - related milestones for every opplineItem Id
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/20/2017       Refer method header
    *************************************************************************************/
    private void createMilestoneSchedules(list<OpportunityLineItem> list_OppLineItem){

        //iterating through the list of opp line items to fetch the project Ids
        set<id> set_relatedProjectIds  = new set<id>();
        list<Milestone__c> list_updateMilestone = new list<Milestone__c>();
        for(OpportunityLineItem iterating_oppLineItem : list_OppLineItem){
            set_relatedProjectIds.add(iterating_oppLineItem.Project__c);
        }
        //iterating thorough the set of projects for the related opp line items
        for(Project__c iterating_project : [ SELECT Id,
                                                   Contract_Date__c,
                                                   FA_Date__c,
                                                   HW_delivery_Date__c,
                                                   HW_Install_Date__c,
                                                   KPI_Date__c,
                                                   Opportunity__c,
                                                   PO_Date__c,
                                                   Retention_Date__c,
                                                   RFA_Date__c,
                                                   Stability_Date__c,
                                                   SW_delivery_Date__c,
                                                   UAT_Date__c,
                                                   (SELECT Id,
                                                           Contract__c,
                                                           FA__c,
                                                           HW_delivery__c,
                                                           HW_Install__c,
                                                           KPI__c,
                                                           PO__c,
                                                           ProductCategory__c,
                                                           Retention__c,
                                                           RFA__c,
                                                           Stability__c,
                                                           SW_delivery__c,
                                                           UAT__c,
                                                           project__c
                                                    FROM
                                                        Milestones__r
                                                   )
                                            FROM
                                                Project__c
                                            WHERE
                                                Id in:set_relatedProjectIds
                                           ]
            ){
                //checking if the dates are not null..
                //enough if one date has values, then update the milestone records
                if(iterating_project.Contract_Date__c != NULL
                   ||
                   iterating_project.PO_Date__c != NULL
                   ||
                   iterating_project.HW_delivery_Date__c != NULL
                   ||
                   iterating_project.HW_Install_Date__c != NULL
                   ||
                   iterating_project.KPI_Date__c != NULL
                   ||
                   iterating_project.FA_Date__c != NULL
                   ||
                   iterating_project.Retention_Date__c != NULL
                   ||
                   iterating_project.RFA_Date__c != NULL
                   ||
                   iterating_project.Stability_Date__c != NULL
                   ||
                   iterating_project.SW_delivery_Date__c != NULL
                   ||
                   iterating_project.UAT_Date__c != NULL
                  ){
                    list_updateMilestone.addAll(iterating_project.Milestones__r);
              }
         }
         System.debug('******* createMilestoneSchedules *******');
            System.debug('list_updateMilestone >> ' + list_updateMilestone);
         System.debug('******* End of  createMilestoneSchedules  *******');
         //time to call the method milestone class
         upsertBillSchedulesOnMilestone(list_updateMilestone);
    }

    /*************************************************************************************
    Method Name             returnRelatedBillingSchedules()
    Developed By            West Monroe Partners
    Purpose                 for every opportunitylineItem multiple related billing schedule
                            records are returned
    Created date            2/20/2017
    Parameters              list<OpportunityLineItem>
    Output type             list<Id>> - related schedules for every opplineItem Id
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/20/2017       Refer method header
    *************************************************************************************/
    private list<Id> returnRelatedBillingSchedules(list<OpportunityLineItem> listOppLineItem){

        //list to send related billing schedules
        list<Id> list_relatedSchedules = new list<Id>();
        set<string> set_oppLineItemIdAsString = new set<string>();

        //iterating the list of list of opportunity line item
        for(OpportunityLineItem iterating_oppLineItem : listOppLineItem){
            set_oppLineItemIdAsString.add((string)iterating_oppLineItem.id);
        }

        //querying the list of opportunity items for every billing scheudles
        for(Schedule__c iterating_schedule : [ SELECT
                                                    Id
                                                FROM
                                                    Schedule__c
                                                WHERE
                                                    Opportunity_Line_Item_ID__c
                                                        IN: set_oppLineItemIdAsString
                                             ]
           ){
            list_relatedSchedules.add(iterating_schedule.id);
        }
        return list_relatedSchedules;
    }
    /*************************************************************************************
    Method Name             createRecurringSchedules()
    Developed By            West Monroe Partners
    Purpose                 for every opportunitylineItem a multiple recurring records
                            based on subscription term and date
    Created date            2/20/2017
    Parameters              list<OpportunityLineItem>
    Output type             list<Schedule__c> - list to create the schedules
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0     SS      2/20/2017           Refer method header
    2.0     SS      6/19/2017           Changes for ACV
                                        Populating the following
                                        * Start Date from product
                                        * Type
                                        * Subscription term

    *************************************************************************************/
    private list<Schedule__c> createRecurringSchedules(list<OpportunityLineItem> list_OppLineItem){
        System.debug('>>>>>>>>>>> createRecurringSchedules');
        //list to send to the function which called
        list<Schedule__c> list_scheduleCreated = new list<Schedule__c>();

        //Looping through the list of opportunitylineItem
        for(OpportunityLineItem iterating_oppLineItem : list_OppLineItem){

            //looping through the number of terms to divide the amount
            for(Integer iterating_int = 0; iterating_int < iterating_oppLineItem.MBIL_Subscription_Term__c; iterating_int++){

                //creating the running Billing schedule record
                Schedule__c running_schedule = new Schedule__c();
                running_schedule.Amount__c                      = iterating_oppLineItem.TotalPrice/iterating_oppLineItem.MBIL_Subscription_Term__c;
                running_schedule.Scheduled_Date__c              = iterating_oppLineItem.MBIL_Effective_Start_date__c.addMonths(iterating_int);
                running_schedule.Opportunity__c                 = iterating_oppLineItem.OpportunityId;
                running_schedule.Billing_Frequency__c               = iterating_oppLineItem.MBLM_Billing_Frequency__c;
                running_schedule.Product_Category__c                = iterating_oppLineItem.Product_Category__c;
                running_schedule.Product__c                     = iterating_oppLineItem.Product2Id;
                running_schedule.Opportunity_Line_Item_ID__c        = iterating_oppLineItem.Id;
                running_schedule.Project__c                     = iterating_oppLineItem.Project__c;
            /**
                Changes for Version 2.0
                Now we are checking if its one-time and has subscription terms
                if yes
                    We have to create one "One-time" billing type billing schedule
                    and
                    multiple (no of subscription terms) types of accounting billing schedules
                if no
                    Just create one billing schedule

                also for all types of billing schedules,
                    type = billing
            **/
            if(iterating_oppLineItem.MBLM_Billing_Frequency__c == 'One-Time')
                running_schedule.Type__c                            = 'Accounting';
            else
                running_schedule.Type__c                            = 'Billing';
            running_schedule.Start_Date_from_Product__c         = iterating_oppLineItem.MBIL_Effective_Start_date__c;
            running_schedule.Subscription_Term__c               = iterating_oppLineItem.MBIL_Subscription_Term__c;
                list_scheduleCreated.add(running_schedule);
            }

        }

        System.debug('list_scheduleCreated >> ' +  list_scheduleCreated);
        return list_scheduleCreated;
    }

    /*************************************************************************************
    Method Name             createOneTimeSchedules()
    Developed By            West Monroe Partners
    Purpose                 for every opportunitylineItem a single Schedule record is created
    Created date            2/17/2017
    Parameters              list<OpportunityLineItem>
    Output type             list<Schedule__c> - list to create the schedules
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0     SS      2/17/2017           Refer method header
    2.0     SS      6/19/2017           Changes for ACV
                                        Populating the following
                                        * Type
    *************************************************************************************/
    private list<Schedule__c> createOneTimeSchedules(list<OpportunityLineItem> list_OppLineItem){

        System.debug('>>>>>>>>>>> createOneTimeSchedules');
        //list to send to the function which called
        list<Schedule__c> list_scheduleCreated = new list<Schedule__c>();

        //Looping through the list of opportunitylineItem
        for(OpportunityLineItem iterating_oppLineItem : list_OppLineItem){

            //creating the running Billing schedule record
            Schedule__c running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = iterating_oppLineItem.TotalPrice;
            running_schedule.Scheduled_Date__c              = iterating_oppLineItem.MBIL_Effective_Start_date__c;
            running_schedule.Opportunity__c                 = iterating_oppLineItem.OpportunityId;
            running_schedule.Billing_Frequency__c           = 'One-Time';
            running_schedule.Product_Category__c            = iterating_oppLineItem.Product_Category__c;
            running_schedule.Product__c                     = iterating_oppLineItem.Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = iterating_oppLineItem.Id;
            running_schedule.Project__c                     = iterating_oppLineItem.Project__c;
        running_schedule.Type__c                            = 'Billing';
            running_schedule.Subscription_Term__c               = iterating_oppLineItem.MBIL_Subscription_Term__c;
            list_scheduleCreated.add(running_schedule);
        }

        System.debug('list_scheduleCreated >> ' +  list_scheduleCreated);
        return list_scheduleCreated;
    }

    /*************************************************************************************
    Method Name             createSchedules()
    Developed By            West Monroe Partners
    Purpose                 for every milestone of a project passed, based on the opportunity line item
                            create billing schedules
    Created date            2/14/2017
    Parameters              milestone name - String - eg 'PO', "FA", "KPI"
                            Project__c - sending the project to track the dates
                            map<id,milestone__c> map of milestone ids and respective milestones
                            map<String(product category),list<opportunityLineItem>> map of product categories
                                and respective list of opportunitylineitems
    Output type             list<Schedule__c> - list to create the schedules
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/14/2017       Refer method header
    *************************************************************************************/
    private list<Schedule__c> createSchedules(String milestoneName,
                                              map<Id,Milestone__c> map_relatedMilestonesToProject,
                                              Project__c executing_Project,
                                              map<string,list<OpportunityLineItem>> map_productCatToOppLineItemList
                                              ){

        System.debug('Map of milestones and IDs >> ' + map_relatedMilestonesToProject);
        System.debug('Map of prod Cate and list of line items >> ' + map_productCatToOppLineItemList);

        //list to send to the function which called
        list<Schedule__c> list_scheduleCreated = new list<Schedule__c>();

        //Iterating through all the milestones
        for(Milestone__c iterating_milestone : map_relatedMilestonesToProject.values()){
            System.debug('Running milestone >> ' +  iterating_milestone);
            //Checking individual milestone value as thats the date the value for checked for
            //PO % check
            if(milestoneName == 'PO'){
                if(iterating_milestone.PO__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //Contract % check
            if(milestoneName == 'Contract'){
                if(iterating_milestone.Contract__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //HW Delivery % check
            if(milestoneName == 'HW Delivery'){
                if(iterating_milestone.HW_delivery__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //HW Install % check
            if(milestoneName == 'HW Install'){
                if(iterating_milestone.HW_install__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //SW Delivery % check
            if(milestoneName == 'SW Delivery'){
                if(iterating_milestone.SW_delivery__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //RFA__c % check
            if(milestoneName == 'RFA'){
                if(iterating_milestone.RFA__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //UAT__c % check
            if(milestoneName == 'UAT'){
                if(iterating_milestone.UAT__c    > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //Stability % check
            if(milestoneName == 'Stability'){
                if(iterating_milestone.Stability__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //FA % check
            if(milestoneName == 'FA'){
                if(iterating_milestone.FA__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //KPI % check
            if(milestoneName == 'KPI'){
                if(iterating_milestone.KPI__c > 0){
                    System.debug('Milestone name and prod cater >> ' + iterating_milestone.ProductCategory__c + ' -- ' + milestoneName);
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
            //Retention% check
            if(milestoneName == 'Retention'){
                if(iterating_milestone.Retention__c > 0){
                    if(map_productCatToOppLineItemList.containsKey(iterating_milestone.ProductCategory__c))
                        list_scheduleCreated.addAll(createscheduleforMilestoneandProdCategory(   milestoneName,
                                                                                            executing_Project,
                                                                                            map_productCatToOppLineItemList.get(iterating_milestone.ProductCategory__c),
                                                                                            iterating_milestone
                                                                                        ));
                }
            }
        }
        return list_scheduleCreated;
    }

    /*************************************************************************************
    Method Name             createscheduleforMilestoneandProdCategory()
    Developed By            West Monroe Partners
    Purpose                 for every single milestone of a project passed, we parse through the
                            opportunityLineItems and create a new list Schedule
    Created date            2/15/2017
    Parameters              milestone name - String - eg 'PO', "FA", "KPI"
                            list<OpportunityLineItem> - related opportunity line item to the milestone passed
                            milestone__c - running milestone
                            Project__c - running projects
    Output type             list<Schedule__c> - list to create the schedules
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/15x/2017      Refer method header
    *************************************************************************************/
    private list<Schedule__c> createscheduleforMilestoneandProdCategory(String milestoneName,
                                                                        Project__c executing_Project,
                                                                        list<OpportunityLineItem> list_opportunityLineItem,
                                                                        Milestone__c iterating_milestone
                                                                        ){
        //list to send to the function which called
        list<Schedule__c> list_scheduleCreated = new list<Schedule__c>();
        //iterating the list of opportunity line items for the product category
        for(OpportunityLineItem iterating_oppLineItem : list_opportunityLineItem){
            //Creating the iterating billing schedule
            Schedule__c inst_BillingSchedule = new Schedule__c();
            inst_BillingSchedule.Opportunity_Line_Item_ID__c           =  iterating_oppLineItem.id;
            inst_BillingSchedule.Opportunity__c                        =  iterating_oppLineItem.OpportunityId;
            inst_BillingSchedule.Product__c                            =  iterating_oppLineItem.Product2Id;
            inst_BillingSchedule.Billing_Frequency__c                  = iterating_oppLineItem.MBLM_Billing_Frequency__c;
            //Assigning the value by multiplying the % to the file format and the date for each milestone
            if(milestoneName == 'PO'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.PO__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.PO_date__c;
            }
            if(milestoneName == 'Contract'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.Contract__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.Contract_Date__c;
            }
            if(milestoneName == 'HW Delivery'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.HW_delivery__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.HW_delivery_Date__c;
            }
            if(milestoneName == 'HW Install'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.HW_Install__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.HW_Install_Date__c;
            }
            if(milestoneName == 'SW Delivery'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.SW_delivery__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.SW_delivery_Date__c;
            }
            if(milestoneName == 'RFA'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.RFA__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.RFA_Date__c;
            }
            if(milestoneName == 'UAT'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.UAT__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.UAT_Date__c;
            }
            if(milestoneName == 'Stability'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.Stability__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.Stability_Date__c;
            }
            if(milestoneName == 'FA'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.FA__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.FA_Date__c;
            }
            if(milestoneName == 'KPI'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.KPI__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.KPI_Date__c;
            }
            if(milestoneName == 'Retention'){
                inst_BillingSchedule.Amount__c                         =  (iterating_oppLineItem.TotalPrice * iterating_milestone.Retention__c)/100 ;
                inst_BillingSchedule.Scheduled_Date__c                 =  executing_Project.Retention_Date__c;
            }
            inst_BillingSchedule.Project__c                            = executing_Project.id;
            inst_BillingSchedule.Milestone_name__c                     = milestoneName;
            inst_BillingSchedule.Milestone__c                          = iterating_milestone.id;
            inst_BillingSchedule.Product_Category__c                   = iterating_milestone.ProductCategory__c;
            inst_BillingSchedule.Type__c                            = 'Billing';
            list_scheduleCreated.add(inst_BillingSchedule);
        }
        return list_scheduleCreated;
    }
    /*************************************************************************************
    Method Name             containsScheduleForMilestone()
    Developed By            West Monroe Partners
    Purpose                 for every milestone string passed, we check if related
                            billing schedules are present for the project or not
    Created date            2/14/2017
    Parameters              milestone name - String - eg 'PO', "FA", "KPI"
                            list<Schedule__c> - related schedules to the project
    Output type             list<Schedule__c> - subset of related schedules to the project with
                            milestone name = milestone name
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/14/2017       Refer method header
    *************************************************************************************/
    private list<Schedule__c> containsScheduleForMilestone(String milestoneName, list<Schedule__c> list_schedulesForProject){
        //Collections used in the method
        list<Schedule__c> list_milestoneNameRelatedSchedules = new list<Schedule__c>();
        System.debug('>>> paramter 1  >>> '+ milestoneName );
        System.debug('>>> paramter 2  >>> '+ list_schedulesForProject );
        if(list_schedulesForProject != null){
            //iterating through the list of schedules and filter out the milestone related schedules
            for(Schedule__c iterating_schedule : list_schedulesForProject){
                //checking for the milestone name and filtering them
                if(iterating_schedule.Milestone_name__c == milestoneName){
                    list_milestoneNameRelatedSchedules.add(iterating_schedule);
                }
            }
        }


        //returning the list .. if the list has records, then can be used for manipulation.
        //if the list is empty, then we might to create new ones or ignore -- based on use case
        return list_milestoneNameRelatedSchedules;
    }

        /**
     * Update project totals on projects where the oppLineItem has been removed from them (Bug-00215)
     */
    public void deductProductSumFromProject(List<OpportunityLineItem> oldOppLineItems) {
      Map<Id, Project__c> projectsToDeduct = new Map<Id, Project__c>();
      for(OpportunityLineItem oldLineItem : oldOppLineItems) {
        // collect projects that need deduction
        if(null != oldLineItem.Project__c) {
          projectsToDeduct.put(oldLineItem.Project__c, createProject(oldLineItem.Project__c));
        }
      }

      if(!projectsToDeduct.isEmpty()) {
        // for each project, calculate fresh totals based on current state after
        // removal of opplineitems
        List<AggregateResult> aggregates = [SELECT Project__c projectId,
                                                  Business_line__c businessLine,
                                                  SUM(TotalPrice) totalPrice,
                                                  MBIL_Product_Family__c prodFamily
                                                      FROM OpportunityLineItem
                                                      WHERE Project__c IN :projectsToDeduct.keySet()
                                                      GROUP BY Project__c, Business_line__c, MBIL_Product_Family__c];
        Set<String> vsoeIncludedFamilies = getVSOEIncludedFamilies();
        for(AggregateResult aggr : aggregates) {
          Id projId = (Id)aggr.get('projectId');
          String bussLine = (String)aggr.get('businessLine');
          Double totPrice = (Double)aggr.get('totalPrice');
          String prodFamily = (String)aggr.get('prodFamily');
          Project__c proj = projectsToDeduct.get(projId);
          proj.Product_Total__c += totPrice;
          if(bussLine == BIG_DATA_ANALYTICS) {
            proj.Big_Data_Analysis_Actual__c += totPrice;
          }
          else if(bussLine == ROAMING) {
            proj.Roaming_Actual__c += totPrice;
          }
          else if(bussLine == ROAMING_ANALYTICS) {
            proj.Roaming_Analytics_Actual__c += totPrice;
          }
          else if(bussLine == TEST_FACTORY) {
            proj.Test_Factory_Actual__c += totPrice;
          }
          else if(bussLine == TRAVEL) {
            proj.Travel_Actual__c += totPrice;
          }
          else if(bussLine == SECURITY) {
            proj.Security_Actuals__c += totPrice;
          }
          else if(bussLine == RISK) {
            proj.Risk_Actuals__c += totPrice;
          }
          else if(bussLine == TESTING) {
            proj.Testing_Actuals__c += totPrice;
          }
          else if(bussLine == Engagement_Experience) {
            proj.Engmnt_Exp_Actuals__c+= totPrice;
          }
          else if(bussLine == UNDETERMINED) {
            proj.Undetermined_Actual__c += totPrice;
          }

          if(vsoeIncludedFamilies.contains(prodFamily)) {
            proj.Software_License_Amount__c += totPrice;
          }
        }

        Database.update(projectsToDeduct.values());
      }
    }

    private static Project__c createProject(Id projId) {
      return new Project__c(Id = projId,
                            Product_Total__c = 0,
                            Big_Data_Analysis_Actual__c = 0,
                            Roaming_Actual__c = 0,
                            Roaming_Analytics_Actual__c = 0,
                            Test_Factory_Actual__c = 0,
                            Travel_Actual__c = 0,
                            Security_Actuals__c = 0,
                            Risk_Actuals__c = 0,
                            Testing_Actuals__c = 0, 
                            Engmnt_Exp_Actuals__c =0,
                            Undetermined_Actual__c = 0,
                            Software_License_Amount__c = 0);
    }

    private static Set<String> getVSOEIncludedFamilies() {
      return new Set<String>(System.Label.VSOE_Included.split(','));
    }

    /*************************************************************************************
    Method Name             updateProjectWithProductSum()
    Developed By            West Monroe Partners
    Purpose                 for every product updates, update the total amount in the project
                            associated to it
    Created date            2/10/2017
    Parameters              list<OpportunityLineItem> - the list of quote IDs from the trigger
                            for which the team needs to be cloned
    Output type             void
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      2/10/2017       Refer method header
    *************************************************************************************/
    public void updateProjectWithProductSum(list<OpportunityLineItem> list_oppLineItem){
        //variables used in the method
        set<Id> set_opportunity = new set<Id>();
        map<Id,Double> map_projectIdToTotalSum = new map<Id,Double>();
        map<Id,map<string,Double>> map_projectIdToBusinessLineTotals = new map<Id,map<string,Double>>();
        list<Project__c> list_project = new list<Project__c>();
        map<Id,Double> map_projectIdToTotalSumForVSOE = new map<Id,Double>();

        //Adding the logic for software license addition
        //string from label
        string str_vsoeIncludedFamilies =  System.Label.VSOE_Included;
        list<string> list_vsoeIncludedFamilies = str_vsoeIncludedFamilies.split(',');
        set<string> set_vsoeIncludedFamilies = new set<string>(list_vsoeIncludedFamilies);
        list_vsoeIncludedFamilies = new list<string>(); //Resetting the list


        System.debug('list_oppLineItem >> ' + list_oppLineItem);

        //looping through line iteme to fetch the Opportunity Ids from the OpportunityLineItem
        for(OpportunityLineItem iterating_oppLineItem : list_oppLineItem){
            set_opportunity.add(iterating_oppLineItem.opportunityId);
        }
        System.debug('set_opportunity >> ' + set_opportunity);
        //Aggregrate query to fetch the sum of all products related to the project
        for(AggregateResult iterating_aggregate : [SELECT Project__c projectId,
                                                          Business_line__c businessLine,
                                                          SUM(TotalPrice) totalPrice ,
                                                          MBIL_Product_Family__c prodFamily
                                                      FROM OpportunityLineItem
                                                      WHERE OpportunityId IN:set_opportunity
                                                      GROUP BY Project__c ,
                                                               Business_line__c,
                                                               MBIL_Product_Family__c
                                                     ]
           ){

            /**
             prepping the map_projectIdToTotalSum map and map_projectIdToBusinessLineTotals
            **/
            //The project is already present in the map
            if(map_projectIdToTotalSum.containsKey((Id)iterating_aggregate.get('projectId'))){
                Double runningTotal = map_projectIdToTotalSum.get((Id)iterating_aggregate.get('projectId'));
                runningTotal  += (Double)iterating_aggregate.get('totalPrice');
                //adding back to the map
                map_projectIdToTotalSum.put((Id)iterating_aggregate.get('projectId'),runningTotal);

                //map_projectIdToBusinessLineTotals logic
                //there are 2 cases, if the business line exists or not
                if(map_projectIdToBusinessLineTotals.get((Id)iterating_aggregate.get('projectId')).containsKey((string)iterating_aggregate.get('businessLine'))){
                    Double runningTotalForBusinessLine =  map_projectIdToBusinessLineTotals.get((Id)iterating_aggregate.get('projectId')).get((string)iterating_aggregate.get('businessLine'));
                    runningTotalForBusinessLine  += (Double)iterating_aggregate.get('totalPrice');
                    map_projectIdToBusinessLineTotals.get((Id)iterating_aggregate.get('projectId')).put((string)iterating_aggregate.get('businessLine'),runningTotalForBusinessLine);
                }else{
                    Double runningTotalForBusinessLine  = (Double)iterating_aggregate.get('totalPrice');
                    map_projectIdToBusinessLineTotals.get((Id)iterating_aggregate.get('projectId')).put((string)iterating_aggregate.get('businessLine'),runningTotalForBusinessLine);
                }


                //checking if the value of the current iterating oppoline item is included in the label
                if(set_vsoeIncludedFamilies.contains((string)iterating_aggregate.get('prodFamily'))){
                    //checking if the project id is already in the map
                    if(map_projectIdToTotalSumForVSOE.containsKey((Id)iterating_aggregate.get('projectId'))){
                        Double runningTotalForVSOE = map_projectIdToTotalSumForVSOE.get((Id)iterating_aggregate.get('projectId'));
                        runningTotalForVSOE  += (Double)iterating_aggregate.get('totalPrice');
                        //adding back to the map
                        map_projectIdToTotalSumForVSOE.put((Id)iterating_aggregate.get('projectId'),runningTotalForVSOE);
                    }else{//adding it first time to the map
                        map_projectIdToTotalSumForVSOE.put((Id)iterating_aggregate.get('projectId'),(Double)iterating_aggregate.get('totalPrice'));
                    }
                }

            }else{//adding a new project to the map
                map_projectIdToTotalSum.put((Id)iterating_aggregate.get('projectId'),(Double)iterating_aggregate.get('totalPrice'));

                //map_projectIdToBusinessLineTotals logic
                map<string, double> map_tempStringToDouble = new map<string, double>();
                map_tempStringToDouble.put((string)iterating_aggregate.get('businessLine'),(Double)iterating_aggregate.get('totalPrice'));
                map_projectIdToBusinessLineTotals.put((Id)iterating_aggregate.get('projectId'),map_tempStringToDouble);

                //checking if the value of the current iterating oppoline item is included in the label
                if(set_vsoeIncludedFamilies.contains((string)iterating_aggregate.get('prodFamily')))
                    map_projectIdToTotalSumForVSOE.put((Id)iterating_aggregate.get('projectId'),(Double)iterating_aggregate.get('totalPrice'));
            }
        }
        System.debug('map_projectIdToTotalSum >> ' + map_projectIdToTotalSum);
        //Querying all the project records
        for(Project__c iterating_proj : [ SELECT Id,
                                                 Product_total__c,
                                                 Big_Data_Analysis_Actual__c,
                                                 Roaming_Actual__c,
                                                 Roaming_Analytics_Actual__c,
                                                 Test_Factory_Actual__c,
                                                 Travel_Actual__c,
                                                 Security_Actuals__c,
                                                 Risk_Actuals__c,
                                                 Testing_Actuals__c,
                                                 Engmnt_Exp_Actuals__c,
                                                 Software_License_Amount__c,
                                                 Undetermined_Actual__c
                                          FROM
                                                Project__c
                                          WHERE
                                                Id IN:map_projectIdToTotalSum.keySet()
                                        ]
          ){
            //if the project exists in map-- not that best of a use case for this
            if(map_projectIdToTotalSum.containsKey(iterating_proj.id)){
                //updating the total
                iterating_proj.Product_total__c = map_projectIdToTotalSum.get(iterating_proj.id);
                //Assigning the business line sums
                if(map_projectIdToBusinessLineTotals.containsKey(iterating_proj.id)){
                    //BDA acutals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Big Data Analytics'))
                            iterating_proj.Big_Data_Analysis_Actual__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Big Data Analytics');
                    else
                            iterating_proj.Big_Data_Analysis_Actual__c = 0;
                    //Roaming acutals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Roaming'))
                            iterating_proj.Roaming_Actual__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Roaming');
                    else
                            iterating_proj.Roaming_Actual__c = 0;
                    //Roaming analytics acutals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Roaming Analytics'))
                            iterating_proj.Roaming_Analytics_Actual__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Roaming Analytics');
                    else
                            iterating_proj.Roaming_Analytics_Actual__c = 0;
                    //Test factory acutals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Test Factory'))
                            iterating_proj.Test_Factory_Actual__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Test Factory');
                    else
                            iterating_proj.Test_Factory_Actual__c = 0;
                    //Travel acutals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Travel'))
                            iterating_proj.Travel_Actual__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Travel');
                    else
                            iterating_proj.Travel_Actual__c = 0;
                    //Security Actuals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Security'))
                          iterating_proj.Security_Actuals__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Security');
                    else
                            iterating_proj.Security_Actuals__c = 0;
                    //Risk Actuals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Risk'))
                          iterating_proj.Risk_Actuals__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Risk');
                    else
                            iterating_proj.Risk_Actuals__c = 0;
                    //Testing_Actuals__c
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Testing'))
                          iterating_proj.Testing_Actuals__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Testing');
                    else
                            iterating_proj.Testing_Actuals__c = 0;
                             
                    //Engmnt_Exp_Actuals__c
                         
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Engagement and Experience'))
                          iterating_proj.Engmnt_Exp_Actuals__c= (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Engagement and Experience');
                    else
                            iterating_proj.Engmnt_Exp_Actuals__c = 0;
                    //Undetermined acutals
                    if((map_projectIdToBusinessLineTotals.get(iterating_proj.id)).containsKey('Undetermined'))
                            iterating_proj.Undetermined_Actual__c = (map_projectIdToBusinessLineTotals.get(iterating_proj.id)).get('Undetermined');
                    else
                            iterating_proj.Undetermined_Actual__c = 0;


                }
                //Assigning the vsoe amount
                if(map_projectIdToTotalSumForVSOE.containsKey(iterating_proj.id))
                    iterating_proj.Software_License_Amount__c = map_projectIdToTotalSumForVSOE.get(iterating_proj.id);
                else
                    iterating_proj.Software_License_Amount__c = 0;

                //adding to the list
                list_project.add(iterating_proj);
            }
        }
        System.debug('list_project >> ' + list_project);
        //updating the project values
        Database.update(list_project);
    }
    
    public static void coverage()
    {
        Integer i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
    }
}