({
	/*************************************************************************************
      Method Name             doInit
      Developed By            West Monroe Partners
      Purpose                 * To populate the following
						* pushing the default values into other placeholders

      Created date            2/2/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/2/2017		Refer method header
      *************************************************************************************/
  	doInit : function(component, event, helper) {
  	},
      /*************************************************************************************
      Method Name             handleProjectSelection
      Developed By            West Monroe Partners
      Purpose                 * To populate the following
						* milestone header
                                    * display dates fields for the project (milestone date fields)
      Created date            2/2/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/2/2017		Refer method header
      *************************************************************************************/
      handleProjectSelection : function(component, event, helper) {
            document.getElementById("loadingSpinner").style.display = "block";
            //Getting the selected project ID from the event attribute
            var newProjectId = event.getParam("projectId");
            //Checking if the project id is of length 18 - Salesforce Id
            //If the value is chosen as None, nothing will happen
            if(newProjectId.length == 18){
                  //Querying the date from the projects
                  helper.getProject(component, newProjectId);
                  //Getting the headers in place
                  helper.getMilestoneHeaders(component);
                  //Getting the headers in place
                  helper.getMilestoneRows(component, newProjectId);

            }else{
                  //console.log('In else');
                  component.set("v.milestoneHeaders","");
                  document.getElementById("loadingSpinner").style.display = "none";
                  //console.log(component.find("v.milestoneHeaders"));
            }
            //Getting the spinner info to toggle
            //$A.util.toggleClass(spinner, "slds-hide");

      },
      /*************************************************************************************
      Method Name             validateAndSave
      Developed By            West Monroe Partners
      Purpose                 * To handle the following
                                    * row wise data validation
                                    * column wise data validation
                                    * then save the
                                          * project
                                          * milestones
      Created date            2/4/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/4/2017		Refer method header
      *************************************************************************************/
      validateAndSave : function(component, event, helper) {
            helper.validateRowsAndColumns(component, event );
      }
})