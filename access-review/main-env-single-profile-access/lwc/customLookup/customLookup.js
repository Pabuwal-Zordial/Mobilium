import { LightningElement, api } from 'lwc';
import apexSearch from '@salesforce/apex/CustomLookupController.search';

export default class CustomLookup extends LightningElement
{
	@api value;
	@api originalValue;
	@api labelValue;
	@api parentId;
	@api targetObjectType;
	@api targetField;
	@api targetLabelField;
	@api editMode;
	@api ignoreChangedLayout = false;

	// Private variables
	_originalLabel;
	_originalValue;

	get componentClass()
	{
		if (this.ignoreChangedLayout) {
			return;
		}
		return this.value !== this.originalValue ? 'edited' : '';
	}

	@api
	resetComponent()
	{
		this._originalValue = undefined;
		this._originalLabel = undefined;
	}

	toggleEditMode()
	{
		this.editMode = !this.editMode;
	}

	clearValue()
	{
		const newValue = '';

		if (this._originalValue === undefined)
		{
			this._originalValue = this.value;
			this._originalLabel = this.labelValue;
		}
		this.valueChanged(newValue, newValue);
	}

	handleSearch(event)
	{
		const { target } = event;
		apexSearch({ searchTerm: event.detail.searchTerm, objectType: this.targetObjectType })
			.then(results => {
				target.setSearchResults(results);
			})
			.catch(error => {
				console.log('handleSearch Error: ', error);
			});
	}

	handleSelectionChange(event) {
		const selection = event.target.getSelection();

		if (this._originalValue === undefined)
		{
			this._originalValue = this.value;
			this._originalLabel = this.labelValue;
		}
		this.valueChanged(selection[0].id, selection[0].title);
	}

	valueChanged(newValue, newLabel)
	{
		this.dispatchEvent(new CustomEvent('customlookupvaluechanged', {
			composed: true,
			bubbles: true,
			cancelable: true,
			detail: {
				data: {
					parentId: this.parentId,
					targetField: this.targetField,
					targetLabelField: this.targetLabelField,
					value: newValue,
					valueLabel: newLabel,
					originalValue: this._originalValue
				}
			}
		}));

		this.value = newValue;
		this.toggleEditMode();
	}
}