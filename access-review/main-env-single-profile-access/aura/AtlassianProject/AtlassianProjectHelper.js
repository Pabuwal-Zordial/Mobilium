({
	loadAppData : function(component) {
		let action = component.get("c.initData");

		action.setParams({ recordId : component.get("v.recordId") });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess && result.insufficientRights) {
					this.showToast("error", "Insufficient rights to publish proposal code.", "Error", "dismissible");
					this.unlockScreen(component, true);
					$A.get("e.force:closeQuickAction").fire();
				}
				else if (result.isSuccess) {
					this.mapInitialValues(component, result.value);
					this.unlockScreen(component, false);
				}
				else {
					this.showToast("error", "Unable to load initial data.", "Error", "dismissible");
					this.unlockScreen(component, true);
					$A.get("e.force:closeQuickAction").fire();
				}
			}
			else {
				this.showToast("error", "Unable to load initial data.", "Error", "dismissible");
				this.unlockScreen(component, true);
				$A.get("e.force:closeQuickAction").fire();
			}
		});

		$A.enqueueAction(action);
	},
	mapInitialValues : function(component, context) {
		component.set("v.integrationContext", context);
		component.set("v.initialDataLoaded", true);

		let data = { eid : context.eid, accountName : context.accountName, acronym : context.acronym };
		component.set("v.data", data);
	},
	handleSubmit : function(component, event) {
		let integrationContext = component.get("v.integrationContext");
		let fields = event.getParam("fields");
		let selectedUsers = component.get("v.selectedUsers");
		let newRecord = this.mapFieldsToRecord(integrationContext, fields, selectedUsers);

		let action = component.get("c.submit");
		action.setParams({ project : newRecord, context : integrationContext });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					component.set("v.integrationContext", result.value);
					this.getStep(component, 0);
				}
				else {
					this.showToast("error", "Unable to submit request.\n" + result.message + ' - ' + result.value, "Error", "dismissible");
					this.unlockScreen(component, false);
				}
			}
			else {
				this.showToast("error", "Unable to submit request.", "Error", "dismissible");
				this.unlockScreen(component, false);
			}
		});

		$A.enqueueAction(action);
	},
	serverUpsertRecord : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.upsertProjectRecord");
		action.setParams({ project : context.projectRecord });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					context.projectRecord = result.value;
					this.showToast("info", "Project record upserted...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to upsert project record.\n" + result.message + ' - ' + result.value, "Error", "dismissible");
					this.unlockScreen(component, false);
				}
			}
			else {
				this.showToast("error", "Unable to upsert project record.", "Error", "dismissible");
				this.unlockScreen(component, false);
			}
		});

		$A.enqueueAction(action);
	},
	serverCreateCustomerSpace : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.createCustomerSpace");
		action.setParams({ project : context.projectRecord });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					if (result.message.includes("Space already exists.")) {
						nextStep++;
					}
					else {
						this.showToast("info", "Customer space created...", "Info", "dismissible");
					}
					context.projectRecord = result.value.record;
					component.set("v.customerSpace", result.value.space);
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to create customer space.\n" + result.message + ' - ' + result.value, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to create customer space.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverCreateCustomerSpacePages : function(component) {
		let context = component.get("v.integrationContext");
		let customerSpace = component.get("v.customerSpace");

		let action = component.get("c.createCustomerSpacePages");
		action.setParams({ project : context.projectRecord, space : customerSpace });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Customer pages created...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to create customer pages.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to create customer pages.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverCreateCustomerEidPage : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.createCustomerEidSpacePage");
		action.setParams({ project : context.projectRecord });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess)
				{
					this.showToast("info", "Customer Eid page created...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to create customer eid page.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to create customer eid page.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverAddCustomerSpacePagesPermissions : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.addCustomerSpacePagesPermissions");
		action.setParams({ project : context.projectRecord, applyPermissionsAllSpace : false });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Permissions added to customer space pages...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to add customer space pages permissions.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to add customer space pages permissions.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverCreateEidSpace : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.createEidSpace");
		action.setParams({ project : context.projectRecord });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					context.projectRecord = result.value.record;
					component.set("v.eidSpace", result.value.space);
					this.showToast("info", "Eid space created...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to create eid space.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to create eid space.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverCreateEidSpacePages : function(component) {
		let context = component.get("v.integrationContext");
		let eidSpace = component.get("v.eidSpace");

		let action = component.get("c.createEidSpacePages");
		action.setParams({ project : context.projectRecord, space : eidSpace });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Eid pages created...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to create eid pages.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to create eid pages.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverAddEidSpacePagesPermissions : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.addEidSpacePagesPermissions");
		action.setParams({ project : context.projectRecord, applyPermissionsAllSpace : true });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Permissions added to eid space pages...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to add eid space page permissions.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to add eid space page permissions.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverCreateJiraProject : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.createJiraProject");
		action.setParams({ project : context.projectRecord });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Jira project created...", "Info", "dismissible");
					component.set("v.project", result.value.project);
					component.set("v.projectTemplate", result.value.template);
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to create jira project.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to create jira project.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverUpdateJiraProject : function(component) {
		let context = component.get("v.integrationContext");
		let project = component.get("v.project");
		let template = component.get("v.projectTemplate");

		let action = component.get("c.updateJiraProject");
		action.setParams({ project : context.projectRecord, jiraProject : project, templateProject : template });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("success", "Spaces and Project created . Operation completed.", "Success.", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to updating jira project.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to updating jira project.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverUpdateCustomerEidPage : function(component) {
		let context = component.get("v.integrationContext");

		let action = component.get("c.updateCustomerEidPage");
		action.setParams({ project : context.projectRecord });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Customer eid page updated...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to update customer eid page.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to update customer eid page.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverUpdateCustomerSpacePagesPermissions : function(component) {
		let integrationContext = component.get("v.integrationContext");

		let action = component.get("c.updateCustomerSpacePagesPermissions");
		action.setParams({ context : integrationContext });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Customer eid page permissions updated...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to update customer eid page permissions.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to update customer eid page permissions.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverUpdateEidSpacePermissions : function(component) {
		let integrationContext = component.get("v.integrationContext");

		let action = component.get("c.updateEidSpacePermissions");
		action.setParams({ context : integrationContext });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Eid space permissions updated...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to update eid space permissions.\n" + result.message, "Error", "dismissible");
					this.unlockScreen(component, true);
				}
			}
			else {
				this.showToast("error", "Unable to update eid space permissions.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverUpdatePublishedJiraProject : function(component) {
		let integrationContext = component.get("v.integrationContext");

		let action = component.get("c.updatePublishedJiraProject");
		action.setParams({ context : integrationContext });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state == "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					this.showToast("info", "Jira project permissions updated...", "Info", "dismissible");
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to update jira project permissions.\n" + result.message, "Error", "dismissible");
				}
				this.unlockScreen(component, true);
			}
			else {
				this.showToast("error", "Unable to update jira project permissions.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverNotifyNew : function(component) {
		let integrationContext = component.get("v.integrationContext");

		let action = component.get("c.notifyUsers");
		action.setParams({ context : integrationContext, isNew : true });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state == "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to notify users.\n" + result.message, "Error", "dismissible");
				}
				this.unlockScreen(component, true);
			}
			else {
				this.showToast("error", "Unable to notify users.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	serverNotifyUpdate : function(component) {
		let integrationContext = component.get("v.integrationContext");

		let action = component.get("c.notifyUsers");
		action.setParams({ context : integrationContext, isNew : false });
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state == "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					let nextStep = parseInt(component.get("v.currentStep")) + 1;
					component.set("v.currentStep", nextStep);
					this.getStep(component, nextStep);
				}
				else {
					this.showToast("error", "Unable to notify users.\n" + result.message, "Error", "dismissible");
				}
				this.unlockScreen(component, true);
			}
			else {
				this.showToast("error", "Unable to notify users.", "Error", "dismissible");
				this.unlockScreen(component, true);
			}
		});

		$A.enqueueAction(action);
	},
	getStep : function(component, currentStep) {
		let context = component.get("v.integrationContext");
		if (currentStep < context.steps.length && context.steps.length > 0) {
			console.log(currentStep);
			console.log(context.steps[currentStep]);
			this[context.steps[currentStep]](component);
		}
		else {
			this.showToast("success", "Operation completed.", "Success.", "dismissible");
			this.unlockScreen(component, true);
		}
	},
	mapFieldsToRecord : function(context, fields, selectedUsers) {
		let newRecord = {
			Id : context.projectRecord.Id,
			Proposal_Code__c : context.projectRecord.Proposal_Code__c,
			Project_Classifications__c : fields["Project_Classifications__c"],
			Project_Name__c : fields["Project_Name__c"],
			Project_Status__c : fields["Project_Status__c"],
			Project_Director_Name__c : selectedUsers.projectDirectorName,
			Project_Director_Username__c : selectedUsers.projectDirectorUsername,
			Project_Director_Email__c : selectedUsers.projectDirectorEmail,
			Project_Manager_Name__c : selectedUsers.projectManagerName,
			Project_Manager_Username__c : selectedUsers.projectManagerUsername,
			Project_Manager_Email__c : selectedUsers.projectManagerEmail
		};

		return newRecord;
	},
	showToast : function(type, message, title, mode) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			type : type,
			message : message,
			title : title,
			mode : mode
		});
		toastEvent.fire();
	},
	lockScreen : function(component) {
		component.set("v.processing", true);
	},
	unlockScreen : function(component, closeModal) {
		component.set("v.processing", false);
		if (closeModal)
		{
			$A.get("e.force:closeQuickAction").fire();
		}
	}
})