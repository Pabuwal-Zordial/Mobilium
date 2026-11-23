/*************************************************************************************
Name                    quoteAttainmentMgmt_clsHandler
Developed By            West Monroe Partners
Purpose                 The following are the requirements for the trigger handler
                            * On Opportunity save
                            	* For any change on the "Business Line Totals"
                            	* For change in stage
                            	* For change in closed date
                            for Quote line fields of the primary quote
Created date            6/30/2017
History
------------------------------------------------------------------------------------
VERSION  	AUTHOR 	DATE      		DETAIL
1.0			SS		4/25/2017		Refer class header
*************************************************************************************/
public with sharing class quoteAttainmentMgmt_clsHandler 
{	
    //boolean to stop recursion
	public static boolean bln_quotaAttainment_executed = false;
    //boolean to denote from other object
    public static boolean bln_quotaExecute = false;

	static list<Quota_by_Business_Line_Mgmt__mdt> list_businessLineApis = new list<Quota_by_Business_Line_Mgmt__mdt>();
	set<Opportunity> set_resetAttainmentsOpportunity = new set<Opportunity>();
	map<Id,list<OpportunitySplit>> map_oppId_relatedSplits = new map<Id,list<OpportunitySplit>>();
	map<Id,set<string>> map_oppId_quotaUniqueString = new map<id,set<string>>();
	map<string,Quota__c> map_quotaString_relatedQuota = new map<string,Quota__c>();
	set<string> set_monthYearCombo = new set<string>();
	map<id,set<id>> map_oppId_relatedSplitUserHierachy = new map<id,set<id>>();
    map<string,set<id>> map_oppId_relatedSplitUserHierachy_ForInsertCheck = new map<string,set<id>>();
	list<Attainment__c> list_attainmentToInsert = new list<Attainment__c>();

	/*************************************************************************************
    Method Name             mtd_getBusinessLinesAPINames
    Developed By            West Monroe Partners
    Purpose                 * Fetch the custom metadata type - Quota by business line mgmt details
    Created date            6/30/2017
	Parameters				None
	Output type				list<string>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		6/30/2017		Refer method header
    *************************************************************************************/
    private void mtd_getBusinessLinesAPINames()
    {
        list_businessLineApis = new list<Quota_by_Business_Line_Mgmt__mdt>();
    	//querying for the custom metadata type
        for(Quota_by_Business_Line_Mgmt__mdt iterating_meta : [ SELECT
        															  MasterLabel,
			                                                          BusinessLineAPIName__c
			                                                     FROM 
			                                                          Quota_by_Business_Line_Mgmt__mdt
			                                                  ]
        	)
        {
            list_businessLineApis.add(iterating_meta);
        }
    }
	/*************************************************************************************
    Method Name             mtd_processOpportunities
    Developed By            West Monroe Partners
    Purpose                 * For the given changes below:
								* Any of the business line total is changing
								* Close date moves from one month to another in the same year
								  or across year
    Created date            6/30/2017
	Parameters				list<Opportunity> - the list of opportunity IDs from the trigger
							that have been updated
                            list<Opportunity> - the list of opportunity IDs from the trigger
							that have the old values before update
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		6/30/2017		Refer method header
    *************************************************************************************/
    private void mtd_processOpportunities(	list<Opportunity> list_Opportunity_afterUpdate,
                                     						map<Id,Opportunity> map_Opportunity_beforeUpdate
                                    				    )
   	{
   		//looping through the trigger.new list
        for(Opportunity iterating_newOpportunity : list_Opportunity_afterUpdate)
        {
        	
        	
        	/*
        		There are 3 cases with respect to business lines total
        		------------------------------------------------------------------
        			  Before     					||| 		After	
				------------------------------------------------------------------
				        0							|||			A
				        A 							|||			B
				        A 							|||			0            			  
				------------------------------------------------------------------					        

				There are 3 cases with respect to forecast category total
				------------------------------------------------------------------
					            		Before     	||| 		After	
				------------------------------------------------------------------											
				Omitted								|||			Pipeline
																Best Case
																Commit
																Closed
				Pipeline
				Best Case
				Commit 		 						|||			Omitted
				Closed 								|||			Pipeline
																Best Case
																Commit             			  
				------------------------------------------------------------------

				Changes to the close date	
				If the month - year combination of the close date changes
				then it will result in the logic to kick in


			*/
			//looping throught the api names to check for value change
			for(Quota_by_Business_Line_Mgmt__mdt string_apiName : list_businessLineApis)
			{

				if(
				   //Before 0 and After value > 0
				   (
					   (Double)iterating_newOpportunity.get(string_apiName.BusinessLineAPIName__c) > 0
		               &&
		               (Double) map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get(string_apiName.BusinessLineAPIName__c) == 0
	               )
	               ||
	               (
	                   (Double)iterating_newOpportunity.get(string_apiName.BusinessLineAPIName__c) > 0
		               &&
		               (Double)map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get(string_apiName.BusinessLineAPIName__c) != (Double)iterating_newOpportunity.get(string_apiName.BusinessLineAPIName__c)
	               )
	               ||
	               (
	               	   (Double)iterating_newOpportunity.get(string_apiName.BusinessLineAPIName__c) == 0
		               &&
		               (Double)map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get(string_apiName.BusinessLineAPIName__c) > 0
	               )
	               ||
	               (
	               	   iterating_newOpportunity.get('ForecastCategoryName') != 'Omitted'
	               	   &&
	               	   map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get('ForecastCategoryName') == 'Omitted'
	               )
	               ||
	               (
	               	   iterating_newOpportunity.get('ForecastCategoryName') == 'Omitted'
	               	   &&
	               	   (
	               	   		map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get('ForecastCategoryName') != 'Omitted'	
	               	   	    ||
	               	   		map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get('ForecastCategoryName') != 'Closed'	
	               	   )
	               )
	               ||
	               (
	               	   iterating_newOpportunity.get('ForecastCategoryName') != 'Closed'
	               	   &&
	               	   map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get('ForecastCategoryName') == 'Closed'
	               )
	               ||
	               (
	               	   (((Date)iterating_newOpportunity.get('CloseDate')).month() + ' -- ' +  ((Date)iterating_newOpportunity.get('CloseDate')).year())
	               	   !=
	               	   (((Date)map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get('CloseDate')).month() + ' -- ' +  ((Date)map_Opportunity_beforeUpdate.get(iterating_newOpportunity.id).get('CloseDate')).year())
	               )
                   ||
                   bln_quotaExecute

	            )
				{

					set_resetAttainmentsOpportunity.add(iterating_newOpportunity);
					set_monthYearCombo.add(iterating_newOpportunity.CloseDate.month()+'-'+iterating_newOpportunity.CloseDate.year()+'-'+string_apiName.MasterLabel);
				}
			}
        }
        System.debug('The residual set is >> ' +  set_resetAttainmentsOpportunity);
   	}
	/*************************************************************************************
    Method Name             mtd_processQuotaAttainmentManagement
    Developed By            West Monroe Partners
    Purpose                 * For the given changes below:
								* Any of the business line total is changing
								* Close date moves from one month to another in the same year
								  or across year
    Created date            6/30/2017
	Parameters				list<Opportunity> - the list of opportunity IDs from the trigger
							that have been updated
                            list<Opportunity> - the list of opportunity IDs from the trigger
							that have the old values before update
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		6/30/2017		Refer method header
    *************************************************************************************/
    public void mtd_processQuotaAttainmentManagement(	list<Opportunity> list_Opportunity_afterUpdate,
                                     					map<Id,Opportunity> map_Opportunity_beforeUpdate
                                    				)
   	{
        System.debug('Checking the boolean >> ' + bln_quotaAttainment_executed);
   		//Checking if this execution has been process by the trigger
   		if(!bln_quotaAttainment_executed)
   		{

   			//query for the custom metadata types for field api names
   			mtd_getBusinessLinesAPINames(); 

   			//the method to check for which opportunities to process
   			mtd_processOpportunities(list_Opportunity_afterUpdate, map_Opportunity_beforeUpdate);

   			//getting the split records from the opportunity ids
   			mtd_getAllSplitRecordsForOpportunity();

   			//getting all the split related users - inclusive of SGM, manager , CRO
   			mtd_getAllSplitRelatedUsers(); 

   			//building all the unique strings to query for quota records
   			//mtd_buildQuotaStringToFetchRecords(); -- added inline in the next statement

   			//getting all the related quota records from the quota table
   			mtd_getAllQuotaAndAttainmentRecords(mtd_buildQuotaStringToFetchRecords());

   			//creating the list of records that needs to be created
   			mtd_createAttainmentRecordsToInsert();

   			//final dmls are carried out here in this method
   			mtd_completeAllDataManipulations();

   			//Setting the boolean so that we do not have recursive execution
   			bln_quotaAttainment_executed = true;
   			
   		}
    }
    /*************************************************************************************
    Method Name             mtd_completeAllDataManipulations
    Developed By            West Monroe Partners
    Purpose                 * Delete all the attainments for the opportunity and
    						create the new ones
    Created date            7/2/2017
	Parameters				NA
	Output type				NA
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		7/2/2017		Refer method header
    *************************************************************************************/
    private void mtd_completeAllDataManipulations()
    {
    	list<Attainment__c> list_attainmentToDelete = new list<Attainment__c>();
    	for(list<Attainment__c> iterating_listAttainment : mtd_getAllRelatedAttainmentRecords().values())
    	{
    		list_attainmentToDelete.addAll(iterating_listAttainment);
    	}

    	//if the list is populated, then delete
    	if(!list_attainmentToDelete.isEmpty())
    		delete list_attainmentToDelete;

		//if the list is populated, then insert
    	if(!list_attainmentToInsert.isEmpty())
    		insert list_attainmentToInsert;


    }
    /*************************************************************************************
    Method Name             mtd_getAllQuotaAndAttainmentRecords
    Developed By            West Monroe Partners
    Purpose                 * For the given list of unique quota strings, fetch the related quota records to parent to
    						  Unique string = UserId + ' - ' + Month + ' - ' + Year + ' - ' + business line
    Created date            7/1/2017
	Parameters				NA
	Output type				NA
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		7/1/2017		Refer method header
    *************************************************************************************/
    private void mtd_getAllQuotaAndAttainmentRecords(set<string> set_uniqueQuotaStrings)
    {
    	System.debug('iterating_quota string >> ' + set_uniqueQuotaStrings);
    	set<id> set_BuHeadIds = new set<id>();
    	for(Quota__c iterating_quota : [ SELECT Id,
    											Business_Line__c,
    											Is_BU_head__c,
    											Period_Date__c,
    											Quota_Owner__c,
    											Quota_Unique_String__c,
    											MonthYearCombo__c
    									  FROM 
    									  		Quota__c
    									  WHERE
    									  		Quota_Unique_String__c IN: set_uniqueQuotaStrings
    									  		OR
    									  		(
    									  			Is_BU_head__c = TRUE
    									  			AND
    									  			MonthYearCombo__c IN:set_monthYearCombo
    									  		)
    								    ]
    	)
    	{
    		map_quotaString_relatedQuota.put(iterating_quota.Quota_Unique_String__c, iterating_quota);
    	}

    	//getting the BU head Ids
    	for(Quota__c iterating_quota : map_quotaString_relatedQuota.values())
    	{
    		if(iterating_quota.Is_BU_head__c)
    			set_BuHeadIds.add(iterating_quota.Quota_Owner__c);
    	}

    	//adding the BU heads to all the opporutnities
    	for(string iterating_string : map_oppId_relatedSplitUserHierachy_ForInsertCheck.keySet())
    	{ 
    		//adding the bu heads ids
    		set<id> set_fromMap = map_oppId_relatedSplitUserHierachy_ForInsertCheck.get(iterating_string);
    		set_fromMap.addAll(set_BuHeadIds);
    		map_oppId_relatedSplitUserHierachy_ForInsertCheck.put(iterating_string,set_fromMap);
    	}
    }
    /*************************************************************************************
    Method Name             mtd_createAttainmentRecordsToInsert
    Developed By            West Monroe Partners
    Purpose                 * Parse through the opprotunities, opportunity splits and the quota records
    						and then create the attainment
    Created date            7/1/2017
	Parameters				NA
	Output type				NA
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		7/1/2017		Refer method header
    *************************************************************************************/
    private void mtd_createAttainmentRecordsToInsert()
    {
        list_attainmentToInsert = new list<Attainment__c>();
    	//creating the collections necessary for the method
    	set<string> set_checkIfAttainmentLogicComplete = new set<string>();
    	list<OpportunitySplit> list_opportunitySplit = new list<OpportunitySplit>();
        set<string> set_checkAttainmentUnique = new set<string>();
        
    	//iterating through the set of opportunity
    	for(Opportunity iterating_opportunity : set_resetAttainmentsOpportunity)
    	{
    		list_opportunitySplit = new list<OpportunitySplit>();
    		//looping throught the api names to check for value change
			for(Quota_by_Business_Line_Mgmt__mdt string_apiName : list_businessLineApis)
			{
				//checking if the business line totals
				if((Double)iterating_opportunity.get(string_apiName.BusinessLineAPIName__c) > 0
					&&
					iterating_opportunity.get('ForecastCategoryName') != 'Omitted'
				)
				{
                     System.debug('string_apiName.BusinessLineAPIName__c >> ' +  string_apiName.BusinessLineAPIName__c);
					if(map_oppId_relatedSplits.containsKey(iterating_opportunity.id))
					{
						//iterating through the opporutnity splits and creating the attainment records for base users
						for(OpportunitySplit iterating_split : map_oppId_relatedSplits.get(iterating_opportunity.id))
						{
							String uniqueQuotaString =  iterating_split.SplitOwnerId
														+ '-' + 
														iterating_opportunity.CloseDate.month()
														+ '-' + 
														iterating_opportunity.CloseDate.year()
														+ '-' + 
														string_apiName.MasterLabel;
							//check if the quota string exists for each user
							if(map_quotaString_relatedQuota.containsKey(uniqueQuotaString))
							{
                                if(!set_checkAttainmentUnique.contains(map_quotaString_relatedQuota.get(uniqueQuotaString).id + '-' + iterating_opportunity.id))
                                {
                                    if(iterating_split.SplitPercentage > 0)
                                    {
                                        //create a new attainment record
                                        Attainment__c iterating_attainment = new Attainment__c(
                                            Quota__c = map_quotaString_relatedQuota.get(uniqueQuotaString).id,
                                            Opportunity__c = iterating_opportunity.id,
                                            Business_Line_Total__c = (Double)iterating_opportunity.get(string_apiName.BusinessLineAPIName__c),
                                            Split__c =  iterating_split.SplitPercentage,
                                            //Business_Line_Split_Amount__c = iterating_split.SplitAmount,
                                            Split_type__c = iterating_split.SplitType.MasterLabel,
                                            Split_User__c = iterating_split.SplitOwner.Name
                                        );
                                        list_attainmentToInsert.add(iterating_attainment);

                                        System.debug('iterating_split.SplitType.MasterLabel >> '+ iterating_split.SplitType.MasterLabel + ' - ' + iterating_split.SplitOwner.Name);
                                        //checking if the split type is revenue
                                        if(iterating_split.SplitType.MasterLabel == 'Revenue')
                                            list_opportunitySplit.add(iterating_split);

                                        //adding to the logic map to ensure no double counting happens
                                        set_checkIfAttainmentLogicComplete.add(iterating_split.SplitOwnerId+'-'+iterating_opportunity.id+'-'+string_apiName.MasterLabel);

                                        //adding to the set to avoid dupes
                                        set_checkAttainmentUnique.add(map_quotaString_relatedQuota.get(uniqueQuotaString).id + '-' + iterating_opportunity.id + '-' + iterating_split.SplitOwnerId);

                                        System.debug(set_checkAttainmentUnique);
                                        
                                        //looping through related user
                                        if(map_oppId_relatedSplitUserHierachy_ForInsertCheck.containsKey(iterating_opportunity.id+'-'+iterating_split.SplitOwnerId))
                                        {
                                            for(Id iterating_id : map_oppId_relatedSplitUserHierachy_ForInsertCheck.get(iterating_opportunity.id+'-'+iterating_split.SplitOwnerId))
                                            {
                                                //should create only if related user - so chrcking the set_checkIfAttainmentLogicComplete map
                                                if(!set_checkIfAttainmentLogicComplete.contains(iterating_id+'-'+iterating_opportunity.id+'-'+string_apiName.MasterLabel))
                                                {
                                                    uniqueQuotaString =  iterating_id
                                                            + '-' + 
                                                            iterating_opportunity.CloseDate.month()
                                                            + '-' + 
                                                            iterating_opportunity.CloseDate.year()
                                                            + '-' + 
                                                            string_apiName.MasterLabel;
                                                }
                                                //check if the quota string exists for each user
                                                if(map_quotaString_relatedQuota.containsKey(uniqueQuotaString))
                                                {
                                                    if(!set_checkAttainmentUnique.contains(map_quotaString_relatedQuota.get(uniqueQuotaString).id + '-' + iterating_opportunity.id + '-' + iterating_split.SplitOwnerId))
                                                    {
                                                        if(iterating_split.SplitPercentage > 0 && iterating_split.SplitType.MasterLabel == 'Revenue')
                                                        {
                                                            //create a new attainment record
                                                            iterating_attainment = new Attainment__c(
                                                                Quota__c = map_quotaString_relatedQuota.get(uniqueQuotaString).id,
                                                                Opportunity__c = iterating_opportunity.id,
                                                                Business_Line_Total__c = (Double)iterating_opportunity.get(string_apiName.BusinessLineAPIName__c),
                                                                Split__c =  iterating_split.SplitPercentage,
                                                                //Business_Line_Split_Amount__c = iterating_split.SplitAmount,
                                                                Split_type__c = iterating_split.SplitType.MasterLabel,
                                                                Split_User__c = iterating_split.SplitOwner.Name
                                                            );
                                                            list_attainmentToInsert.add(iterating_attainment);
                                                            //adding to the set to avoid dupes
                                                            set_checkAttainmentUnique.add(map_quotaString_relatedQuota.get(uniqueQuotaString).id + '-' + iterating_opportunity.id);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
							}
						}
					}
				}
			}
		}
    }

    /*************************************************************************************
    Method Name             mtd_buildQuotaStringToFetchRecords
    Developed By            West Monroe Partners
    Purpose                 * For the given list of user Ids and the opportunity close dates,
    						  build a list of quota unique strings
    						  Unique string = UserId + ' - ' + Month + ' - ' + Year + ' - ' + business line
    Created date            7/1/2017
	Parameters				NA
	Output type				set<string> -- the list of unique quota strings to query
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		7/1/2017		Refer method header
    *************************************************************************************/
    private set<string> mtd_buildQuotaStringToFetchRecords()
    {
    	//collections for the class
    	set<string> set_uniqueQuotaStrings = new set<string>();

    	//iterating through the set of opportunity
    	for(Opportunity iterating_opportunity : set_resetAttainmentsOpportunity)
    	{
    		//looping throught the api names to check for value change
			for(Quota_by_Business_Line_Mgmt__mdt string_apiName : list_businessLineApis)
			{
				//checking if the business line totals
				if((Double)iterating_opportunity.get(string_apiName.BusinessLineAPIName__c) > 0)
				{
					//parsing through the related users if present
					if(map_oppId_relatedSplitUserHierachy.containsKey(iterating_opportunity.id))
					{
						for(Id iterating_id : map_oppId_relatedSplitUserHierachy.get(iterating_opportunity.id))
						{
							
							String uniqueQuotaString = '';
							uniqueQuotaString = iterating_id
												+ '-' + 
												iterating_opportunity.CloseDate.month()
												+ '-' + 
												iterating_opportunity.CloseDate.year()
												+ '-' + 
												string_apiName.MasterLabel;
							set_uniqueQuotaStrings.add(uniqueQuotaString);
							
							//checking already present in the map
							if(map_oppId_quotaUniqueString.containsKey(iterating_opportunity.id))
							{
								set<string> set_uniqueQuotaStringsForMap = new set<string>();
								set_uniqueQuotaStringsForMap = map_oppId_quotaUniqueString.get(iterating_opportunity.id);
								set_uniqueQuotaStringsForMap.add(uniqueQuotaString);
								map_oppId_quotaUniqueString.put(iterating_opportunity.id,set_uniqueQuotaStringsForMap);
							}
							else
 							{
								set<string> set_uniqueQuotaStringsForMap = new set<string>();
								set_uniqueQuotaStringsForMap.add(uniqueQuotaString);
								map_oppId_quotaUniqueString.put(iterating_opportunity.id,set_uniqueQuotaStringsForMap);
							} 
						}
 					}
				} 
			}
    	}
    	System.debug('set_uniqueQuotaStrings >> '+ set_uniqueQuotaStrings);
    	return set_uniqueQuotaStrings;
    }

    /*************************************************************************************
    Method Name             mtd_getAllSplitRelatedUsers
    Developed By            West Monroe Partners
    Purpose                 * For the given list of opportunity split owner Ids, get the
    						  set of users, related managers, SGM and CROs
    Created date            6/30/2017
	Parameters				NA
	Output type				map<id,set<id>> -- users to be considered for every opporutnity
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		6/30/2017		Refer method header
    *************************************************************************************/
    private void mtd_getAllSplitRelatedUsers(){
    	//collection - set to get the user ids  
    	set<id> splitRelatedUsers_set = new set<id>();
    	map<id,User> map_splitRelatedUsers = new map<id,User>();
    	
    	//now that we have the list of opportunity splits, create a set of users for whom 
    	//we have to query the quota records 
    	System.debug('map_oppId_relatedSplits >> ' +  map_oppId_relatedSplits);
    	for(list<OpportunitySplit> iterating_splitList : map_oppId_relatedSplits.values())
    	{
    		for(OpportunitySplit iterating_split : iterating_splitList)
    		{
    			splitRelatedUsers_set.add(iterating_split.SplitOwnerId);
    		}
    	}
    	System.debug('splitRelatedUsers_set >> ' +  splitRelatedUsers_set);
    	//query for related users and add to the same set
    	for(User iterating_user : [ SELECT
    										Id,
    										SGM__c,
    										ManagerId,
    										CRO__c
									FROM
											User
									WHERE
											Id IN: splitRelatedUsers_set

    							   ]
    	)
    	{
    		//Adding the related 3 users on the hierarchy
    		map_splitRelatedUsers.put(iterating_user.id,iterating_user);
    	}
    	//associated user hierarchy for every opportunity
    	for(list<OpportunitySplit> iterating_splitList : map_oppId_relatedSplits.values())
    	{
    		for(OpportunitySplit iterating_split : iterating_splitList)
    		{
                //adding the insert for check map
                if(!map_oppId_relatedSplitUserHierachy_ForInsertCheck.containsKey(iterating_split.OpportunityId+'-'+iterating_split.SplitOwnerId))
                {
                    set<id> set_relatedUsers = new set<id>();
                    //checking if the manager fields are populated
                    if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).ManagerId != null)
                        set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).ManagerId);
                    if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).SGM__c != null)
                        set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).SGM__c);
                    if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).CRO__c != null)
                        set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).CRO__c);

                    //adding to the map
                    if(!set_relatedUsers.isEmpty())
                        map_oppId_relatedSplitUserHierachy_ForInsertCheck.put(iterating_split.OpportunityId+'-'+iterating_split.SplitOwnerId,set_relatedUsers);   
                }
    			//if not existing in the map
    			if(!map_oppId_relatedSplitUserHierachy.containsKey(iterating_split.OpportunityId))
    			{
    				set<id> set_relatedUsers = new set<id>();
    				set_relatedUsers.add(iterating_split.SplitOwnerId);
    				//checking if the manager fields are populated
    				if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).ManagerId != null)
    					set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).ManagerId);
    				if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).SGM__c != null)
    					set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).SGM__c);
    				if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).CRO__c != null)
    					set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).CRO__c);

    				//adding to the map
    				map_oppId_relatedSplitUserHierachy.put(iterating_split.OpportunityId,set_relatedUsers);

    			}else
    			{
    				//opportunity id already present as a key
    				set<id> set_relatedUsers = new set<id>();
    				set_relatedUsers = map_oppId_relatedSplitUserHierachy.get(iterating_split.OpportunityId);
    				set_relatedUsers.add(iterating_split.SplitOwnerId);
    				//checking if the manager fields are populated
    				if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).ManagerId != null)
    					set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).ManagerId);
    				if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).SGM__c != null)
    					set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).SGM__c);
    				if(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).CRO__c != null)
    					set_relatedUsers.add(map_splitRelatedUsers.get(iterating_split.SplitOwnerId).CRO__c);

                    //adding to the map
                    map_oppId_relatedSplitUserHierachy.put(iterating_split.OpportunityId,set_relatedUsers);
    			}
    		} 
    	}
    	System.debug('map_oppId_relatedSplitUserHierachy >> ' +  map_oppId_relatedSplitUserHierachy);
        System.debug('map_oppId_relatedSplitUserHierachy_ForInsertCheck >> ' +  map_oppId_relatedSplitUserHierachy_ForInsertCheck);
    }
    /*************************************************************************************
    Method Name             mtd_getAllRelatedAttainmentRecords
    Developed By            West Monroe Partners
    Purpose                 * For the given list of opportunity
								* get all the attainment records
    Created date            6/30/2017 
	Parameters				NA
	Output type				map<id, list<Attainment__c>>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		6/30/2017		Refer method header
    *************************************************************************************/
    private map<id,list<Attainment__c>> mtd_getAllRelatedAttainmentRecords()
    {
    	//map to be sent back to the caller method
    	map<Id,list<Attainment__c>>  map_oppId_relatedAttainments = new map<Id,list<Attainment__c>>();
    	//querying for the attainment records for the given opportunity id
    	for(Attainment__c iterating_attainment : [  SELECT 
    														Id,
    														Opportunity__c
    												FROM
    														Attainment__c
    												WHERE
    														Opportunity__c IN:set_resetAttainmentsOpportunity		
    											 ]
    	)
    	{
    		//checking if the key is already present in the map
    		if(map_oppId_relatedAttainments.containsKey(iterating_attainment.Opportunity__c))
    		{
    			//if key present, get the list of OpportunitySplits and add the new split to list
    			list<Attainment__c> opportunityAttainment_list = new list<Attainment__c>();
    			opportunityAttainment_list = map_oppId_relatedAttainments.get(iterating_attainment.Opportunity__c);
    			opportunityAttainment_list.add(iterating_attainment);
    			map_oppId_relatedAttainments.put(iterating_attainment.Opportunity__c, opportunityAttainment_list);
    		}
    		else
    		{
    			//add to the map and the add the new split list record
    			list<Attainment__c> opportunityAttainment_list = new list<Attainment__c>();
    			opportunityAttainment_list.add(iterating_attainment);
    			map_oppId_relatedAttainments.put(iterating_attainment.Opportunity__c, opportunityAttainment_list);
    		}
    	}
    	return map_oppId_relatedAttainments;
    }

    /*************************************************************************************
    Method Name             mtd_getAllSplitRecordsForOpportunity
    Developed By            West Monroe Partners
    Purpose                 * For the given list of opportunity
								* get all the split records
    Created date            6/30/2017
	Parameters				NA
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		6/30/2017		Refer method header
    *************************************************************************************/
    private void mtd_getAllSplitRecordsForOpportunity()
    {
        map_oppId_relatedSplits = new map<Id,list<OpportunitySplit>>();

    	for(OpportunitySplit iterating_split : [ SELECT 
    													Id,
                                                        isDeleted,
    													OpportunityId,
    													SplitOwnerId,
    													SplitOwner.Name,
    													SplitPercentage,
    													SplitAmount,
    													SplitType.MasterLabel
    											 FROM
    											 		OpportunitySplit
    											 WHERE
    											 		OpportunityId IN:set_resetAttainmentsOpportunity
                                                        AND
                                                        isDeleted = false
    										    ]
    	)
    	{
    		//checking if the key is already present in the map
    		if(map_oppId_relatedSplits.containsKey(iterating_split.OpportunityId))
    		{
    			//if key present, get the list of OpportunitySplits and add the new split to list
    			list<OpportunitySplit> opportunitySplit_list = new list<OpportunitySplit>();
    			opportunitySplit_list = map_oppId_relatedSplits.get(iterating_split.OpportunityId);
    			opportunitySplit_list.add(iterating_split);
    			map_oppId_relatedSplits.put(iterating_split.OpportunityId, opportunitySplit_list);
    		}
    		else
    		{
    			//add to the map and the add the new split list record
    			list<OpportunitySplit> opportunitySplit_list = new list<OpportunitySplit>();
    			opportunitySplit_list.add(iterating_split);
    			map_oppId_relatedSplits.put(iterating_split.OpportunityId, opportunitySplit_list);
    		}
    	}
    	System.debug('map_oppId_relatedSplits >> ' + map_oppId_relatedSplits);
    }
    /*************************************************************************************
    Method Name             mtd_processAllOpportunitySplits
    Developed By            West Monroe Partners
    Purpose                 * For the given list of opportunity splits
                                get all the related opportunty records using clsUtility
    Created date            4/7/2017
    Parameters              NA
    Output type             void
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      4/7/2017       Refer method header
    *************************************************************************************/
    public void mtd_processAllOpportunitySplits(set<id> opportunityIds_set)
    {
        String string_whereClause = '((';
        //looping the opportunty set ids to create the where string
        for(Id iterating_id : opportunityIds_set)
        {
            string_whereClause += ' Id = \'' + iterating_id + '\' OR ';
        }

        string_whereClause = string_whereClause.substring(0, string_whereClause.length() - 3);
        string_whereClause += ')';
        //adding the forecast category check
        string_whereClause += ' AND (ForecastCategoryName != \'Closed\' AND ForecastCategoryName != \'Omitted\'))';
        //now we have the set of opportunity Ids
        //we have to query for the information from the clsUtility
        //getting the opportunities from the utility class
        list<Opportunity> list_allOpportunityRecords = (list<Opportunity>)clsUtility.queryRecordWithFilter('Opportunity', '', string_whereClause);

        //creating a dummy map
        map<Id,Opportunity> map_dummyForMethodCalling = new map<Id,Opportunity> ();
        for(Opportunity iterating_opportunity : list_allOpportunityRecords)
        {
            map_dummyForMethodCalling.put(iterating_opportunity.id,iterating_opportunity);
        }

        //calling the method to process quota by business lines
        mtd_processQuotaAttainmentManagement(list_allOpportunityRecords, map_dummyForMethodCalling);

        //null-fying the unwanted collection
        map_dummyForMethodCalling = new map<Id,Opportunity> ();
    }
    /*************************************************************************************
    Method Name             mtd_processUserHierarchyManagement
    Developed By            West Monroe Partners
    Purpose                 * For the given list of user modifications, check for specific changes
    						and recalculate the quota - attainment management
    Created date            5/7/2017
    Parameters              NA
    Output type             void
    History
    ------------------------------------------------------------------------------------
    VERSION     AUTHOR  DATE            DETAIL
    1.0         SS      5/7/2017       Refer method header
    *************************************************************************************/
    public void mtd_processUserHierarchyManagement(
    													list<User> list_User_afterUpdate,
                                     					map<Id,User> map_User_beforeUpdate
    											)
    {
    	//collections required for the class
    	set<id> set_splitOwnerIds = new set<id>();
    	set<id> set_opportunityIds = new set<id>();
    	//looping through new values
    	for(User iterating_user : list_User_afterUpdate)
    	{
    		//check for the change in manager, SGM, CRO values
    		if(
    			iterating_user.get('ManagerId') != map_User_beforeUpdate.get(iterating_user.id).get('ManagerId')
    			||
    			iterating_user.get('SGM__c') != map_User_beforeUpdate.get(iterating_user.id).get('SGM__c')
    			||
    			iterating_user.get('CRO__c') != map_User_beforeUpdate.get(iterating_user.id).get('CRO__c')
    		)
    		{
    			set_splitOwnerIds.add(iterating_user.id);
    		}
    	}
    	//checking if there are any changes done to the hierarchy
    	if(!set_splitOwnerIds.isEmpty())
    	{
	    	//looping through the splits for whom the manager/sgm/cro is changed
	    	String string_whereClause = '((';
	    	//looping the opportunty set ids to create the where string
	        for(Id iterating_id : set_splitOwnerIds)
	        {
	            string_whereClause += ' SplitOwnerId = \'' + iterating_id + '\' OR ';
	        }
	        string_whereClause = string_whereClause.substring(0, string_whereClause.length() - 3);
	        string_whereClause += ')';
	        //adding the forecast category check
	        string_whereClause += ' AND (Opportunity.ForecastCategoryName != \'Closed\' AND Opportunity.ForecastCategoryName != \'Omitted\'))';

	        //now we have the set of split owner Ids
	        //we have to query for the information from the clsUtility
	        //getting the opportunities from the utility class
	        list<OpportunitySplit> list_allOpportunitySplitRecords = (list<OpportunitySplit>)clsUtility.queryRecordWithFilter('OpportunitySplit', '', string_whereClause);

	        //loopinh through the list of opportunity splits and constructing the set of opportunity ids
	        for(OpportunitySplit iterating_split : list_allOpportunitySplitRecords)
	        {
				set_opportunityIds.add(iterating_split.OpportunityId);
	        }

	        //checking if there are more than 1 value(s)
	        if(!set_opportunityIds.isEmpty())
	        	mtd_processAllOpportunitySplits(set_opportunityIds);

    	}
    }
}