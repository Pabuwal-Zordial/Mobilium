({
	/*************************************************************************************
      Method Name             doInit
      Developed By            West Monroe Partners
      Purpose                 * To populate the following
									* products from quote lines
									* products from generic products
 									* validate rows and columns in summarizer
      Created date            5/15/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/15/2017		Refer method header
      *************************************************************************************/
  	mtd_dataLoaderForQuote : function(component, event, helper) {
  		//Getting the quote line for the quote from which the button is clicked
  		helper.getQuoteLineProducts(component);
  		//Getting the column headers from the custom metadata types
  		helper.getColumnHeaders(component);
  		//Getting the generic products
  		helper.getCommonProducts(component);
  		 component.set("v.showSave",false);
            //checking if the user is a part of the group
            helper.getSaveButtonAccess(component,helper);
        //Getting the primary quote
  		helper.getPrimaryQuote(component,helper);
  		//setting all totals to be 0 - attributes in markup
  		component.set("v.totalGenHours", 0);
          	component.set("v.totalSSHours", 0);
          	component.set("v.totalDeployHours", 0);
          	component.set("v.totalIntegHours", 0);
            component.set("v.totalIntTestHours", 0);
          	component.set("v.totalUATHours", 0);
          	component.set("v.totalDocHours", 0);
          	component.set("v.totalProdHours", 0);
          	component.set("v.totalHours", 0);
          	component.set("v.totalPMRowSum", 0);
          	component.set("v.deploymentHeaderTotalHours", 0);
          	component.set("v.allowSave", false);
          	component.set("v.instructionText" ,'');
            component.set("v.totalSoftInstallRow",0);
            component.set("v.totalSoftInstallAdditionalRow",0);
            component.set("v.totalTestBedRow",0);
            component.set("v.totalGeoRow",0);
            component.set("v.totalDBRow",0);
            component.set("v.total3PInstRow",0);
            component.set("v.totalMiscRow",0);
            component.set("v.showAccordian",false);
        
  	},

      /*************************************************************************************
      Method Name             updateTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the row

      Created date            5/18/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/18/2017		Refer method header
      *************************************************************************************/
      updateTotals : function(component,event,helper){
    	  console.log('About to make the call');
          //Calculating all totals
    	    helper.updateAllTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updatePMTotal
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the row

      Created date            5/18/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/18/2017		Refer method header
      *************************************************************************************/
      updatePMTotal : function(component,event,helper){
    	  //update PM totals
    	  helper.updateAllPMTotal(component,helper);
      },
      /*************************************************************************************
      Method Name             updateDBTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the row

      Created date            6/9/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/9/2017		Refer method header
      *************************************************************************************/
      updateDBTotals : function(component,event,helper){
    	  //update DB totals
    	  helper.updateDBTotals(component,helper);
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
      update3PInsTotals : function(component,event,helper){
    	  //update DB totals
    	  helper.update3PInsTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateSoftInstTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Software installation row

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateSoftInstTotals : function(component,event,helper){
    	  //update PM totals
    	  helper.updateSoftInstTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateSoftInstAddTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the Software installation additional row

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateSoftInstAddTotals : function(component,event,helper){
    	  //update PM totals
    	  helper.updateSoftInstAddTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateTestBedTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the test bed

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateTestBedTotals : function(component,event,helper){
    	  //update PM totals
    	  helper.updateTestBedTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateMiscTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the test bed

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateMiscTotals : function(component,event,helper){
    	  //update PM totals
    	  helper.updateMiscTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             updateGeoTotals
      Developed By            West Monroe Partners
      Purpose                 * To populate the total sum for the test bed

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		6/8/2017		Refer method header
      *************************************************************************************/
      updateGeoTotals : function(component,event,helper){
    	  //update PM totals
    	  helper.updateGeoTotals(component,helper);
      },
      /*************************************************************************************
      Method Name             validateHeaderHours
      Developed By            West Monroe Partners
      Purpose                 * To validate the hours

      Created date            5/19/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/19/2017		Refer method header
      *************************************************************************************/
      validateHeaderHours : function(component,event,helper){
    	//helper method to look for button visibility
    	helper.validateAllHeaderHours(component,helper);
     },
     /*************************************************************************************
      Method Name             saveLoE
      Developed By            West Monroe Partners
      Purpose                 * To save LoE and the hours

      Created date            5/19/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		5/19/2017		Refer method header
      *************************************************************************************/
      saveLoE :function(component,event,helper){
    	  //getting info to save
    	  //getting the primary quote
    	  var primaryQuote = component.get("v.primaryQuote");
    	  //getting the quote lines
    	  var quoteLines = component.get("v.quoteLines");

    	  //save the quote and the quote lines
    	  var action = component.get("c.saveQuoteAndLines");
			action.setParams({
				"primaryQuote" : primaryQuote,
				"list_quoteLines" : quoteLines
		    });
		  //Handling the call back
		  action.setCallback(this, function(response){
				var state = response.getState();
				if(state == "SUCCESS"){
						//letting the user know that the record saved
						var toastEvent = $A.get("e.force:showToast");
						toastEvent.setParams({
							"title": "Records saved",
							"message":  $A.get("$Label.c.LoE_Success_PageMessage"),
							"type":"success",
							"mode":"pester"
						});
						toastEvent.fire();
						//refreshing the page

					}else if(state == 'ERROR'){
						//parsing the error
						var errors = action.getError();
						//console.log('state is >> ' + errors);
						//console.log('state is >> ' + errors.length);
					    //console.log('response is >> ' + response);
						if(errors.length > 0){
							//throwing an error toast to display the error message in case
							//there are apex exceptions
							//validation rule failing
							//Other default salesforce exceptions
							//console.log('state is 1 >> ' + errors.length);
								var toastEvent = $A.get("e.force:showToast");
								toastEvent.setParams({
									"title": "Unexpected Error!",
									"message": "Please contact your system administrator",
									"type":"error",
									"mode":"sticky"
								});
								toastEvent.fire();
						}
				  }
			});
		     $A.enqueueAction(action);
      },
      /*************************************************************************************
      Method Name             showModal
      Developed By            West Monroe Partners
      Purpose                 * To show instruction model based on the place it is clicked from

      Created date            5/21/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	 DATE      		DETAIL
      1.0		SS		 5/21/2017		Refer method header
      *************************************************************************************/
      showModal : function(component, event, helper) {

        document.getElementById("newClientSectionId").style.display = "block";
        var idPassed =  event.target.id;
        document.getElementById("header43").innerHTML = idPassed;
        //getting the primary quote
    	  var primaryQuote = component.get("v.primaryQuote");
        //getting the common products header
        var commonProducts = component.get("v.commonProducts");
        var defaultvalue;
        //if idPassed is first in the list returned
        if(commonProducts[0].MasterLabel == idPassed)
        	defaultvalue = primaryQuote.Kick_Off_Instructions__c;
        else if(commonProducts[1].MasterLabel == idPassed)
        	defaultvalue = primaryQuote.Software_Installation_Main_Phase_Ins__c;
        else if(commonProducts[2].MasterLabel == idPassed)
        	defaultvalue = primaryQuote.Software_Installation_Add_Phases_Insts__c;
        else if(commonProducts[3].MasterLabel == idPassed)
            defaultvalue = primaryQuote.Test_Bed_deployment_Inst__c;
        else if(commonProducts[4].MasterLabel == idPassed)
            defaultvalue = primaryQuote.Geo_Redundant_deployment_Inst__c;
        else if(commonProducts[5].MasterLabel == idPassed)
            defaultvalue = primaryQuote.Database_deployment_Insts__c;
        else if(commonProducts[6].MasterLabel == idPassed)
            defaultvalue = primaryQuote.Third_Party_installation_Inst__c;
        else if(commonProducts[7].MasterLabel == idPassed)
            defaultvalue = primaryQuote.Miscellaneous_Inst__c;
        else if(commonProducts[8].MasterLabel == idPassed)
            defaultvalue = primaryQuote.Launch_support_instructions__c;
        else if(commonProducts[9].MasterLabel == idPassed)
            defaultvalue = primaryQuote.Training_Instructions__c;
        else
        	defaultvalue = primaryQuote.PM_Instructions__c;

        //setting the value
        component.set("v.instructionText" ,defaultvalue);
	  },
	  /*************************************************************************************
      Method Name             saveInstruction
      Developed By            West Monroe Partners
      Purpose                 * To save the actual instruction

      Created date            5/21/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	 DATE      		DETAIL
      1.0		SS		 5/21/2017		Refer method header
      *************************************************************************************/
      saveInstruction :function(component,event,helper){
    	  //getting the primary quote
    	  var primaryQuote = component.get("v.primaryQuote");
    	  var instruction = component.get("v.instructionText");
    	  //getting the common products header
          var commonProducts = component.get("v.commonProducts");
    	  var idPassed = document.getElementById("header43").innerHTML;
    	  //if idPassed is first in the list returned
        if(commonProducts[0].MasterLabel == idPassed)
        	primaryQuote.Kick_Off_Instructions__c = instruction;
        else if(commonProducts[1].MasterLabel == idPassed)
        	primaryQuote.Software_Installation_Main_Phase_Ins__c = instruction;
        else if(commonProducts[2].MasterLabel == idPassed)
        	primaryQuote.Software_Installation_Add_Phases_Insts__c = instruction;
        else if(commonProducts[3].MasterLabel == idPassed)
            primaryQuote.Test_Bed_deployment_Inst__c = instruction;
        else if(commonProducts[4].MasterLabel == idPassed)
            primaryQuote.Geo_Redundant_deployment_Inst__c = instruction;
        else if(commonProducts[5].MasterLabel == idPassed)
            primaryQuote.Database_deployment_Insts__c = instruction;
        else if(commonProducts[6].MasterLabel == idPassed)
            primaryQuote.Third_Party_installation_Inst__c = instruction;
        else if(commonProducts[7].MasterLabel == idPassed)
            primaryQuote.Miscellaneous_Inst__c = instruction;
        else if(commonProducts[8].MasterLabel == idPassed)
            primaryQuote.Launch_support_instructions__c = instruction;
        else if(commonProducts[9].MasterLabel == idPassed)
            primaryQuote.Training_Instructions__c = instruction;
        else
        	primaryQuote.PM_Instructions__c = instruction;

        component.set("v.instructionText" ,'');
        component.set("v.primaryQuote" ,primaryQuote);
        document.getElementById("newClientSectionId").style.display = "none" ;
      },
      /*************************************************************************************
      Method Name             hideModal
      Developed By            West Monroe Partners
      Purpose                 * To hide instruction model based on the place it is clicked from

      Created date            5/21/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	 DATE      		DETAIL
      1.0		SS		 5/21/2017		Refer method header
      *************************************************************************************/
	  hideModal : function(component,event, helper){
	       document.getElementById("newClientSectionId").style.display = "none" ;
      },
      /*************************************************************************************
      Method Name             showSystemError
      Developed By            West Monroe Partners
      Purpose                 * To hide instruction model based on the place it is clicked from

      Created date            6/9//2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	 DATE      		DETAIL
      1.0		SS		 6/9/2017		Refer method header
      *************************************************************************************/
      showSystemError: function(component,event, helper) {
        // Handle system error
        console.log('showSystemError' + component);
        console.log(event);
     },
     /*************************************************************************************
     Method Name             toggleAccordian
     Developed By            West Monroe Partners
     Purpose                 * To hide instruction model based on the place it is clicked from

     Created date            6/9//2017
     History
     ------------------------------------------------------------------------------------
     VERSION  	AUTHOR 	 DATE      		DETAIL
     1.0		SS		 6/9/2017		Refer method header
     *************************************************************************************/
     toggleAccordian : function(component){
           console.log('In toggle Accordian');
           var classOfButton = document.getElementById('accordianDiv').className;
           if(classOfButton.includes('slds-is-open')){
                  document.getElementById('accordianDiv').className = 'test-id__section slds-section  full forcePageBlockSection forcePageBlockSectionView';
                  component.set("v.showAccordian", false);
           }else{
                  document.getElementById('accordianDiv').className = 'test-id__section slds-section  slds-is-open full forcePageBlockSection forcePageBlockSectionView';
                  component.set("v.showAccordian", true);
           }
     }
})