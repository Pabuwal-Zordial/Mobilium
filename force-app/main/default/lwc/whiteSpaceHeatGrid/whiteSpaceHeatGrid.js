import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHeatMapData from '@salesforce/apex/WhiteSpaceHeatMapController.getHeatMapData';
import updateAssessmentSpend from '@salesforce/apex/WhiteSpaceHeatMapController.updateAssessmentSpend';
import createOpportunityFromAssessment from '@salesforce/apex/WhiteSpaceHeatMapController.createOpportunityFromAssessment';

export default class WhiteSpaceHeatGrid extends LightningElement {
    @api recordId; // Populated when placed on Account_Plan__c record page

    @track isLoading = true;
    @track isSaving = false;
    @track isSinglePlanMode = false;
    @track selectedFiscalYear = 'FY2027';
    @track fiscalYears = [];
    @track searchTerm = '';

    @track offerings = [];
    @track rawRows = [];
    @track kpis = {};

    // Modal State
    @track isModalOpen = false;
    @track selectedCell = {};
    @track editOurSpend = 0;
    @track editCompetitorSpend = 0;
    @track editInternalSpend = 0;
    @track editUnknownSpend = 0;
    @track editComments = '';

    // Quick Opportunity State
    @track createOppEnabled = false;
    @track oppName = '';
    @track oppAmount = 0;
    @track oppCloseDate = '';
    @track oppStage = 'Prospecting';

    stageOptions = [
        { label: 'Prospecting', value: 'Prospecting' },
        { label: 'Qualification', value: 'Qualification' },
        { label: 'Needs Analysis', value: 'Needs Analysis' },
        { label: 'Value Proposition', value: 'Value Proposition' },
        { label: 'Proposal/Price Quote', value: 'Proposal/Price Quote' },
        { label: 'Negotiation/Review', value: 'Negotiation/Review' }
    ];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            const data = await getHeatMapData({
                accountPlanId: this.recordId ? this.recordId : null,
                fiscalYear: this.selectedFiscalYear
            });

            this.isSinglePlanMode = data.isSinglePlanMode;
            this.selectedFiscalYear = data.selectedFiscalYear;
            this.fiscalYears = data.fiscalYears || [];
            this.kpis = data.kpis || {};
            this.offerings = data.offerings || [];

            this.rawRows = (data.rows || []).map(row => {
                return {
                    ...row,
                    planUrl: '/' + row.planId,
                    formattedOurRevenue: this.formatCurrency(row.ourRevenue),
                    formattedWhiteSpace: this.formatCurrency(row.totalWhiteSpace),
                    cells: (row.cells || []).map(cell => {
                        return {
                            ...cell,
                            isWon: cell.statusBadge === 'CLIENT_WON',
                            cardClass: `heat-cell-card ${cell.badgeClass}`,
                            displayBadgeText: this.getBadgeLabel(cell),
                            formattedPrimaryAmount: this.formatCurrency(cell.whiteSpaceValue > 0 ? cell.whiteSpaceValue : cell.ourSpend),
                            formattedOurSpend: this.formatCurrency(cell.ourSpend),
                            formattedCompetitorSpend: this.formatCurrency(cell.competitorSpend),
                            formattedInternalSpend: this.formatCurrency(cell.internalSpend),
                            formattedUnknownSpend: this.formatCurrency(cell.unknownSpend),
                            formattedWhiteSpace: this.formatCurrency(cell.whiteSpaceValue)
                        };
                    })
                };
            });
        } catch (error) {
            this.showToast('Error Loading Heat Grid', error?.body?.message || error?.message || 'Unknown error', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get headerTitle() {
        if (this.isSinglePlanMode && this.rawRows.length > 0) {
            return `${this.rawRows[0].accountName} - White Space Matrix`;
        }
        return 'White Space Portfolio Heat Map';
    }

    get headerSubtitle() {
        if (this.isSinglePlanMode && this.rawRows.length > 0) {
            return `Strategic Offering Penetration & Spend Analysis • ${this.rawRows[0].fiscalYear}`;
        }
        return `Multi-Dimensional Spend & Opportunity Penetration across Accounts • ${this.selectedFiscalYear}`;
    }

    get fiscalYearOptions() {
        return this.fiscalYears.map(fy => ({ label: fy, value: fy }));
    }

    get hasData() {
        return this.rawRows && this.rawRows.length > 0;
    }

    get filteredRows() {
        if (!this.searchTerm || this.searchTerm.trim() === '') {
            return this.rawRows;
        }
        const term = this.searchTerm.toLowerCase();
        return this.rawRows.filter(r =>
            (r.accountName && r.accountName.toLowerCase().includes(term)) ||
            (r.planName && r.planName.toLowerCase().includes(term))
        );
    }

    // KPI Formatters
    get kpiAccountLabel() {
        return this.isSinglePlanMode ? 'Plan Status' : 'Account Plans';
    }

    get kpiAccountCount() {
        if (this.isSinglePlanMode && this.rawRows.length > 0) {
            return this.rawRows[0].status || 'Active';
        }
        return this.kpis.totalPlans || 0;
    }

    get formattedOurRevenue() {
        return this.formatCurrency(this.kpis.totalOurRevenue || 0);
    }

    get formattedWhiteSpace() {
        return this.formatCurrency(this.kpis.totalWhiteSpace || 0);
    }

    get formattedCustomerSpend() {
        return this.formatCurrency(this.kpis.totalCustomerSpend || 0);
    }

    get formattedAvgShare() {
        return this.kpis.avgShareOfWallet || 0;
    }

    get formattedOpenPipeline() {
        return this.formatCurrency(this.kpis.totalOpenPipeline || 0);
    }

    // Handlers
    handleFiscalYearChange(event) {
        this.selectedFiscalYear = event.detail.value;
        this.loadData();
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await this.loadData();
            this.showToast('Refreshed', 'Live Heat Map data refreshed from Salesforce.', 'success');
        } catch (error) {
            this.showToast('Refresh Error', error?.body?.message || error?.message || 'Error refreshing data', 'error');
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
    }

    handleCellClick(event) {
        const planId = event.currentTarget.dataset.planId;
        const offeringId = event.currentTarget.dataset.offeringId;

        // Find cell in raw rows
        let targetCell = null;
        let parentRow = null;
        for (const row of this.rawRows) {
            if (row.planId === planId) {
                parentRow = row;
                targetCell = (row.cells || []).find(c => c.offeringId === offeringId);
                break;
            }
        }

        if (!targetCell) {
            this.showToast('Notice', 'No cell found for this offering.', 'info');
            return;
        }

        const offeringMeta = (this.offerings || []).find(o => o.id === offeringId) || {};

        this.selectedCell = {
            id: targetCell.id || null,
            planId: planId,
            offeringId: offeringId,
            offeringName: targetCell.offeringName || offeringMeta.name || 'Offering',
            offeringCode: targetCell.offeringCode || offeringMeta.code || '',
            accountName: parentRow ? parentRow.accountName : 'Account'
        };

        this.editOurSpend = targetCell.ourSpend || 0;
        this.editCompetitorSpend = targetCell.competitorSpend || 0;
        this.editInternalSpend = targetCell.internalSpend || 0;
        this.editUnknownSpend = targetCell.unknownSpend || 0;
        this.editComments = targetCell.comments || '';

        // Reset Opp fields
        this.createOppEnabled = false;
        this.oppName = `${this.selectedCell.accountName} - ${this.selectedCell.offeringName} Expansion`;
        this.oppAmount = targetCell.whiteSpaceValue > 0 ? targetCell.whiteSpaceValue : 50000;
        const defaultClose = new Date();
        defaultClose.setDate(defaultClose.getDate() + 60);
        this.oppCloseDate = defaultClose.toISOString().split('T')[0];
        this.oppStage = 'Prospecting';

        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleSpendFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        if (field === 'ourSpend') this.editOurSpend = parseFloat(value) || 0;
        if (field === 'competitorSpend') this.editCompetitorSpend = parseFloat(value) || 0;
        if (field === 'internalSpend') this.editInternalSpend = parseFloat(value) || 0;
        if (field === 'unknownSpend') this.editUnknownSpend = parseFloat(value) || 0;
        if (field === 'comments') this.editComments = value;
    }

    handleToggleOpp(event) {
        this.createOppEnabled = event.target.checked;
    }

    handleOppFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        if (field === 'oppName') this.oppName = value;
        if (field === 'oppAmount') this.oppAmount = parseFloat(value) || 0;
        if (field === 'oppCloseDate') this.oppCloseDate = value;
        if (field === 'oppStage') this.oppStage = value;
    }

    async handleSaveSpend() {
        this.isSaving = true;
        try {
            // 1. Update Assessment Spend (creates if not existing)
            const updatedCell = await updateAssessmentSpend({
                assessmentId: this.selectedCell.id ? this.selectedCell.id : null,
                planId: this.selectedCell.planId,
                offeringId: this.selectedCell.offeringId,
                ourSpend: Number(this.editOurSpend) || 0,
                competitorSpend: Number(this.editCompetitorSpend) || 0,
                internalSpend: Number(this.editInternalSpend) || 0,
                unknownSpend: Number(this.editUnknownSpend) || 0,
                comments: this.editComments || ''
            });

            // 2. Optionally create linked Opportunity
            if (this.createOppEnabled) {
                if (!this.oppName || !this.oppCloseDate || !this.oppStage) {
                    throw new Error('Please fill all required opportunity fields.');
                }

                await createOpportunityFromAssessment({
                    assessmentId: updatedCell.id,
                    oppName: this.oppName,
                    amount: Number(this.oppAmount) || 0,
                    closeDate: this.oppCloseDate,
                    stageName: this.oppStage
                });

                this.showToast('Success', 'Spend updated and Expansion Opportunity created!', 'success');
            } else {
                this.showToast('Success', 'White Space spend updated successfully.', 'success');
            }

            this.closeModal();
            // Force re-fetch fresh data from server
            await this.loadData();
        } catch (error) {
            this.showToast('Save Failed', error?.body?.message || error?.message || 'Error saving spend', 'error');
        } finally {
            this.isSaving = false;
        }
    }

    // Helper functions
    formatCurrency(val) {
        if (val === null || val === undefined || isNaN(val)) {
            return '$0';
        }
        if (Math.abs(val) >= 1000000) {
            return '$' + (val / 1000000).toFixed(1) + 'M';
        }
        if (Math.abs(val) >= 1000) {
            return '$' + (val / 1000).toFixed(0) + 'k';
        }
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
        }).format(val);
    }

    getBadgeLabel(cell) {
        switch (cell.statusBadge) {
            case 'CLIENT_WON':
                return 'Won / Client';
            case 'COMPETITOR_DOMINANT':
                return 'Competitor';
            case 'INTERNAL_DIY':
                return 'Internal DIY';
            default:
                return 'White Space';
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
