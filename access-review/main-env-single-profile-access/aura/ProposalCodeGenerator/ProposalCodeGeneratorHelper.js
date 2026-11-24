({
	loadAppData : function(component)
	{
		var action = component.get("c.initData");

		action.setParams(
			{ opportunityId : component.get("v.recordId") }
		);

		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS")
			{
				var serverResponse = response.getReturnValue();
				if (serverResponse.isSuccess)
				{
					component.set("v.isMasterCode", serverResponse.value.isMasterCode);
					component.set("v.opportunityType", serverResponse.value.opportunityType );
				}
				else
				{
					this.showToast("Error", "error", "Failed to load initial data.");
				}
			}
			else
			{
				this.showToast("Error", "error", "Failed to load initial data.");
			}

			component.set("v.loading", false);
		});

		$A.enqueueAction(action);
	},
	serverGenerateMasterCode : function(component)
	{
		var action = component.get("c.generateMasterCode");

		action.setParams(
			{ opportunityId : component.get("v.recordId") }
		);

		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS")
			{
				var serverResponse = response.getReturnValue();
				if (serverResponse.isSuccess)
				{
					this.showToast("Success", "success", serverResponse.message);
					$A.get("e.force:closeQuickAction").fire();
					$A.get('e.force:refreshView').fire();
				}
				else
				{
					this.showToast("Error", "error", serverResponse.message);
					component.set("v.submited", false);
				}
			}
			else
			{
				this.showToast("Error", "error", "Unable to generate a proposal code.");
				component.set("v.submited", false);
			}

			component.set("v.loading", false);
		});

		$A.enqueueAction(action);
	},
	serverGenerateExtensionCode : function(component)
	{
		var action = component.get("c.generateExtensionCode");

		action.setParams(
			{ opportunityId : component.get("v.recordId"), opportunityType : component.get("v.opportunityType") }
		);

		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS")
			{
				var serverResponse = response.getReturnValue();
				if (serverResponse.isSuccess)
				{
					this.showToast("Success", "success", serverResponse.message);
					$A.get("e.force:closeQuickAction").fire();
					$A.get('e.force:refreshView').fire();
				}
				else
				{
					this.showToast("Error", "error", serverResponse.message);
					component.set("v.submited", false);
				}
			}
			else
			{
				this.showToast("Error", "error", "Unable to generate a proposal code.");
				component.set("v.submited", false);
			}

			component.set("v.loading", false);
		});

		$A.enqueueAction(action);
	},
	showToast : function(title, type, message)
	{
		var toastEvent = $A.get("e.force:showToast");

		toastEvent.setParams({
			"title" : title,
			"message" : message,
			"type" : type,
			"duration" : "dismissible"
		});

		toastEvent.fire();
	}
})