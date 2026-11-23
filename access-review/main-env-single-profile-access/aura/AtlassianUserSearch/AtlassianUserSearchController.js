({
	doInit : function(component, event, helper) {
		var actions = [
			{ label: 'Assign as Director', name: 'assign_director' },
			{ label: 'Assign as Manager', name: 'assign_manager' }
		]

		component.set('v.columns', [
			{ label: 'Name', fieldName: 'displayName', type: 'text' },
			{ label: 'Email', fieldName: 'emailAddress', type: 'eamil' },
			{ label: 'Username', fieldName: 'name', type: 'text' },
			{ type: 'action', typeAttributes: { rowActions: actions } }
		]);

		var isUpdate = component.get('v.isUpdate');
		if (isUpdate) {
			component.set('v.searchQuestion', 'Do you want to update Project Director and/or Project Manager of this Project?')
		}
	},
	handleRowAction : function(component, event, helper) {
		var action = event.getParam('action');
		var row = event.getParam('row');

		switch (action.name) {
			case 'assign_director':
				component.set('v.projectDirectorUsername', row.name);
				component.set('v.projectDirectorName', row.displayName);
				component.set('v.projectDirectorEmail', row.emailAddress);
				break;
			case 'assign_manager':
				component.set('v.projectManagerUsername', row.name);
				component.set('v.projectManagerName', row.displayName);
				component.set('v.projectManagerEmail', row.emailAddress);
				break;
		}
	},
	handleSearch : function(component, event, helper) {
		var inputSearchCmp = component.find('searchInput');
		if (event.keyCode == 13 && inputSearchCmp.reportValidity())
		{
			component.set("v.processing", true);
			helper.serverSearch(component, inputSearchCmp.get('v.value'));
		}
	},
	getSelectedUsers : function(component, event, helper) {
		var pdUsername = component.get('v.projectDirectorUsername');
		var pdName = component.get('v.projectDirectorName');
		var pdEmail = component.get('v.projectDirectorEmail');
		var pmUsername = component.get('v.projectManagerUsername');
		var pmName = component.get('v.projectManagerName');
		var pmEmail = component.get('v.projectManagerEmail');
		var answer = component.get('v.answer');

		if ((pdUsername && pmUsername) || answer == 'no') {
			return {
				projectDirectorUsername: pdUsername,
				projectDirectorName: pdName,
				projectDirectorEmail: pdEmail,
				projectManagerUsername: pmUsername,
				projectManagerName: pmName,
				projectManagerEmail: pmEmail
			};
		}
		else {
			return false;
		}
	}
})