({
	doInit : function(component, event, helper)
	{
		helper.loadAppData(component);
	},
	generate : function(component, event, helper)
	{
		var submitted = component.get("v.submitted");
		if (submitted)
		{
			return;
		}

		if (!component.get("v.opportunityType "))
		{
			return;
		}

		component.set("v.loading", true);
		component.set("v.submitted", true);

		var isMasterCode = component.get("v.isMasterCode");
		if (isMasterCode)
		{
			helper.serverGenerateMasterCode(component);
		}
		else
		{
			helper.serverGenerateExtensionCode(component);
		}
	},
	cancel : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})