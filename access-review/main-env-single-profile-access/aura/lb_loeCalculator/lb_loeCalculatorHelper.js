({
	/*************************************************************************************
      Method Name             getQuoteLineProducts
      Developed By            West Monroe Partners
      Purpose                 * To interact with apex to fetch the products from quote line

      Created date            5/15/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/15/2017		Refer method header
      *************************************************************************************/
      getQuoteLineProducts : function(component){
    	  //Method to fetch the products from quote lines
		  var action = component.get("c.fetchQuoteLineProducts");
		  //Setting parameters for the method call
		  action.setParams({
			  quoteId : component.get("v.recordId")
		  });
		  //Handling the call back
		  action.setCallback(this, function(response){
			  var state = response.getState();
			  if(state == "SUCCESS"){
				  console.log('Response value >> '+ response.getReturnValue());
				  component.set("v.quoteLines", response.getReturnValue());
			  }
		  });
		  //enqueuing the action
		  $A.enqueueAction(action);
      },
      /*************************************************************************************
      Method Name             getColumnHeaders
      Developed By            West Monroe Partners
      Purpose                 * To interact with apex to fetch the column headers from
								custom metadata headers
      Created date            5/15/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/15/2017		Refer method header
      *************************************************************************************/
      getColumnHeaders : function(component){
    	  //Method to fetch the string headers from the custom metadata headers
		  var action = component.get("c.fetchColumnHeaders");
		  //Handling the call back
		  action.setCallback(this, function(response){
			  var state = response.getState();
			  if(state == "SUCCESS"){
				  console.log('Response value >> '+ response.getReturnValue());
				  component.set("v.columnHeaders", response.getReturnValue());
			  }
		  });
		  //enqueuing the action
		  $A.enqueueAction(action);
      },
      /*************************************************************************************
      Method Name             getCommonProducts
      Developed By            West Monroe Partners
      Purpose                 * To interact with apex to fetch the common products from custom
								metadata types
      Created date            5/15/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/15/2017		Refer method header
      *************************************************************************************/
      getCommonProducts : function(component){
    	  //method to fetch the common products from custom metadata type
    	  var action = component.get("c.fetchCommonProducts");
    	  //Handling the call back
    	  action.setCallback(this, function(response){
    		  var state = response.getState();
    		  if(state=='SUCCESS'){
    			  console.log('Response value >> '+ response.getReturnValue());
				  component.set("v.commonProducts", response.getReturnValue());
    		  }
    	  });
    	  //enqueuing the action
		  $A.enqueueAction(action);
      },
      /*************************************************************************************
      Method Name             getQuoteFields
      Developed By            West Monroe Partners
      Purpose                 * To interact with apex to fetch the fields from quotes
      Created date            5/17/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/17/2017		Refer method header
      *************************************************************************************/
      getPrimaryQuote :function(component,helper){
    	  //method to fetch the common products from custom metadata type
    	  var action = component.get("c.fetchPrimaryQuote");
    	  //Setting parameters for the method call
		  action.setParams({
			  quoteId : component.get("v.recordId")
		  });
		  //Handling the call back
		  action.setCallback(this, function(response){
			  var state = response.getState();
			  if(state == "SUCCESS"){
				  console.log('getPrimary Response value >> '+ response.getReturnValue());
				  var prQuote = response.getReturnValue();
                  console.log('Before >> ' + prQuote.KickOff_General_Hours__c);
				  prQuote.KickOff_General_Hours__c = Number(isNaN(prQuote.KickOff_General_Hours__c)?0:prQuote.KickOff_General_Hours__c);
					console.log('After >> ' + prQuote.KickOff_General_Hours__c);
                          prQuote.PM_General_Hours__c = Number(isNaN(prQuote.PM_General_Hours__c)?0:prQuote.PM_General_Hours__c);

                          prQuote.Software_Installation_Main_Phase_Deploy__c = Number(isNaN(prQuote.Software_Installation_Main_Phase_Deploy__c)?0:prQuote.Software_Installation_Main_Phase_Deploy__c);
				  prQuote.Software_Installation_Main_Phase_Doc__c = Number(isNaN(prQuote.Software_Installation_Main_Phase_Doc__c)?0:prQuote.Software_Installation_Main_Phase_Doc__c);
				  prQuote.Software_Installation_Main_Phase_General__c = Number(isNaN(prQuote.Software_Installation_Main_Phase_General__c)?0:prQuote.Software_Installation_Main_Phase_General__c);
				  prQuote.Software_Installation_Main_Phase_SS__c = Number(isNaN(prQuote.Software_Installation_Main_Phase_SS__c)?0:prQuote.Software_Installation_Main_Phase_SS__c);
				  prQuote.Software_Installation_Main_Phase_InTest__c = Number(isNaN(prQuote.Software_Installation_Main_Phase_InTest__c)?0:prQuote.Software_Installation_Main_Phase_InTest__c);
				  prQuote.Software_Installation_Main_Phase_Intg__c = Number(isNaN(prQuote.Software_Installation_Main_Phase_Intg__c)?0:prQuote.Software_Installation_Main_Phase_Intg__c);
				  prQuote.Software_Installation_Main_Phase_UAT__c = Number(isNaN(prQuote.Software_Installation_Main_Phase_UAT__c)?0:prQuote.Software_Installation_Main_Phase_UAT__c);

                          prQuote.Software_Installation_Addi_Phases_Gen__c = Number(isNaN(prQuote.Software_Installation_Addi_Phases_Gen__c )?0:prQuote.Software_Installation_Addi_Phases_Gen__c) ;
				  prQuote.Software_Installation_Add_Phases_Dply__c = Number(isNaN(prQuote.Software_Installation_Add_Phases_Dply__c )?0:prQuote.Software_Installation_Add_Phases_Dply__c) ;
				  prQuote.Software_Installation_Add_Phases_Doc__c = Number(isNaN(prQuote.Software_Installation_Add_Phases_Doc__c )?0:prQuote.Software_Installation_Add_Phases_Doc__c) ;
				  prQuote.Software_Installation_Add_Phases_Intg__c = Number(isNaN(prQuote.Software_Installation_Add_Phases_Intg__c )?0:prQuote.Software_Installation_Add_Phases_Intg__c) ;
				  prQuote.Software_Installation_Add_Phases_InTest__c = Number(isNaN(prQuote.Software_Installation_Add_Phases_InTest__c )?0:prQuote.Software_Installation_Add_Phases_InTest__c) ;
				  prQuote.Software_Installation_Add_Phases_SS__c = Number(isNaN(prQuote.Software_Installation_Add_Phases_SS__c )?0:prQuote.Software_Installation_Add_Phases_SS__c);
				  prQuote.Software_Installation_Add_Phases_UAT__c = Number(isNaN(prQuote.Software_Installation_Add_Phases_UAT__c )?0:prQuote.Software_Installation_Add_Phases_UAT__c);

                          prQuote.Test_Bed_deployment_General__c = Number(isNaN(prQuote.Test_Bed_deployment_General__c )?0:prQuote.Test_Bed_deployment_General__c) ;
                          prQuote.Test_Bed_deployment_Dply__c = Number(isNaN(prQuote.Test_Bed_deployment_Dply__c )?0:prQuote.Test_Bed_deployment_Dply__c) ;
                          prQuote.Test_Bed_deployment_Doc__c = Number(isNaN(prQuote.Test_Bed_deployment_Doc__c )?0:prQuote.Test_Bed_deployment_Doc__c) ;
                          prQuote.Test_Bed_deployment_Intg__c = Number(isNaN(prQuote.Test_Bed_deployment_Intg__c )?0:prQuote.Test_Bed_deployment_Intg__c) ;
                          prQuote.Test_Bed_deployment_InTest__c = Number(isNaN(prQuote.Test_Bed_deployment_InTest__c )?0:prQuote.Test_Bed_deployment_InTest__c) ;
                          prQuote.Test_Bed_deployment_SS__c = Number(isNaN(prQuote.Test_Bed_deployment_SS__c )?0:prQuote.Test_Bed_deployment_SS__c);
                          prQuote.Test_Bed_deployment_UAT__c = Number(isNaN(prQuote.Test_Bed_deployment_UAT__c )?0:prQuote.Test_Bed_deployment_UAT__c);

                          prQuote.Database_deployment_General__c = Number(isNaN(prQuote.Database_deployment_General__c )?0:prQuote.Database_deployment_General__c) ;
			        prQuote.Database_deployment_Dply__c = Number(isNaN(prQuote.Database_deployment_Dply__c )?0:prQuote.Database_deployment_Dply__c);
				  prQuote.Database_deployment_Doc__c  = Number(isNaN(prQuote.Database_deployment_Doc__c )?0:prQuote.Database_deployment_Doc__c) ;
				  prQuote.Database_deployment_Intg__c = Number(isNaN(prQuote.Database_deployment_Intg__c )?0:prQuote.Database_deployment_Intg__c) ;
				  prQuote.Database_deployment_InTest__c = Number(isNaN(prQuote.Database_deployment_InTest__c )?0:prQuote.Database_deployment_InTest__c) ;
				  prQuote.Database_deployment_SS__c = Number(isNaN(prQuote.Database_deployment_SS__c )?0:prQuote.Database_deployment_SS__c);
				  prQuote.Database_deployment_UAT__c = Number(isNaN(prQuote.Database_deployment_UAT__c )?0:prQuote.Database_deployment_UAT__c);

                          prQuote.Third_Party_installation_Gen__c = Number(isNaN(prQuote.Third_Party_installation_Gen__c )?0:prQuote.Third_Party_installation_Gen__c) ;
			        prQuote.Third_Party_installation_Dply__c = Number(isNaN(prQuote.Third_Party_installation_Dply__c )?0:prQuote.Third_Party_installation_Dply__c);
				  prQuote.Third_Party_installation_Doc__c  = Number(isNaN(prQuote.Third_Party_installation_Doc__c )?0:prQuote.Third_Party_installation_Doc__c) ;
				  prQuote.Third_Party_installation_Intg__c = Number(isNaN(prQuote.Third_Party_installation_Intg__c )?0:prQuote.Third_Party_installation_Intg__c) ;
				  prQuote.Third_Party_installation_inTest__c = Number(isNaN(prQuote.Third_Party_installation_inTest__c )?0:prQuote.Third_Party_installation_inTest__c) ;
				  prQuote.Third_Party_installation_SS__c = Number(isNaN(prQuote.Third_Party_installation_SS__c )?0:prQuote.Third_Party_installation_SS__c);
				  prQuote.Third_Party_installation_UAT__c = Number(isNaN(prQuote.Third_Party_installation_UAT__c )?0:prQuote.Third_Party_installation_UAT__c);

                          prQuote.Miscellaneous_Gen__c = Number(isNaN(prQuote.Miscellaneous_Gen__c )?0:prQuote.Miscellaneous_Gen__c) ;
			        prQuote.Miscellaneous_Dply__c = Number(isNaN(prQuote.Miscellaneous_Dply__c )?0:prQuote.Miscellaneous_Dply__c);
				  prQuote.Miscellaneous_Doc__c  = Number(isNaN(prQuote.Miscellaneous_Doc__c )?0:prQuote.Miscellaneous_Doc__c) ;
				  prQuote.Miscellaneous_Intg__c = Number(isNaN(prQuote.Miscellaneous_Intg__c )?0:prQuote.Miscellaneous_Intg__c) ;
				  prQuote.Miscellaneous_InTest__c = Number(isNaN(prQuote.Miscellaneous_InTest__c )?0:prQuote.Miscellaneous_InTest__c) ;
				  prQuote.Miscellaneous_SS__c = Number(isNaN(prQuote.Miscellaneous_SS__c )?0:prQuote.Miscellaneous_SS__c);
				  prQuote.Miscellaneous_UAT__c = Number(isNaN(prQuote.Miscellaneous_UAT__c )?0:prQuote.Miscellaneous_UAT__c);

                          prQuote.Geo_Redundant_deployment_General__c = Number(isNaN(prQuote.Geo_Redundant_deployment_General__c )?0:prQuote.Geo_Redundant_deployment_General__c) ;
			        prQuote.Geo_Redundant_deployment_Dply__c = Number(isNaN(prQuote.Geo_Redundant_deployment_Dply__c )?0:prQuote.Geo_Redundant_deployment_Dply__c);
				  prQuote.Geo_Redundant_deployment_Doc__c  = Number(isNaN(prQuote.Geo_Redundant_deployment_Doc__c )?0:prQuote.Geo_Redundant_deployment_Doc__c) ;
				  prQuote.Geo_Redundant_deployment_Intg__c = Number(isNaN(prQuote.Geo_Redundant_deployment_Intg__c )?0:prQuote.Geo_Redundant_deployment_Intg__c) ;
				  prQuote.Geo_Redundant_deployment_InTest__c = Number(isNaN(prQuote.Geo_Redundant_deployment_InTest__c )?0:prQuote.Geo_Redundant_deployment_InTest__c) ;
				  prQuote.Geo_Redundant_deployment_SS__c = Number(isNaN(prQuote.Geo_Redundant_deployment_SS__c )?0:prQuote.Geo_Redundant_deployment_SS__c);
				  prQuote.Geo_Redundant_deployment_UAT__c = Number(isNaN(prQuote.Geo_Redundant_deployment_UAT__c )?0:prQuote.Geo_Redundant_deployment_UAT__c);

                          prQuote.Training_General_Hours__c = Number(isNaN(prQuote.Training_General_Hours__c)?0:prQuote.Training_General_Hours__c);
				  prQuote.Deployment_OffSite__c = Number(isNaN(prQuote.Deployment_OffSite__c)?0:prQuote.Deployment_OffSite__c);
				  prQuote.Deployment_OnSite__c = Number(isNaN(prQuote.Deployment_OnSite__c)?0:prQuote.Deployment_OnSite__c);
				  prQuote.PM_Offsite__c = Number(isNaN(prQuote.PM_Offsite__c)?0:prQuote.PM_Offsite__c);
				  prQuote.PM_Onsite__c = Number(isNaN(prQuote.PM_Onsite__c)?0:prQuote.PM_Onsite__c);
				  prQuote.Support_OffSite__c = Number(isNaN(prQuote.Support_OffSite__c)?0:prQuote.Support_OffSite__c);
				  prQuote.Support_OnSite__c = Number(isNaN(prQuote.Support_OnSite__c)?0:prQuote.Support_OnSite__c);
				  prQuote.Training_OffSite__c = Number(isNaN(prQuote.Training_OffSite__c)?0:prQuote.Training_OffSite__c);
				  prQuote.Training_OnSite__c = Number(isNaN(prQuote.Training_OnSite__c)?0:prQuote.Training_OnSite__c);
				  prQuote.Deployment_RoW__c = Number(isNaN(prQuote.Deployment_RoW__c)?0:prQuote.Deployment_RoW__c);
				  prQuote.PM_Row__c = Number(isNaN(prQuote.PM_Row__c)?0:prQuote.PM_Row__c);
				  prQuote.Support_Row__c = Number(isNaN(prQuote.Support_Row__c)?0:prQuote.Support_Row__c);
				  prQuote.Training_Row__c = Number(isNaN(prQuote.Training_Row__c)?0:prQuote.Training_Row__c);
				  prQuote.Post_production_Launch_spprt_General_Hrs__c = Number(isNaN(prQuote.Post_production_Launch_spprt_General_Hrs__c)?0:prQuote.Post_production_Launch_spprt_General_Hrs__c);

				  component.set("v.primaryQuote", prQuote);
				  //update PM totals
				          
                          helper.updateAllPMTotal(component,helper);
                          helper.updateDBTotals(component,helper);
                          helper.update3PInsTotals(component,helper);
                          helper.updateSoftInstTotals(component,helper);
                          helper.updateSoftInstAddTotals(component,helper);
                          helper.updateTestBedTotals(component,helper);
                          helper.updateMiscTotals(component,helper);
                          helper.updateGeoTotals(component,helper);
                          
			  }else{
				  console.log('In error ' + response);
			  }
		  });
		  //enqueuing the action
		  $A.enqueueAction(action);
      },
      /*************************************************************************************
      Method Name             `updateAllTotals`
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the row

      Created date            5/18/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/18/2017		Refer method header
      *************************************************************************************/
      updateAllTotals :function(component,helper){
    	  var generalTotal = 0;
    	  var softStagingTotal = 0;
    	  var deployTotals = 0;
    	  var integrationTotals = 0;
    	  var intenalTestingTotals = 0;
    	  var uatTotals = 0;
    	  var documentationTotals = 0;
    	  var prodSupportTotals = 0;

    	  var quoteLines = component.get("v.quoteLines");
    	  var runningQuote = component.get("v.primaryQuote");
          console.log('runningQuote KickOff_General_Hours__c ' +  runningQuote.KickOff_General_Hours__c);
    	  var pmTotal  =  component.get("v.totalPMRowSum");

	  /*
    	  //iterating the quotelines to get all quote line totals
    	  for(var iterating_index = 0; iterating_index < quoteLines.length ; iterating_index++){
    		  generalTotal = generalTotal + Number(isNaN(quoteLines[iterating_index].General_Hours__c)?0:quoteLines[iterating_index].General_Hours__c);
    		  softStagingTotal = softStagingTotal +  Number(isNaN(quoteLines[iterating_index].Soft_Staging_Hours__c)?0:quoteLines[iterating_index].Soft_Staging_Hours__c);
    		  deployTotals = deployTotals +  Number(isNaN(quoteLines[iterating_index].Deployment_Hours__c)?0:quoteLines[iterating_index].Deployment_Hours__c);
    		  integrationTotals = integrationTotals +  Number(isNaN(quoteLines[iterating_index].Integration_Hours__c)?0:quoteLines[iterating_index].Integration_Hours__c);
    		  intenalTestingTotals = intenalTestingTotals + Number(isNaN(quoteLines[iterating_index].Internal_Testing_Hours__c)?0:quoteLines[iterating_index].Internal_Testing_Hours__c);
    		  uatTotals = uatTotals + Number(isNaN(quoteLines[iterating_index].UAT_Hours__c)?0:quoteLines[iterating_index].UAT_Hours__c);
    		  documentationTotals = documentationTotals + Number(isNaN(quoteLines[iterating_index].Documentation_Hours__c)?0:quoteLines[iterating_index].Documentation_Hours__c);
    		  prodSupportTotals = prodSupportTotals +  Number(isNaN(quoteLines[iterating_index].Production_Launch_Support_Hours__c)?0:quoteLines[iterating_index].Production_Launch_Support_Hours__c);

    	  }
	  */
    	  //Ensuring that generic product values are added
    	  //Adding general column total
    	  generalTotal = generalTotal
    	  				+ Number(isNaN(runningQuote.PM_General_Hours__c )?0:runningQuote.PM_General_Hours__c )
    	  				+ Number(isNaN(runningQuote.KickOff_General_Hours__c )?0:runningQuote.KickOff_General_Hours__c )
    	  				+ Number(isNaN(runningQuote.Training_General_Hours__c )?0:runningQuote.Training_General_Hours__c )
    	  				+ Number(isNaN(runningQuote.Post_production_Launch_spprt_General_Hrs__c )?0:runningQuote.Post_production_Launch_spprt_General_Hrs__c )
					+ Number(isNaN(runningQuote.Software_Installation_Main_Phase_General__c )?0:runningQuote.Software_Installation_Main_Phase_General__c )
                              + Number(isNaN(runningQuote.Software_Installation_Addi_Phases_Gen__c )?0:runningQuote.Software_Installation_Addi_Phases_Gen__c )
                              + Number(isNaN(runningQuote.Test_Bed_deployment_General__c )?0:runningQuote.Test_Bed_deployment_General__c )
                              + Number(isNaN(runningQuote.Geo_Redundant_deployment_General__c )?0:runningQuote.Geo_Redundant_deployment_General__c )
                              + Number(isNaN(runningQuote.Database_deployment_General__c )?0:runningQuote.Database_deployment_General__c )
                              + Number(isNaN(runningQuote.Third_Party_installation_Gen__c )?0:runningQuote.Third_Party_installation_Gen__c )
                              + Number(isNaN(runningQuote.Miscellaneous_Gen__c )?0:runningQuote.Miscellaneous_Gen__c );

    	  //Adding soft staging column total
    	  softStagingTotal = softStagingTotal
    	  					 + Number(isNaN(runningQuote.Software_Installation_Main_Phase_SS__c )?0:runningQuote.Software_Installation_Main_Phase_SS__c )
                                     + Number(isNaN(runningQuote.Software_Installation_Add_Phases_SS__c )?0:runningQuote.Software_Installation_Add_Phases_SS__c )
                                     + Number(isNaN(runningQuote.Test_Bed_deployment_SS__c )?0:runningQuote.Test_Bed_deployment_SS__c )
                                     + Number(isNaN(runningQuote.Geo_Redundant_deployment_SS__c )?0:runningQuote.Geo_Redundant_deployment_SS__c )
                                     + Number(isNaN(runningQuote.Database_deployment_SS__c )?0:runningQuote.Database_deployment_SS__c )
                                     + Number(isNaN(runningQuote.Third_Party_installation_SS__c )?0:runningQuote.Third_Party_installation_SS__c )
                                     + Number(isNaN(runningQuote.Miscellaneous_SS__c )?0:runningQuote.Miscellaneous_SS__c );

    	  //Adding deployTotals column total
    	  deployTotals = deployTotals
    	  					 + Number(isNaN(runningQuote.Software_Installation_Main_Phase_Deploy__c )?0:runningQuote.Software_Installation_Main_Phase_Deploy__c )
                                     + Number(isNaN(runningQuote.Software_Installation_Add_Phases_Dply__c )?0:runningQuote.Software_Installation_Add_Phases_Dply__c )
                                     + Number(isNaN(runningQuote.Test_Bed_deployment_Dply__c )?0:runningQuote.Test_Bed_deployment_Dply__c )
                                     + Number(isNaN(runningQuote.Geo_Redundant_deployment_Dply__c )?0:runningQuote.Geo_Redundant_deployment_Dply__c )
                                     + Number(isNaN(runningQuote.Database_deployment_Dply__c )?0:runningQuote.Database_deployment_Dply__c )
                                     + Number(isNaN(runningQuote.Third_Party_installation_Dply__c )?0:runningQuote.Third_Party_installation_Dply__c )
                                     + Number(isNaN(runningQuote.Miscellaneous_Dply__c )?0:runningQuote.Miscellaneous_Dply__c );


    	  //Adding integrationTotals column total
    	  integrationTotals = integrationTotals
    	  					 + Number(isNaN(runningQuote.Software_Installation_Main_Phase_Intg__c )?0:runningQuote.Software_Installation_Main_Phase_Intg__c)
                                     + Number(isNaN(runningQuote.Software_Installation_Add_Phases_Intg__c )?0:runningQuote.Software_Installation_Add_Phases_Intg__c )
                                     + Number(isNaN(runningQuote.Test_Bed_deployment_Intg__c )?0:runningQuote.Test_Bed_deployment_Intg__c )
                                     + Number(isNaN(runningQuote.Geo_Redundant_deployment_Intg__c )?0:runningQuote.Geo_Redundant_deployment_Intg__c )
                                     + Number(isNaN(runningQuote.Database_deployment_Intg__c )?0:runningQuote.Database_deployment_Intg__c )
                                     + Number(isNaN(runningQuote.Third_Party_installation_Intg__c )?0:runningQuote.Third_Party_installation_Intg__c )
                                     + Number(isNaN(runningQuote.Miscellaneous_Intg__c )?0:runningQuote.Miscellaneous_Intg__c );


    	  //Adding intenalTestingTotals column total
    	  intenalTestingTotals = intenalTestingTotals
    	  					 + Number(isNaN(runningQuote.Software_Installation_Main_Phase_InTest__c )?0:runningQuote.Software_Installation_Main_Phase_InTest__c )
                                     + Number(isNaN(runningQuote.Software_Installation_Add_Phases_InTest__c )?0:runningQuote.Software_Installation_Add_Phases_InTest__c )
                                     + Number(isNaN(runningQuote.Test_Bed_deployment_InTest__c )?0:runningQuote.Test_Bed_deployment_InTest__c )
                                     + Number(isNaN(runningQuote.Geo_Redundant_deployment_InTest__c )?0:runningQuote.Geo_Redundant_deployment_InTest__c )
                                     + Number(isNaN(runningQuote.Database_deployment_InTest__c )?0:runningQuote.Database_deployment_InTest__c )
                                     + Number(isNaN(runningQuote.Third_Party_installation_inTest__c )?0:runningQuote.Third_Party_installation_inTest__c )
                                     + Number(isNaN(runningQuote.Miscellaneous_InTest__c )?0:runningQuote.Miscellaneous_InTest__c );


    	  //Adding soft staging column total
    	  uatTotals = uatTotals
    	  					 + Number(isNaN(runningQuote.Software_Installation_Main_Phase_UAT__c )?0:runningQuote.Software_Installation_Main_Phase_UAT__c )
                                     + Number(isNaN(runningQuote.Software_Installation_Add_Phases_UAT__c )?0:runningQuote.Software_Installation_Add_Phases_UAT__c )
                                     + Number(isNaN(runningQuote.Test_Bed_deployment_UAT__c )?0:runningQuote.Test_Bed_deployment_UAT__c )
                                     + Number(isNaN(runningQuote.Geo_Redundant_deployment_UAT__c )?0:runningQuote.Geo_Redundant_deployment_UAT__c )
                                     + Number(isNaN(runningQuote.Database_deployment_UAT__c )?0:runningQuote.Database_deployment_UAT__c )
                                     + Number(isNaN(runningQuote.Third_Party_installation_UAT__c )?0:runningQuote.Third_Party_installation_UAT__c )
                                     + Number(isNaN(runningQuote.Miscellaneous_UAT__c )?0:runningQuote.Miscellaneous_UAT__c );


    	  //Adding soft staging column total
    	  documentationTotals = documentationTotals
    	  					 + Number(isNaN(runningQuote.Software_Installation_Main_Phase_Doc__c )?0:runningQuote.Software_Installation_Main_Phase_Doc__c )
                                     + Number(isNaN(runningQuote.Software_Installation_Add_Phases_Doc__c )?0:runningQuote.Software_Installation_Add_Phases_Doc__c )
                                     + Number(isNaN(runningQuote.Test_Bed_deployment_Doc__c )?0:runningQuote.Test_Bed_deployment_Doc__c )
                                     + Number(isNaN(runningQuote.Geo_Redundant_deployment_Doc__c )?0:runningQuote.Geo_Redundant_deployment_Doc__c )
                                     + Number(isNaN(runningQuote.Database_deployment_Doc__c )?0:runningQuote.Database_deployment_Doc__c )
                                     + Number(isNaN(runningQuote.Third_Party_installation_Doc__c )?0:runningQuote.Third_Party_installation_Doc__c )
                                     + Number(isNaN(runningQuote.Miscellaneous_Doc__c )?0:runningQuote.Miscellaneous_Doc__c );


    	  //Adding overall total
    	  var overallTotal =      generalTotal
    	  						+ softStagingTotal
    	  						+ deployTotals
    	  						+ integrationTotals
    	  						+ intenalTestingTotals
    	  						+ uatTotals
    	  						+ documentationTotals;

    	  //Setting deploymentHeaderTotalHours
    	  var deploymentHeaderTotalHours = overallTotal
    	  								-
    	  								(
    	  								  Number(isNaN(pmTotal)?0:pmTotal )
    	  								+ Number(isNaN(runningQuote.Training_General_Hours__c )?0:runningQuote.Training_General_Hours__c )
    	  								+ Number(isNaN(runningQuote.Post_production_Launch_spprt_General_Hrs__c )?0:runningQuote.Post_production_Launch_spprt_General_Hrs__c )
    	  								);
    	  //Setting all values back
    	  component.set("v.totalGenHours", generalTotal);
    	  component.set("v.totalSSHours", softStagingTotal);
    	  component.set("v.totalDeployHours", deployTotals);
    	  component.set("v.totalIntegHours", integrationTotals);
    	  component.set("v.totalIntTestHours", intenalTestingTotals);
    	  component.set("v.totalUATHours", uatTotals);
    	  component.set("v.totalDocHours", documentationTotals);
    	  component.set("v.totalProdHours", prodSupportTotals);
    	  component.set("v.deploymentHeaderTotalHours", deploymentHeaderTotalHours);
    	  component.set("v.totalHours", overallTotal);
			// component.set("v.primaryQuote", runningQuote);
    	  //helper method to look for button visibility
    	 helper.validateAllHeaderHours(component,helper);
      },
      /*************************************************************************************
      Method Name             updateAllPMTotal
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the row

      Created date            5/18/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/18/2017		Refer method header
      *************************************************************************************/
      updateAllPMTotal : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");
    	  console.log('runningQuote KickOff_General_Hours__c ' +  runningQuote.KickOff_General_Hours__c);
    	  //Adding the PM hours
    	  var rowTotal =    Number(isNaN(runningQuote.PM_General_Hours__c )?0:runningQuote.PM_General_Hours__c) +
    	  					Number(isNaN(runningQuote.PM_Deployment_Hours__c )?0:runningQuote.PM_Deployment_Hours__c) +
    	  					Number(isNaN(runningQuote.PM_Documentation_Hours__c )?0:runningQuote.PM_Documentation_Hours__c) +
    	  					Number(isNaN(runningQuote.PM_Integration_Hours__c )?0:runningQuote.PM_Integration_Hours__c) +
    	  					Number(isNaN(runningQuote.PM_Internal_Testing_Hours__c )?0:runningQuote.PM_Internal_Testing_Hours__c) +
    	  					Number(isNaN(runningQuote.PM_Production_Launch_Support_Hours__c )?0:runningQuote.PM_Production_Launch_Support_Hours__c)+
    	  					Number(isNaN(runningQuote.PM_Soft_Staging_Hours__c )?0:runningQuote.PM_Soft_Staging_Hours__c)+
    	  					Number(isNaN(runningQuote.PM_UAT_Hours__c )?0:runningQuote.PM_UAT_Hours__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the PM hours
         component.set("v.totalPMRowSum", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
	/*************************************************************************************
      Method Name             updateSoftInstTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Software installation

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017			Refer method header
      *************************************************************************************/
      updateSoftInstTotals : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");
    	  console.log('In updateSoftInstTotals edit');
    	  //Adding the Software installation hours
    	  var rowTotal =              Number(isNaN(runningQuote.Software_Installation_Main_Phase_General__c )?0:runningQuote.Software_Installation_Main_Phase_General__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Main_Phase_Deploy__c )?0:runningQuote.Software_Installation_Main_Phase_Deploy__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Main_Phase_Doc__c )?0:runningQuote.Software_Installation_Main_Phase_Doc__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Main_Phase_Intg__c )?0:runningQuote.Software_Installation_Main_Phase_Intg__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Main_Phase_InTest__c )?0:runningQuote.Software_Installation_Main_Phase_InTest__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Main_Phase_SS__c )?0:runningQuote.Software_Installation_Main_Phase_SS__c)+
    	  					Number(isNaN(runningQuote.Software_Installation_Main_Phase_UAT__c )?0:runningQuote.Software_Installation_Main_Phase_UAT__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the total software installation hours
         component.set("v.totalSoftInstallRow", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateMiscTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Software installation

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017			Refer method header
      *************************************************************************************/
      updateMiscTotals : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");

    	  //Adding the Software installation hours
    	  var rowTotal =              Number(isNaN(runningQuote.Miscellaneous_Gen__c )?0:runningQuote.Miscellaneous_Gen__c) +
    	  					Number(isNaN(runningQuote.Miscellaneous_Dply__c )?0:runningQuote.Miscellaneous_Dply__c) +
    	  					Number(isNaN(runningQuote.Miscellaneous_Doc__c )?0:runningQuote.Miscellaneous_Doc__c) +
    	  					Number(isNaN(runningQuote.Miscellaneous_Intg__c )?0:runningQuote.Miscellaneous_Intg__c) +
    	  					Number(isNaN(runningQuote.Miscellaneous_InTest__c )?0:runningQuote.Miscellaneous_InTest__c) +
    	  					Number(isNaN(runningQuote.Miscellaneous_SS__c )?0:runningQuote.Miscellaneous_SS__c)+
    	  					Number(isNaN(runningQuote.Miscellaneous_UAT__c )?0:runningQuote.Miscellaneous_UAT__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the total software installation hours
         component.set("v.totalMiscRow", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateSoftInstAddTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Software installation additional

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateSoftInstAddTotals : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");
    	  console.log('In updateSoftInstADDTotals edit');
    	  //Adding the Software installation hours
    	  var rowTotal =              Number(isNaN(runningQuote.Software_Installation_Addi_Phases_Gen__c )?0:runningQuote.Software_Installation_Addi_Phases_Gen__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Add_Phases_Dply__c )?0:runningQuote.Software_Installation_Add_Phases_Dply__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Add_Phases_Doc__c )?0:runningQuote.Software_Installation_Add_Phases_Doc__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Add_Phases_Intg__c )?0:runningQuote.Software_Installation_Add_Phases_Intg__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Add_Phases_InTest__c )?0:runningQuote.Software_Installation_Add_Phases_InTest__c) +
    	  					Number(isNaN(runningQuote.Software_Installation_Add_Phases_SS__c )?0:runningQuote.Software_Installation_Add_Phases_SS__c)+
    	  					Number(isNaN(runningQuote.Software_Installation_Add_Phases_UAT__c )?0:runningQuote.Software_Installation_Add_Phases_UAT__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the total software installation hours
         component.set("v.totalSoftInstallAdditionalRow", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateTestBedTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Test Bed Deployment additional

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateTestBedTotals : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");
    	  console.log('In updateSoftInstADDTotals edit');
    	  //Adding the Software installation hours
    	  var rowTotal =              Number(isNaN(runningQuote.Test_Bed_deployment_General__c )?0:runningQuote.Test_Bed_deployment_General__c) +
    	  					Number(isNaN(runningQuote.Test_Bed_deployment_Dply__c )?0:runningQuote.Test_Bed_deployment_Dply__c) +
    	  					Number(isNaN(runningQuote.Test_Bed_deployment_Doc__c )?0:runningQuote.Test_Bed_deployment_Doc__c) +
    	  					Number(isNaN(runningQuote.Test_Bed_deployment_Intg__c )?0:runningQuote.Test_Bed_deployment_Intg__c) +
    	  					Number(isNaN(runningQuote.Test_Bed_deployment_InTest__c )?0:runningQuote.Test_Bed_deployment_InTest__c) +
    	  					Number(isNaN(runningQuote.Test_Bed_deployment_SS__c )?0:runningQuote.Test_Bed_deployment_SS__c)+
    	  					Number(isNaN(runningQuote.Test_Bed_deployment_UAT__c )?0:runningQuote.Test_Bed_deployment_UAT__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the total software installation hours
         component.set("v.totalTestBedRow", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateDBTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Test Bed Deployment additional

      Created date            6/9/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/9/2017		Refer method header
      *************************************************************************************/
      updateDBTotals : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");

    	  //Adding the Software installation hours
    	  var rowTotal =              Number(isNaN(runningQuote.Database_deployment_General__c )?0:runningQuote.Database_deployment_General__c) +
    	  					Number(isNaN(runningQuote.Database_deployment_Dply__c )?0:runningQuote.Database_deployment_Dply__c) +
    	  					Number(isNaN(runningQuote.Database_deployment_Doc__c )?0:runningQuote.Database_deployment_Doc__c) +
    	  					Number(isNaN(runningQuote.Database_deployment_Intg__c )?0:runningQuote.Database_deployment_Intg__c) +
    	  					Number(isNaN(runningQuote.Database_deployment_InTest__c )?0:runningQuote.Database_deployment_InTest__c) +
    	  					Number(isNaN(runningQuote.Database_deployment_SS__c )?0:runningQuote.Database_deployment_SS__c)+
    	  					Number(isNaN(runningQuote.Database_deployment_UAT__c )?0:runningQuote.Database_deployment_UAT__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the total software installation hours
         component.set("v.totalDBRow", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             update3PInsTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the row

      Created date            6/9/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/9/2017		Refer method header
      *************************************************************************************/
      update3PInsTotals : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");

    	  //Adding the Software installation hours
    	  var rowTotal =              Number(isNaN(runningQuote.Third_Party_installation_Gen__c )?0:runningQuote.Third_Party_installation_Gen__c) +
    	  					Number(isNaN(runningQuote.Third_Party_installation_Dply__c )?0:runningQuote.Third_Party_installation_Dply__c) +
    	  					Number(isNaN(runningQuote.Third_Party_installation_Doc__c )?0:runningQuote.Third_Party_installation_Doc__c) +
    	  					Number(isNaN(runningQuote.Third_Party_installation_Intg__c )?0:runningQuote.Third_Party_installation_Intg__c) +
    	  					Number(isNaN(runningQuote.Third_Party_installation_inTest__c )?0:runningQuote.Third_Party_installation_inTest__c) +
    	  					Number(isNaN(runningQuote.Third_Party_installation_SS__c )?0:runningQuote.Third_Party_installation_SS__c)+
    	  					Number(isNaN(runningQuote.Third_Party_installation_UAT__c )?0:runningQuote.Third_Party_installation_UAT__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the total software installation hours
         component.set("v.total3PInstRow", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateGeoTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Test Bed Deployment additional

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateGeoTotals : function(component,helper){
    	  //getting the running Quote
    	  var runningQuote = component.get("v.primaryQuote");

    	  //Adding the Software installation hours
    	  var rowTotal =              Number(isNaN(runningQuote.Geo_Redundant_deployment_General__c )?0:runningQuote.Geo_Redundant_deployment_General__c) +
    	  					Number(isNaN(runningQuote.Geo_Redundant_deployment_Dply__c )?0:runningQuote.Geo_Redundant_deployment_Dply__c) +
    	  					Number(isNaN(runningQuote.Geo_Redundant_deployment_Doc__c )?0:runningQuote.Geo_Redundant_deployment_Doc__c) +
    	  					Number(isNaN(runningQuote.Geo_Redundant_deployment_Intg__c )?0:runningQuote.Geo_Redundant_deployment_Intg__c) +
    	  					Number(isNaN(runningQuote.Geo_Redundant_deployment_InTest__c )?0:runningQuote.Geo_Redundant_deployment_InTest__c) +
    	  					Number(isNaN(runningQuote.Geo_Redundant_deployment_SS__c )?0:runningQuote.Geo_Redundant_deployment_SS__c)+
    	  					Number(isNaN(runningQuote.Geo_Redundant_deployment_UAT__c )?0:runningQuote.Geo_Redundant_deployment_UAT__c);

    	if(isNaN(rowTotal))
            rowTotal = 0;
         //Setting the total software installation hours
         component.set("v.totalGeoRow", rowTotal);
         //Calculating all totals
         helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             validateAllHeaderHours
      Developed By            West Monroe Partners
      Purpose                 * To validate the hours

      Created date            5/19/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/19/2017		Refer method header
      *************************************************************************************/
      validateAllHeaderHours : function(component,helper){
    	//getting the primary quote
    	var primaryQuote = component.get("v.primaryQuote");
          console.log('In validateHeaders >> ' + primaryQuote.KickOff_General_Hours__c)
    	//checking for save button appearance condition
    	if(
	    	(component.get("v.deploymentHeaderTotalHours") == (primaryQuote.Deployment_OffSite__c + primaryQuote.Deployment_OnSite__c + primaryQuote.Deployment_RoW__c))
	     && (primaryQuote.Post_production_Launch_spprt_General_Hrs__c == (primaryQuote.Support_OffSite__c + primaryQuote.Support_OnSite__c + primaryQuote.Support_Row__c))
	     && (primaryQuote.Training_General_Hours__c == (primaryQuote.Training_OffSite__c + primaryQuote.Training_OnSite__c + primaryQuote.Training_Row__c))
	     && (component.get("v.totalPMRowSum") == (primaryQuote.PM_Offsite__c + primaryQuote.PM_Onsite__c + primaryQuote.PM_Row__c))
	     ){
	      //setting visibility to true
	      component.set("v.allowSave", true);
        }else{
        	//setting visibility to false
        	component.set("v.allowSave", false);
        }
          //component.set("v.primaryQuote",primaryQuote);
      },
      /*************************************************************************************
      Method Name             getSaveButtonAccess
      Developed By            West Monroe Partners
      Purpose                 * To validate the if the running user is a PSO
      Created date            6/9/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/9/2017		Refer method header
      *************************************************************************************/
      getSaveButtonAccess : function(component,helper){
            //method to call to check if the runing user is a PSO
            var action = component.get("c.fetchSaveAccesss");
            //Handling the call back
        	action.setCallback(this, function(response){
        		  var state = response.getState();
        		  if(state=='SUCCESS'){
        			  console.log('Save boolena Response value >> '+ response.getReturnValue());
      		        component.set("v.showSave", response.getReturnValue());
                    }else{
                          console.log(response);
                    }
        	  });
        	  //enqueuing the action
    		  $A.enqueueAction(action);
      }
})