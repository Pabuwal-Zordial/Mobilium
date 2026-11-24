// dragAndDropListView.js
import { LightningElement, track } from 'lwc';

export default class DragAndDropListView extends LightningElement {
    @track items = [
        { id: 1, name: 'Item 1' },
        { id: 2, name: 'Item 2' },
        { id: 3, name: 'Item 3' }
    ];

    handleDragStart(event) {
        const itemId = event.target.dataset.itemId;
        event.dataTransfer.setData('itemId', itemId);
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();
        const itemId = event.dataTransfer.getData('itemId');
        const newIndex = this.findDropIndex(event);
        this.reorderItems(itemId, newIndex);
    }

    findDropIndex(event) {
        const listItems = Array.from(this.template.querySelectorAll('li'));
        let newIndex = -1;
        listItems.forEach((item, index) => {
            const rect = item.getBoundingClientRect();
            if (event.clientY > rect.top && event.clientY < rect.bottom) {
                newIndex = index;
            }
        });
        return newIndex;
    }

    reorderItems(itemId, newIndex) {
        const itemToMove = this.items.find(item => item.id === parseInt(itemId));
        const currentIndex = this.items.indexOf(itemToMove);
        if (currentIndex !== newIndex) {
            this.items = this.arrayMove(this.items, currentIndex, newIndex);
        }
    }

    arrayMove(array, fromIndex, toIndex) {
        const newArray = array.slice();
        const element = newArray[fromIndex];
        newArray.splice(fromIndex, 1);
        newArray.splice(toIndex, 0, element);
        return newArray;
    }
}