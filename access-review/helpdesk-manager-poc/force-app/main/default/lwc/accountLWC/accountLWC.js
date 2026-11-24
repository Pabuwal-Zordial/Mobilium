import { LightningElement, api } from 'lwc';

export default class LdsRecordForm extends LightningElement {

    @api strTitle;
    arrayFields = ['Name', 'Phone', 'Website'];
}