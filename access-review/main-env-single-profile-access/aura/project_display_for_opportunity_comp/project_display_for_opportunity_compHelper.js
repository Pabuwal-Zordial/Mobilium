({
	/*************************************************************************************
      Method Name             getAccounts
      Developed By            West Monroe Partners
      Purpose                 * To interact with apex to fetch the project informatiokn
						for the running opportunity Id

      Created date            2/2/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/2/2017		Refer method header
      *************************************************************************************/
	getProjects : function(component) {
		//Calling the method on the controller to retrieve all the projects for
		//the opportunity
		var recordid = component.get("v.recordId");
		//Calling the method in the apex controller to query
		var action = component.get("c.fetchProjectForOpportunityId");
		//Setting parameters for the method call
		action.setParams({
			"opportunityID" : recordid
		});
		//Handling the set back
		action.setCallback(this, function(response){
	             //component.set("v.twentyAccounts", a.getReturnValue());
			 var state = response.getState();
			 //$A.log(response);
			 if(state == "SUCCESS"){
			 	//Setting the values back to projects
				component.set("v.projects", response.getReturnValue());
				//console.log( response.getReturnValue());
			 }
		});
		$A.enqueueAction(action);
	}
})