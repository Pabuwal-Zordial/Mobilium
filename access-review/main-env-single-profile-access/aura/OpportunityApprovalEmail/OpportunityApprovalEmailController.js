({
    handleSend: function (component, event, helper) {
        helper.sendApprovalEmail(component);
    },

    handleCancel: function (component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    }
})