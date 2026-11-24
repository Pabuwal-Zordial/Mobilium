({
	doInit : function(component, event, helper) {
		helper.loadAppData(component);
	},
	save : function(component, event, helper) {
		helper.showToast("Info", "info", "This process may take few minutes please do not close this window.");
		helper.lockScreen(component);
		try {
			helper.handleSubmit(component, event);
		} catch(e) {
			console.log("error while processing save: " + e.message);
			helper.showToast("error", "Unable to save please contact your System Administrator.", "Error", "dismissible");
			helper.unlockScreen(component);
		}
	},
	cancel : function(component, event, helper) {
		var wizardStep = component.get("v.wizardStep");
		if (wizardStep == "pageDetails") {
			component.set("v.backLabel", "Cancel");
			component.set("v.wizardStep", "searchUsers");
		}
		else {
			$A.get("e.force:closeQuickAction").fire();
		}
	},
	next : function(component, event, helper) {
		var searchCmp = component.find("usersSearch");
		var result = searchCmp.getSelectedUsers();
		if (result) {
			component.set("v.selectedUsers", result);
			component.set("v.backLabel", "Back");
			component.set("v.wizardStep", "pageDetails");
			var context = component.get("v.integrationContext");
			component.find("projectNameInput").set("v.value", context.projectName);
			component.find("projectClassificationInput").set("v.value", context.projectRecord.Project_Classifications__c);
			component.find("projectStatusInput").set("v.value", context.projectRecord.Project_Status__c);
		}
		else {
			helper.showToast("error", "Please assing users to director and manager role.", "Error", "dismissible");
		}
	}
})