/*************************************************************************************
Name                    clshandler_milestone_schedule
Developed By            West Monroe Partners
Purpose                 Refer individual method headers
Created date            1/23/2017
*************************************************************************************/
public class clshandler_milestone_schedule {

    //Variable declarations
    list<String> list_productCategories = new list<String>();
    public static map<string,Inactivate_Trigger_On_Object__mdt> map_objectToActivate  = new map<string,Inactivate_Trigger_On_Object__mdt>([ SELECT Label, Activate__c FROM Inactivate_Trigger_On_Object__mdt]);

	/*************************************************************************************
    Method Name             createMilestoneOnOpportunityCreate
    Developed By            West Monroe Partners
    Purpose                 * For every opportunity, create 1 project record
								* All date values are null - this will be the default value on the object
								* Associate it to the opportunity
    Created date            1/23/2017
	Parameters				list<Opportunity> - the list of opportunity IDs from the trigger
							for which the projects have to be created have to be created
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		1/23/2017		Refer method header
    2.0         SS      2/7/2017        Ensuring that projects are created when opportunity is created
    *************************************************************************************/
    public void createProjectOnOpportunityCreate(list<Opportunity> list_Opportunity){

        /* 1.0 code commented
       //Variable declaration for the method
        list<Milestone__c> list_milestone 								= new list<Milestone__c>();



        if(!list_productCategories.isEmpty()){
            for(Opportunity iterating_opportunity : list_Opportunity){
                //Creating the project to be inserted
             	//Iterating through the list of Product categories
                for(String iterating_prodCategory : list_productCategories){
                    //The iterating_milestone is the milestone record created on the fly for every product category
                    //Opportunity is the running opportunity
                    //Product category is from the custom metadata type
                    Milestone__c iterating_milestone 						= new Milestone__c();
                    iterating_milestone.ProductCategory__c					= iterating_prodCategory;
                    list_milestone.add(iterating_milestone);
                }
            }


            //DML if any milestones exist
            if(!list_milestone.isEmpty()){
                Database.insert(list_milestone, false);
            }
            */
            //Variable declaration for the method
            list<Project__c> list_project       = new list<Project__c>();

            //For every opportunity inserted, one single project is created
            for(Opportunity iterating_opportunity: list_Opportunity){
                Project__c iterating_project = new Project__c();
                iterating_project.Name = System.Label.defaultProjectPrefix + ' - ' + iterating_opportunity.Name;
                iterating_project.Opportunity__c = iterating_opportunity.Id;
                list_project.add(iterating_project);
            }
            System.debug('list_project >> ' + list_project);
            //DML if any milestones exist
            if(!list_project.isEmpty()){
                Database.insert(list_project, false);
            }
        //}
    }
	/*************************************************************************************
    Method Name             shareCPQ_QuoteToOpportunityTeam
    Developed By            West Monroe Partners
    Purpose                 for every quote created, it is shared with the opportunity team
    						of the opportunity associated
    Created date            2/9/2017
	Parameters				list<SBQQ__Quote__c> - the list of quote IDs from the trigger
							for which the team needs to be cloned
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		2/9/2017		Refer method header
    *************************************************************************************/
    public void shareCPQ_QuoteToOpportunityTeam(list<SBQQ__Quote__c> list_CPQ_quotes){
    	//variables used in the method
    		//1. list<Id> list_OpportunityIds - gets the id of all the opp related to CPQ_Quotes
    		//2. map<Id,list<OpportunityTeam>> - returns the list of opplinetime and this will
    												//be looped to create share record
    	list<Id> list_OpportunityIds = new list<Id>();
    	map<Id,list<OpportunityTeamMember>> map_opportunityIdToOpportunityTeam = new map<Id,list<OpportunityTeamMember>>();
    	list<SBQQ__Quote__Share> list_quoteShare = new list<SBQQ__Quote__Share>();

    	for(SBQQ__Quote__c iterating_cpq_quote : list_CPQ_quotes){
    		//using the list to fetch the opportunity ids
    		if(iterating_cpq_quote.SBQQ__Opportunity2__c != null)
    			list_OpportunityIds.add(iterating_cpq_quote.SBQQ__Opportunity2__c);
    	}

    	 //Querying the opportunity team for the opportunity Id
    	for(OpportunityTeamMember iterating_opportunityTeam : [ SELECT
			    													Id,
			    													Name,
			    													OpportunityAccessLevel,
			    													OpportunityId,
			    													TeamMemberRole,
			    													UserId
			    												 FROM
			    												 	OpportunityTeamMember
			    												 WHERE
			    												 	OpportunityId
			    												 		IN: list_OpportunityIds
			    												 AND
			    												 	OpportunityAccessLevel != 'Read'
			    												 AND
			    												 	OpportunityAccessLevel != 'None'
			    												 AND
			    												 	OpportunityAccessLevel != ''
    														  ]
    	   ){
    	   	//We are checking if the value is already in the map,
    	   	//if it exists, adding another opportunity team member to the value

    	   	if(map_opportunityIdToOpportunityTeam.containsKey(iterating_opportunityTeam.OpportunityId)){
    	   		list<OpportunityTeamMember> list_oppTeamMember = new list<OpportunityTeamMember>();
    	   		list_oppTeamMember = map_opportunityIdToOpportunityTeam.get(iterating_opportunityTeam.OpportunityId);
    	   		list_oppTeamMember.add(iterating_opportunityTeam);
    	   		map_opportunityIdToOpportunityTeam.put(iterating_opportunityTeam.OpportunityId, list_oppTeamMember);
    	   	}else{//else -- creating for the first time
    	   		list<OpportunityTeamMember> list_oppTeamMember = new list<OpportunityTeamMember>();
    	   		list_oppTeamMember.add(iterating_opportunityTeam);
    	   		map_opportunityIdToOpportunityTeam.put(iterating_opportunityTeam.OpportunityId, list_oppTeamMember);
    	   	}
    	}

    	//iterating the SBQQ__Quote__c to assign the share access
    	for(SBQQ__Quote__c iterating_cpq_quote : list_CPQ_quotes){
    		//looping through the map
    		if(map_opportunityIdToOpportunityTeam.containsKey(iterating_cpq_quote.SBQQ__Opportunity2__c)){
    			for(OpportunityTeamMember iterating_opportunityTeam : map_opportunityIdToOpportunityTeam.get(iterating_cpq_quote.SBQQ__Opportunity2__c)){
	    			//creating the iterating Share record
		    		SBQQ__Quote__Share iterating_share = new SBQQ__Quote__Share();
		    		iterating_share.ParentId = iterating_cpq_quote.id;
		    		iterating_share.UserOrGroupId = iterating_opportunityTeam.UserId;
		    		iterating_share.AccessLevel = 'Edit';
		    		iterating_share.RowCause   = Schema.SBQQ__Quote__Share.rowCause.Opp_team__c;
		    		list_quoteShare.add(iterating_share);
    			}
    		}
    	}
    	//DML
    	if(!list_quoteShare.isEmpty())
    		Database.insert(list_quoteShare);
    }
	/*************************************************************************************
    Method Name             cloneTeamFromAccountTeam
    Developed By            West Monroe Partners
    Purpose                 For every opportunity created, the method does the following
    							* clones the account team at that moment and moves them
    							  to opportunity team
    Created date            2/8/2017
	Parameters				list<Project__c> - the list of opportunity IDs from the trigger
							for which the team needs to be cloned
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		2/8/2017		Refer method header
    *************************************************************************************/
    public void cloneTeamFromAccountTeam(list<Opportunity> list_opportunity) {

    	//variables used in the method
    		//1. a map to store the opportunity id to account id
    		map<Id,Id> map_opportunityIdToAccountId = new map<Id,Id >();
			//2. a map to store account id and related account team member records
			map<id,list<AccountTeamMember>> map_accountIdToAccountTeamMembers = new map<id,list<AccountTeamMember>>();

			list<OpportunityTeamMember> oppTeamMembersList = new list<OpportunityTeamMember>();
    	//Looping through the list to fetch the account Ids
    	for(Opportunity iterating_opportunity : list_opportunity){
	        	map_opportunityIdToAccountId.put(iterating_opportunity.Id, iterating_opportunity.accountId);
   		}
		System.debug('Account to opportunity map  >> ' + map_opportunityIdToAccountId);
		
    	//Fetching the related account team member for the set of accounts retrieved
    	for(AccountTeamMember iterating_accountTeamMember : [SELECT Id,
    																UserId,
    																User.Name,
    																TeamMemberRole,
    																AccountId,
    																OpportunityAccessLevel
    														 FROM
    														 		AccountTeamMember
    														 WHERE
    																AccountId
    																IN:map_opportunityIdToAccountId.values()
    														AND
			    												 	OpportunityAccessLevel != 'Read'
			    											AND
			    												 	OpportunityAccessLevel != 'None'
			    											AND
			    												 	OpportunityAccessLevel != ''
    													    ]
    	){
    		//Checks the existing map and pulls the list of TeamMember info if found
    		list<AccountTeamMember > list_accountTeamMembers = new list<AccountTeamMember >();
    		if(map_accountIdToAccountTeamMembers.containsKey(iterating_accountTeamMember.accountid))
            	list_accountTeamMembers = map_accountIdToAccountTeamMembers.get(iterating_accountTeamMember.accountId);
            //Adding the team member to the list
            list_accountTeamMembers.add(iterating_accountTeamMember);
            //Adding to the map
        	map_accountIdToAccountTeamMembers.put(iterating_accountTeamMember.Accountid, list_accountTeamMembers);
    	}
    	//Looping through the opportunity list and creating opportunity team member
    	for(Opportunity iterating_opportunity : list_opportunity){
    		//getting the account team member by using the account id map
    		if(map_accountIdToAccountTeamMembers.containsKey(map_opportunityIdToAccountId.get(iterating_opportunity.Id))){
	    		for(AccountTeamMember iterating_accountTeamMember : map_accountIdToAccountTeamMembers.get(map_opportunityIdToAccountId.get(iterating_opportunity.Id))){
	    			//Creating the opportunity line item
	    			//Filtering the 'None' OpportunityAccessLevel
	    				OpportunityTeamMember iterating_oppTeamMember = new OpportunityTeamMember();
		    			iterating_oppTeamMember.UserId = iterating_accountTeamMember.UserId;
			            iterating_oppTeamMember.TeamMemberRole = iterating_accountTeamMember.TeamMemberRole;
			            iterating_oppTeamMember.OpportunityId = iterating_opportunity.ID;
			            iterating_oppTeamMember.OpportunityAccessLevel = iterating_accountTeamMember.OpportunityAccessLevel;
			            oppTeamMembersList.add(iterating_oppTeamMember);
	    		}
    		}
    	}

    	//Dml to insert the opportunity team members
		if(!oppTeamMembersList.isEmpty())
    		Database.insert(oppTeamMembersList);

    }

    /*************************************************************************************
    Method Name             getProductCategories
    Developed By            West Monroe Partners
    Purpose                 *Fetch the 7 product category values from the custom metadata types
    Created date            1/23/2017
	Parameters				void
	Output type				list<String> - list of product category values stored in the custom metadata type
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		1/23/2017		Refer method header
    *************************************************************************************/
    private list<String> getProductCategories(){
        list<String> list_prodCategories = new list<String>();
        //Getting all Product categories from the Product_Category_Master__mdt - metadata type
        for(Product_Category_Master__mdt iterating_prodCat : [SELECT MasterLabel
                                                              FROM Product_Category_Master__mdt]){
            list_prodCategories.add(iterating_prodCat.MasterLabel);
        }
        return (!list_prodCategories.isEmpty())?list_prodCategories:null;
    }

    /*************************************************************************************
    Method Name             createMilestoneOnProject
    Developed By            West Monroe Partners
    Purpose                 For every project created, the method does the following
    							* associates existing milestones if the project created is the 1st project
    							* clones the milestones related to the 1st project, if the present milestone created is not the 1st one
    Created date            1/26/2017
	Parameters				list<Project__c> - the list of project IDs from the trigger
							for which the milestones have to be created/associated
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		1/26/2017		Refer method header
    2.0			SS		1/26/2017		Ensuring that milestones are created when project is created
    *************************************************************************************/
    public void createMilestoneOnProject(list<Project__c> list_project){
    	//Variable declaration for the method - list to create/update milestones
        list<Milestone__c> list_milestone 								= new list<Milestone__c>();
        list<Id>  list_allRunningOpportunities 							= new list<Id>();
        map<Id,list<Milestone__c>> map_opportunityIdToFirstProjectMilestones			= new map<Id,list<Milestone__c>>();
		//Querying and associating the list of
        list_productCategories											= getProductCategories();

        //Looping through the projects
        for(Project__c iterating_project : list_project){
    		//Storing the opportunity IDs of the projects which were inserted
    		list_allRunningOpportunities.add(iterating_project.Opportunity__c);
        }

        //Fetching all the first project Ids for the running Opportunities Id(s)
        map_opportunityIdToFirstProjectMilestones 								= fetchMilestonesForFirstProject(list_allRunningOpportunities);

		System.debug('map_opportunityIdToFirstProjectMilestones'+map_opportunityIdToFirstProjectMilestones);
        //Looping through the project details and deciding if its is a first or pro first project
        for(Project__c iterating_project : list_project){
            //Comment the logic here
        	if(!map_opportunityIdToFirstProjectMilestones.containsKey(iterating_project.Opportunity__c)){
        		//Method to pass project, and the list of milestones
        		list_milestone.addAll(createMilestoneOnFirstProject(iterating_project));
        	}else{ //Use case -- more than 1 project.. Querying the first 7 milestones inserted.
        		//Method to pass projects and the list of milestones to clone
        		list_milestone.addAll(cloneMilestonesToFirstProject(iterating_project, map_opportunityIdToFirstProjectMilestones.get(iterating_project.Opportunity__c)));
        	}

        }

        //DML if any milestones exist
        if(!list_milestone.isEmpty()){
    		Schema.SObjectField milestoneID = Milestone__c.Fields.Id;
    		for(Milestone__c iterating_milestone : list_milestone){
    			System.debug('>>> Iterating milestone is >> ' +  iterating_milestone.id);
    			System.debug('>>> Iterating milestone is >> ' +  iterating_milestone.Project__c);
    		}
            Database.upsert(list_milestone);
        }
    }
    /*************************************************************************************
    Method Name             fetchMilestonesForFirstProject
    Developed By            West Monroe Partners
    Purpose                 Returns the milestone ID(s) for the opportunity
    Created date            1/27/2017
	Parameters				list<Opportunity>
	Output type				map<Id, list<Milestone__c>> - Opportunity ID to list of milestone IDs
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		1/27/2017		Refer method header
    2.0			SS		2/8/2017		Refer the changes below:
    ------------------------------------------------------------------------------------
    2.0 Changes
    Data model
    Opportunity --> Project (child) --> Milestones (child)
    The method does the following:
    1. Gets the list of opportunity Ids as a parameter
    2. Parses through the projects related to the opportunity and checks for the
       count of projects associated to the opportunity
       a) If we have more than 1, we save the first project ID to every opporutnity ID
    3. Query for the milestones related to the 1st project and create a map of
    	opportunity id to the list of first 7 milestones
    ------------------------------------------------------------------------------------
    *************************************************************************************/
    private map<Id,list<Milestone__c>> fetchMilestonesForFirstProject(list<Id> list_opportunity){
    	//Variable declaration for the method
    	//create 2 maps
        // 1. map<Id, count of projects>
        map<Id, Integer> mapCountOfProjectsOnOpportunity = new map<Id, Integer>();
        // 2. map<id, firstprojectID> if count is >1
        map<Id, Id> mapOpportunityIDToFirstProjectId = new map<Id, Id>();
        //3. get the milestones from the point 2 and then build, map<oppid,list<Milestone__c>>
        list<Id> list_projectIds   = new list<Id>();
        map<Id, list<Milestone__c>> map_opportunityIdToMilestones = new map<Id, list<Milestone__c>>();
        for(Project__c iterating_project : [SELECT Id,
                                                   Opportunity__c
                                             FROM Project__c
                                             WHERE Opportunity__c
                                             IN: list_opportunity
                                             ORDER BY CreatedDate ASC
                                           ]
            ){
                //using the map to establish the number of projects for each opportunity
                if(!mapCountOfProjectsOnOpportunity.containsKey(iterating_project.Opportunity__c)){
                    //Initiating the count
                    mapCountOfProjectsOnOpportunity.put(iterating_project.Opportunity__c, 1);
                    //Adding the first project Id for every opportunity
                    mapOpportunityIDToFirstProjectId.put(iterating_project.Opportunity__c, iterating_project.Id);
                }
                else{
                    Integer instance_int = mapCountOfProjectsOnOpportunity.get(iterating_project.Opportunity__c) + 1;
                    mapCountOfProjectsOnOpportunity.put(iterating_project.Opportunity__c, instance_int);
                    //If it gets here, it means we have more than 1 project for the opportunity
                    list_projectIds.add(mapOpportunityIDToFirstProjectId.get(iterating_project.Opportunity__c));
                }
        }

		System.debug('list_opportunity'+list_opportunity);
		System.debug('list_projectIds'+list_projectIds);
        //Query for the milestone related to the project Ids chosen in the previous step
        for(Milestone__c iterating_milestone : [ SELECT Id,
                                                        Project__c,
                                                        Project__r.Opportunity__c,
                                                        Contract__c,
                                                        FA__c,
                                                        HW_Install__c,
                                                        HW_delivery__c,
                                                        KPI__c,
                                                        PO__c,
                                                        ProductCategory__c,
                                                        Retention__c,
                                                        RFA__c,
                                                        Stability__c,
                                                        SW_delivery__c,
                                                        Total_Percentage__c,
                                                        UAT__c
                                                    FROM
                                                        Milestone__c
                                                    WHERE
                                                        Project__c IN:list_projectIds
													ORDER BY
														CreatedDate
													ASC
                                                ]
           ){
               //using the map to establish the number of projects for each opportunity
               if(!map_opportunityIdToMilestones.containsKey(iterating_milestone.Project__r.Opportunity__c)){
                   //Inserting a list of milestone
                   list<Milestone__c> list_milestone = new list<Milestone__c>();
                   list_milestone.add(iterating_milestone);
                   map_opportunityIdToMilestones.put(iterating_milestone.Project__r.Opportunity__c,list_milestone);
               }
               else{
                   //Inserting milestone list to exsiting values in the map
                   list<Milestone__c> list_milestone = new list<Milestone__c>();
                   list_milestone = map_opportunityIdToMilestones.get(iterating_milestone.Project__r.Opportunity__c);
                   list_milestone.add(iterating_milestone);
                   map_opportunityIdToMilestones.put(iterating_milestone.Project__r.Opportunity__c,list_milestone);
               }
        }

        return map_opportunityIdToMilestones;

    }

    /*************************************************************************************
    Method Name             fetchMilestoneRows
    Developed By            West Monroe Partners
    Purpose                 Returns the milestone rows for the project to be displayed
    Created date            2/3/2017
	Parameters              Id -- projectId
	Output type				list<Milestone__c>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		2/3/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static list<Milestone__c> fetchMilestoneRows (Id projectId){
        //2 things.. eliminate all products which do not have the product categories
        // Query for the chosen milestone and then send it back to the helper js
        System.debug('In fetchMilestoneRows');

        //Getting all the opportunity line items
        set<String> set_prodCategoriesString = new set<String>();
        for(OpportunityLineItem iterating_opportunityLineItem : [SELECT
                                                                    Id,
                                                                    Product_Category__c
                                                              FROM
                                                                  OpportunityLineItem
                                                              Where
                                                                Project__c =:projectId
                                                              AND
                                                              	MBLM_Billing_Frequency__c = 'Milestone'
                                                            ]
            ){
                set_prodCategoriesString.add(iterating_opportunityLineItem.Product_Category__c);
         }
         System.debug('set_prodCategoriesString >> ' +  set_prodCategoriesString.size());
         System.debug(set_prodCategoriesString);
         list<Milestone__c> list_milestone = new list<Milestone__c>();
         for(Milestone__c iterating_milestone  : [SELECT
                                                     Id,
                                                     ProductCategory__c,
                                                     Project__c,
                                                     Contract__c,
                                                     FA__c,
                                                     KPI__c,
                                                     HW_delivery__c,
                                                     HW_Install__c,
                                                     PO__c,
                                                     Retention__c,
                                                     RFA__c,
                                                     Stability__c,
                                                     SW_delivery__c,
                                                     UAT__c,
                                                     Total_Percentage__c
                                                  FROM
                                                 Milestone__c
                                              WHERE Project__c =:projectId
                                              AND ProductCategory__c in:set_prodCategoriesString]
            ){
                list_milestone.add(iterating_milestone);
            }
            System.debug(list_milestone);
        return list_milestone;
    }
    /*************************************************************************************
    Method Name             fetchProjectDetails
    Developed By            West Monroe Partners
    Purpose                 Returns the project info based on the id provided
    Created date            2/2/2017
	Parameters              Id -- projectId
	Output type				Project__c
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		2/2/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static Project__c fetchProjectDetails (Id projectId){
        Project__c runningProject = [SELECT Id,
                                            Contract_Date__c,
                                            FA_Date__c,
                                            HW_delivery_Date__c,
                                            HW_Install_Date__c,
                                            KPI_Date__c,
                                            PO_Date__c,
                                            Retention_Date__c,
                                            RFA_Date__c,
                                            Stability_Date__c,
                                            SW_delivery_Date__c,
                                            UAT_Date__c
                                     FROM
                                        Project__c
                                     WHERE
                                        ID =:projectId];
        System.debug('In controller >> '  + runningProject);

        return runningProject;
    }
    /*************************************************************************************
    Method Name             saveMethod
    Developed By            West Monroe Partners
    Purpose                 Saves the following
                            * Project record with dates
                            * Milestone records with percentage information
    Created date            2/7/2017
	Parameters              Project__c, list<Milestone__c>
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		2/7/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static void saveMethod (Project__c project, list<Milestone__c> list_milestone){
            System.debug(' DEBUGGING PROJECT >>  ' + project );
            System.debug(' DEBUGGING MILESTONES >>  ' + list_milestone );
            //There are 2 steps here
            //1. Save the project first -- it is the parent
            update project;
            System.debug('Project saved, next is the list of milestones');
            //2. Save all the milestone -- it is the child
            update list_milestone;
            System.debug(' saving done  ' );
    }

    /*************************************************************************************
    Method Name             fetchMilestoneHeaders
    Developed By            West Monroe Partners
    Purpose                 Returns the list of milestone headers from custom metadata type,
                            ordered by display order field
    Created date            2/2/2017
	Parameters
	Output type				list of milestone header strings
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		2/2/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static list<String> fetchMilestoneHeaders(){
        list<String> list_milestoneHeaders = new list<String>();
         for(Milestone_master__mdt iterating_milestoneHeader : [SELECT
                                                                    MasterLabel,
                                                                    Display_Order__c
                                                                FROM Milestone_master__mdt
                                                                ORDER BY
                                                                    Display_Order__c ASC]
            ){
                list_milestoneHeaders.add(iterating_milestoneHeader.MasterLabel);
                System.debug('Milestone header is ?? ' + iterating_milestoneHeader);
            }

            return list_milestoneHeaders;
    }
    /*************************************************************************************
    Method Name             fetchProjectForOpportunityId
    Developed By            West Monroe Partners
    Purpose                 Returns the list of project names and ID to display for the given opportunity Id
    Created date            2/1/2017
	Parameters				String - Opportunity ID
	Output type				 list of projects
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		2/1/2017		Refer method header
    *************************************************************************************/
    @AuraEnabled
    public static list<Project__c> fetchProjectForOpportunityId(String opportunityID){
        //Variables to use in the method
        System.debug('Here in APEX >>' + opportunityID);
        list<Project__c> list_projectsAssociatedToOpportunity = new list<Project__c>();
        for(Project__c iterating_project : [SELECT
                                                  ID,
                                                  Name
                                            FROM
                                                Project__c
                                            WHERE
                                                Opportunity__c =:opportunityID]){
            list_projectsAssociatedToOpportunity.add(iterating_project);
        }
        return list_projectsAssociatedToOpportunity;
    }

    /*************************************************************************************
    Method Name             createMilestoneOnFirstProject
    Developed By            West Monroe Partners
    Purpose                 Creates empty 7 milestone records
    Created date            1/27/2017
	Parameters				Project__c, list<Milestone__c>
	Output type				list<Milestone__c> list of milestones to update
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		1/27/2017		Refer method header
    2.0			SS		2/7/2017		Now a milestone is a child of a project, hence
    									creating 7 milestones and associate it to the project
    *************************************************************************************/
    private list<Milestone__c> createMilestoneOnFirstProject(Project__c iterating_project){
    	System.debug('>> In createMilestoneOnFirstProject');
        list<Milestone__c> list_milestone                               = new list<Milestone__c>();
        //Querying and associating the list of
        //list_productCategories											=
        /*
    	//Looping through the milestones to update the project Id on the milestone object
    	for(Milestone__c iterating_milestone : list_milestone){
    		//Associating the project to each milestone__c
    		iterating_milestone.Project__c = iterating_project.Id;
    	}*/
        if(!list_productCategories.isEmpty()){
            for(String iterating_prodCategory : list_productCategories){
                //The iterating_milestone is the milestone record created on the fly for every product category
                //Opportunity is the running opportunity
                //Product category is from the custom metadata type
                Milestone__c iterating_milestone 						= new Milestone__c();
                iterating_milestone.Project__c						    = iterating_project.Id;
                iterating_milestone.ProductCategory__c					= iterating_prodCategory;
                list_milestone.add(iterating_milestone);
            }
        }
    	return list_milestone;
    }


	/*************************************************************************************
    Method Name             associateToFirstProject
    Developed By            West Monroe Partners
    Purpose                 Associate the line items to the 1st project
    Created date            2/8/2017
	Parameters				list<OpportunityLineItem>
	Output type				void
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		1/27/2017		Refer method header
    *************************************************************************************/
    public void associateToFirstProject(list<OpportunityLineItem> list_oppLineItem){
    	//Variables to use in the method
    	list<Id> list_opportunity = new list<Id>();
    	//Map to have opportunity ID to first project Id
    	map<Id,Id> map_opportunityProdToFirstProject = new map<Id,Id>();

    	//Looping through the list of opportunity line items and getting the opportunity Id
    	for(OpportunityLineItem iterating_oppLineItem : list_oppLineItem){
    		list_opportunity.add(iterating_oppLineItem.OpportunityId);
    	}

    	//Querying for the first project for the opportunities chosen
    	for(Opportunity iterating_opportunity : [ SELECT Id,
    												     (SELECT Id
    												      FROM
    												      		Projects__r
    												      ORDER BY CreatedDate
    												      LIMIT 1)
    											  FROM
    											  		Opportunity
    											  WHERE
    											  		ID IN: list_opportunity
    											]
    	   ){
    	   	map_opportunityProdToFirstProject.put(iterating_opportunity.id,iterating_opportunity.Projects__r[0].Id);
    	}

    	//Looping through the opp line items and modifying the project id
    	for(OpportunityLineItem iterating_oppLineItem : list_oppLineItem){
    		iterating_oppLineItem.Project__c = map_opportunityProdToFirstProject.get(iterating_oppLineItem.OpportunityId);
    	}
    }
    /*************************************************************************************
    Method Name             cloneMilestonesToFirstProject
    Developed By            West Monroe Partners
    Purpose                 Returns the list of milestones to insert -- cloned the milestones
    						related to the first project
    Created date            1/27/2017
	Parameters				Project__c, list<Milestone__c>
	Output type				list<Milestone__c> list of milestones to insert
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0			SS		1/27/2017		Refer method header
    *************************************************************************************/
    private list<Milestone__c> cloneMilestonesToFirstProject(Project__c iterating_project, list<Milestone__c> list_milestone){
    	System.debug('>> In cloneMilestonesToFirstProject');
    	//Variable declaration for the method
    	list<Milestone__c> list_milestoneToInsert 								= new list<Milestone__c>();
        System.debug(' list_milestone ' + list_milestone.size() );
    	//Looping through the milestones to update the project Id on the milestone object
    	for(Milestone__c iterating_milestone : list_milestone){
    		//Associating the project to each milestone__c
    		//iterating_milestone.Project__c = iterating_project.Id;
    		Milestone__c inst_milestone = iterating_milestone.clone(false, true, false, false);
    		inst_milestone.Project__c = iterating_project.Id;
    		list_milestoneToInsert.add(inst_milestone);
    	}
    	return list_milestoneToInsert;
    }

    public void prefillIfEmptyProjectDates(List<Project__c> newProjects)
	{
		Map<Id, List<Project__c>> oppIdProjectMap = new Map<Id, List<Project__c>>();
		for(Project__c p : newProjects)
		{
			if(p.Opportunity__c != null
			&& p.PO_Date__c == null
			&& p.Contract_Date__c == null
			&& p.HW_delivery_Date__c == null
			&& p.HW_Install_Date__c == null
			&& p.SW_delivery_Date__c == null
			&& p.RFA_Date__c == null
			&& p.UAT_Date__c == null
			&& p.Stability_Date__c == null
			&& p.FA_Date__c == null
			&& p.KPI_Date__c == null
			&& p.Retention_Date__c == null
			)

			{
				if(!oppIdProjectMap.containsKey(p.Opportunity__c))
				{
					oppIdProjectMap.put(p.Opportunity__c , new List<Project__c>());
				}
				oppIdProjectMap.get(p.Opportunity__c).add(p);
			}
		}

		List <Project__c> brotherProjects =  new List <Project__c>();

		if (!oppIdProjectMap.keySet().isEmpty())
		{
			brotherProjects =[SELECT
									Id,
									Opportunity__c,
									CreatedDate,
									PO_Date__c,
									Contract_Date__c,
									HW_delivery_Date__c,
									HW_Install_Date__c,
									SW_delivery_Date__c,
									RFA_Date__c,
									UAT_Date__c,
									Stability_Date__c,
									FA_Date__c,
									KPI_Date__c,
									Retention_Date__c
								FROM
									Project__c
								WHERE
									Opportunity__c IN: oppIdProjectMap.keySet()
								ORDER BY
									CreatedDate
								ASC];
		}
		else
		{
			return;
		}

		Map<Id, Project__c> oppIdOldestBrotherProjectMap = new Map<Id, Project__c>();

		for (Project__c brotherObject : brotherProjects)
		{
			if (oppIdOldestBrotherProjectMap.get(brotherObject.Opportunity__c) == null)
			{
				oppIdOldestBrotherProjectMap.put(brotherObject.Opportunity__c, brotherObject);
			}
			else
			{
				if (oppIdOldestBrotherProjectMap.get(brotherObject.Opportunity__c).CreatedDate < brotherObject.CreatedDate)
				{
					oppIdOldestBrotherProjectMap.put(brotherObject.Opportunity__c, brotherObject);
				}
			}
		}

		if (oppIdOldestBrotherProjectMap.keySet() == null)
		{
			return;
		}

		for (Project__c p : newProjects)
		{
			Project__c oldestBrotherProject = oppIdOldestBrotherProjectMap.get(p.Opportunity__c);
			if (oldestBrotherProject == null)
			{
				continue;
			}
			p.PO_Date__c = oldestBrotherProject.PO_Date__c;
			p.Contract_Date__c = oldestBrotherProject.Contract_Date__c;
			p.HW_delivery_Date__c = oldestBrotherProject.HW_delivery_Date__c;
			p.HW_Install_Date__c = oldestBrotherProject.HW_Install_Date__c;
			p.SW_delivery_Date__c = oldestBrotherProject.SW_delivery_Date__c;
			p.RFA_Date__c = oldestBrotherProject.RFA_Date__c;
			p.UAT_Date__c = oldestBrotherProject.UAT_Date__c;
			p.Stability_Date__c = oldestBrotherProject.Stability_Date__c;
			p.FA_Date__c = oldestBrotherProject.FA_Date__c;
			p.KPI_Date__c = oldestBrotherProject.KPI_Date__c;
			p.Retention_Date__c = oldestBrotherProject.Retention_Date__c;
		}
	}
}