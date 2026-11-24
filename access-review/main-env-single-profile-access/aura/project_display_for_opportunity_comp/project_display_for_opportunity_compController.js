({
    /*************************************************************************************
    Method Name             doInit
    Developed By            West Monroe Partners
    Purpose                 * To populate the project name is a picklist so that we can display
    				    the milestone information for the project
    Created date            2/1/2017
    History
    ------------------------------------------------------------------------------------
    VERSION  	AUTHOR 	DATE      		DETAIL
    1.0		SS		2/1/2017		Refer method header
    *************************************************************************************/
	doInit : function(component, event, helper) {
		helper.getProjects(component);
	}
	,
	/*************************************************************************************
	Method Name             onSelectChange
	Developed By            West Monroe Partners
	Purpose                 * To call the event to set the project Id common
					accross multiple components
	Created date            2/1/2017
	History
	------------------------------------------------------------------------------------
	VERSION  	AUTHOR 	DATE      		DETAIL
	1.0		SS		2/1/2017		Refer method header
	*************************************************************************************/
	onSelectChange : function(component, event, helper) {
      	var selected = component.find("projectSelections").get("v.value");

		//Calling the application event
		var appEvent = $A.get("e.c:projectSelectionEvent");
		appEvent.setParams({
			"projectId" : selected
		});
    		//Firing the event
		appEvent.fire();

	}

})