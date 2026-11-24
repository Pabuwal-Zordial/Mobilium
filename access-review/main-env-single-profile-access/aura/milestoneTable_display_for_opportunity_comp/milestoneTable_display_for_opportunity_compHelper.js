({
	/*************************************************************************************
      Method Name             getMilestoneHeaders
      Developed By            West Monroe Partners
      Purpose                 * To interact with apex to fetch the milestone heaeder informatiokn
						from the custom metadata

      Created date            2/2/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/2/2017		Refer method header
      *************************************************************************************/
	getMilestoneHeaders : function(component) {
		//Method to fetch the milestone heaeders from the custom metadata type
		var action = component.get("c.fetchMilestoneHeaders");

		//Handling the call back
		action.setCallback(this, function(response){

			 var state = response.getState();
			 //$A.log(response);
			 if(state == "SUCCESS"){
			 	//Setting the values back to projects
				component.set("v.milestoneHeaders", response.getReturnValue());
				//console.log( response.getReturnValue());
			 }
		});
		$A.enqueueAction(action);
	},
	/*************************************************************************************
      Method Name             getProject
      Developed By            West Monroe Partners
      Purpose                 * To query the project and populate the date information
      Created date            2/2/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/2/2017		Refer method header
      *************************************************************************************/
	getProject : function(component, runningProjectId, callback){

		//Method to fetch the milestone heaeders from the custom metadata type
		var action = component.get("c.fetchProjectDetails");

		//Setting parameters for the method call
		action.setParams({
			"projectId" : runningProjectId
		});

		//Handling the call back
		action.setCallback(this, function(response){
			var state = response.getState();
			//$A.log(response);
			if(state == "SUCCESS"){
				component.set("v.project", response.getReturnValue());
				//console.log(response.getReturnValue());
			}
		});
		$A.enqueueAction(action);

	},
	/*************************************************************************************
      Method Name             getMilestoneRows
      Developed By            West Monroe Partners
      Purpose                 * To query the milestone rows to be displayed on the page
      Created date            2/3/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/3/2017		Refer method header
      *************************************************************************************/
	getMilestoneRows : function(component, runningProjectId, callback){


		//Method to fetch the milestone heaeders from the custom metadata type
		var action = component.get("c.fetchMilestoneRows");
		//Setting parameters for the method call
		action.setParams({
			"projectId" : runningProjectId
		});

		//Handling the call back
		action.setCallback(this, function(response){
			var state = response.getState();
			//$A.log(response);
			if(state == "SUCCESS"){
				component.set("v.milestoneRows", response.getReturnValue());
				document.getElementById("loadingSpinner").style.display = "none";
			}
		});
		$A.enqueueAction(action);

	},
	/*************************************************************************************
      Method Name             validateRows
      Developed By            West Monroe Partners
      Purpose                 * To validate all rows
      Created date            2/4/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/4/2017		Refer method header
      *************************************************************************************/
	validateRowsAndColumns : function(component, event, callback){
		//Setting the variables to be used by the method
		var milestones = component.get("v.milestoneRows");

		//Setting the error message (in case) to be displayed
		var errorMessage = " ";
		var errorColumnMessage_val1 = " ";
		var errorColumnMessage_val2 = " ";
		//Boolean to break off if sum not equal to 100
		var rowSumBoolean = true;
		//Boolean to show column toasts
		var columnValidationFail1 = false;
		var columnValidationFail2 = false;
		//creating 11 booleans to track column level information
		var po_available = false;
		var contract_available = false;
		var hwDelivery_available = false;
		var hwInstall_available = false;
		var swDelivery_available = false;
		var rfa_available = false;
		var uat_available = false;
		var stability_available = false;
		var fa_available = false;
		var kpi_available = false;
		var retention_available = false;
		//looping through the array to check for total
		for(var iterating_index = 0; iterating_index < milestones.length ; iterating_index++){
			//To check if the total percentage is 100
			console.log('Total percentage >> ' + milestones[iterating_index].Total_Percentage__c);
			if(milestones[iterating_index].Total_Percentage__c != 100){
				errorMessage +=  milestones[iterating_index].ProductCategory__c + ",";
				rowSumBoolean = false;
			}
			//Validation for column level information
			//PO percentage check for the row

			if(milestones[iterating_index].PO__c > 0)
				po_available = true;
			//Contract percentage check for the row
			if(milestones[iterating_index].Contract__c > 0)
				contract_available = true;
			//HW Delivery percentage check for the row
			if(milestones[iterating_index].HW_delivery__c > 0)
				hwDelivery_available = true;
			//HW_Install__c percentage check for the row
			if(milestones[iterating_index].HW_Install__c > 0)
				hwInstall_available = true;
			// percentage check for the row
			if(milestones[iterating_index].SW_delivery__c > 0)
				swDelivery_available = true;
			// percentage check for the row
			if(milestones[iterating_index].RFA__c > 0)
				rfa_available = true;
			// percentage check for the row
			if(milestones[iterating_index].UAT__c > 0)
				uat_available = true;
			// percentage check for the row
			if(milestones[iterating_index].Stability__c > 0)
				stability_available = true;
			// percentage check for the row
			if(milestones[iterating_index].FA__c > 0)
				fa_available = true;
			// percentage check for the row
			if(milestones[iterating_index].KPI__c > 0)
				kpi_available = true;
			// percentage check for the row
			if(milestones[iterating_index].Retention__c > 0)
				retention_available = true;


		}
		//Error message(s) shown as a toast for row validation
 		if(!rowSumBoolean){
			//prompt('This is an error');
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					"title": $A.get("$Label.c.notBalancedMsgPart1"),
					"message": $A.get("$Label.c.dateNoPercentageMsg")  + " " + errorMessage.substring(0,errorMessage.length-1),
					"type":"error",
					"mode":"sticky"
				});
				toastEvent.fire();
		}
		//Column validation
		/*******
			there are 2 cases
			1. If the percentage is entered -- denoted by boolean eg po_available
			   and the date is not entered  -- denoted by aura:id fetch eg - component.find("po_dateField").get("v.value")
			2. If the percentage is not entered -- all column shows 0
			   and the dates is entered
		*******/
		//use case 1 message
		if(((component.find("po_dateField").get("v.value") === undefined || component.find("po_dateField").get("v.value") == '') && po_available)){
			errorColumnMessage_val1 += "PO,";
			columnValidationFail1 = true;
		}
		if(((component.find("contract_dateField").get("v.value") === undefined || component.find("contract_dateField").get("v.value") == '')&& contract_available)){
			errorColumnMessage_val1 += "Contract,";
			columnValidationFail1 = true;
		}
		if(((component.find("hwDelivery_dateField").get("v.value") === undefined || component.find("hwDelivery_dateField").get("v.value") == '') && hwDelivery_available)){
			errorColumnMessage_val1 += "HW Delivery,";
			columnValidationFail1 = true;
		}
		if(((component.find("hwInstall_dateField").get("v.value") === undefined || component.find("hwInstall_dateField").get("v.value") == '') && hwInstall_available)){
			errorColumnMessage_val1 += "HW Install,";
			columnValidationFail1 = true;
		}
		if(((component.find("swDelivery_dateField").get("v.value") === undefined || component.find("swDelivery_dateField").get("v.value") == '') && swDelivery_available)){
			errorColumnMessage_val1 += "SW Delivery,";
			columnValidationFail1 = true;
		}
		if(((component.find("RFA_dateField").get("v.value") === undefined || component.find("RFA_dateField").get("v.value") == '') && rfa_available)){
			errorColumnMessage_val1 += "RFA,";
			columnValidationFail1 = true;
		}
		if(((component.find("UAT_dateField").get("v.value") === undefined || component.find("UAT_dateField").get("v.value") == '') && uat_available)){
			errorColumnMessage_val1 += "UAT,";
			columnValidationFail1 = true;
		}
		if(((component.find("stability_dateField").get("v.value") === undefined || component.find("stability_dateField").get("v.value") == '') && stability_available)){
			errorColumnMessage_val1 += "Stability,";
			columnValidationFail1 = true;
		}
		if(((component.find("FA_dateField").get("v.value") === undefined || component.find("FA_dateField").get("v.value") == '') && fa_available)){
			errorColumnMessage_val1 += "FA,";
			columnValidationFail1 = true;
		}
		if(((component.find("KPI_dateField").get("v.value") === undefined || component.find("KPI_dateField").get("v.value") == '') && kpi_available)){
			errorColumnMessage_val1 += "KPI,";
			columnValidationFail1 = true;
		}
		if(((component.find("Retention_dateField").get("v.value") === undefined || component.find("Retention_dateField").get("v.value") == '' ) && retention_available)){
			errorColumnMessage_val1 += "Retention,";
			columnValidationFail1 = true;
		}

		//use case 2 message
		if(component.find("po_dateField").get("v.value") != undefined && component.find("po_dateField").get("v.value") != '' && !po_available){
			errorColumnMessage_val2 += "PO,";
			columnValidationFail2 = true;
		}
		if(component.find("contract_dateField").get("v.value") != undefined && component.find("contract_dateField").get("v.value") != '' && !contract_available){
			errorColumnMessage_val2 += "Contract,";
			columnValidationFail2 = true;
		}
		if(component.find("hwDelivery_dateField").get("v.value") != undefined && component.find("hwDelivery_dateField").get("v.value") != '' && !hwDelivery_available){
			errorColumnMessage_val2 += "HW Delivery,";
			columnValidationFail2 = true;
		}
		if(component.find("hwInstall_dateField").get("v.value") != undefined && component.find("hwInstall_dateField").get("v.value") != '' && !hwInstall_available){
			errorColumnMessage_val2 += "HW Install,";
			columnValidationFail2 = true;
		}
		if(component.find("swDelivery_dateField").get("v.value")!= undefined && component.find("swDelivery_dateField").get("v.value") != '' && !swDelivery_available){
			errorColumnMessage_val2 += "SW Delivery,";
			columnValidationFail2 = true;
		}
		if(component.find("RFA_dateField").get("v.value") != undefined && component.find("RFA_dateField").get("v.value") != '' && !rfa_available){
			errorColumnMessage_val2 += "RFA,";
			columnValidationFail2 = true;
		}
		if(component.find("UAT_dateField").get("v.value") != undefined && component.find("UAT_dateField").get("v.value") != '' && !uat_available){
			errorColumnMessage_val2 += "UAT,";
			columnValidationFail2 = true;
		}
		if(component.find("stability_dateField").get("v.value") != undefined &&  component.find("stability_dateField").get("v.value") != '' && !stability_available){
			errorColumnMessage_val2 += "Stability,";
			columnValidationFail2 = true;
		}
		if(component.find("FA_dateField").get("v.value") != undefined && component.find("FA_dateField").get("v.value") != '' && !fa_available){
			errorColumnMessage_val2 += "FA,";
			columnValidationFail2 = true;
		}
		if(component.find("KPI_dateField").get("v.value") != undefined && component.find("KPI_dateField").get("v.value") != '' && !kpi_available){
			errorColumnMessage_val2 += "KPI,";
			columnValidationFail2 = true;
		}
		if(component.find("Retention_dateField").get("v.value")!= undefined && component.find("Retention_dateField").get("v.value") != '' && !retention_available){
			errorColumnMessage_val2 += "Retention,";
			columnValidationFail2 = true;
		}

		if(columnValidationFail1){
			var errorMsg  = $A.get("$Label.c.dateNotPresentButPerrcentage") + " \n " + errorColumnMessage_val1.substring(0,errorColumnMessage_val1.length-1);
			console.log(errorMsg);
			//prompt('This is an error');
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					"title": $A.get("$Label.c.dateNotPresentButPercentageHeader"),
					"message": errorMsg,
					"type":"error",
					"mode":"sticky"
				});
				toastEvent.fire();
		}

		if(columnValidationFail2){
			var errorMsg = $A.get("$Label.c.dateNoPercentageMsg") + " \n " + errorColumnMessage_val2.substring(0,errorColumnMessage_val2.length-1);
			console.log(errorMsg);
			//prompt('This is an error');
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					"title":  $A.get("$Label.c.dateNoPercentageMsgHeader"),
					"message": errorMsg,
					"type":"error",
					"mode":"sticky"
				});
				toastEvent.fire();
		}

		//Only if both validation booleans are not true
		if(!columnValidationFail1 && !columnValidationFail2 && rowSumBoolean){
			var project = component.get("v.project");
			project.PO_Date__c = component.find("po_dateField").get("v.value");
			project.Contract_Date__c = component.find("contract_dateField").get("v.value");
			project.HW_delivery_Date__c = component.find("hwDelivery_dateField").get("v.value");
			project.HW_Install_Date__c = component.find("hwInstall_dateField").get("v.value");
			project.SW_delivery_Date__c = component.find("swDelivery_dateField").get("v.value");
			project.RFA_Date__c = component.find("RFA_dateField").get("v.value");
			project.UAT_Date__c = component.find("UAT_dateField").get("v.value");
			project.Stability_Date__c = component.find("stability_dateField").get("v.value");
			project.FA_Date__c = component.find("FA_dateField").get("v.value");
			project.KPI_Date__c = component.find("KPI_dateField").get("v.value");
			project.Retention_Date__c = component.find("Retention_dateField").get("v.value");
			//Project ready for update - as a parameters
			//Milestone rows is auto updated hence that is another
			var action = component.get("c.saveMethod");
			action.setParams({
				"project" : project,
				"list_milestone" : milestones
			});
			//Handling the call back
			action.setCallback(this, function(response){
				var state = response.getState();
				console.log('state is >> ' + state);
				//console.log('response is >> ' + response);
				if(state == "SUCCESS"){
					//letting the user know that the record saved
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						"title": "Records saved",
						"message":  $A.get("$Label.c.milestonePageSuccessMsg"),
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
		}
	}
})