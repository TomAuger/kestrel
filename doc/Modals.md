Modals
======

Modals in AppBase are implemented with the following structure:

-   App-specific modals extend ModalView

-   ModalFactory dishes out the correct ModalView

-   AppBase holds a single Modal at a time and is used to set the current Modal
    for the app.



Which API should I use?
-----------------------

If you are just interested in displaying Modals and responding to their
interactions, use the methods available within AppBase.

If you are changing the look / skin / visual construction of Modals to meet your
App requirements, extend ModalView, or one of its child views, such as
iOSModalView.

If you are creating a new set of Modals and wish to control which modal is
actually used based on the number of buttons requested, extend ModalFactory.



AppBase Methods
---------------

Your App can only have one active Modal at a time. When a Modal is active, the
screen (and all its assets) are deactivated (automatically) via their
`deactivate()` methods. When the Modal is dismissed, the screen and assets are
activated via their `activate()` methods.

When a Modal is active, the App's `isModal` property is `true`. Use this on
ScreenViews to ensure that you are not processing any interactive events while a
Modal has focus.




Throwing a Modal
----------------

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public function setModal(modalText:String, ... modalArgs):void
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Gets a Modal from the ModalFactory according to the `modalArgs` you specify
    (see below). Sets this Modal as the current dialog, clearing the previous
    dialog, if there was one already up.

    The only required argument is `modalText`, which is a String of the text you
    wish the Modal to say. By default, Modals have a single button, labelled
    "OK", which dismissed the Modal when clicked.

    

Listening for Modal Events
--------------------------

There are two ways to listen for and respond to Modal events:

1.  Register an event listener against the App, listening for
    `EVENT_MODAL_DIALOG_CLOSED`. When responding to this event, query
    `app.selectedModalButton` to get the ID of the button that was clicked. This
    is a String, usually "ok", "cancel", "button_3", "button_4" etc.

2.  Provide a callback function in the `modalArgs` when defining the buttons as
    you request the Modal from the app.



The first method is probably the most familiar-feeling, though the second
approach is more direct and avoids having to query the ID of the clicked button
(unless you provide the same callback for two different buttons!).

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Method 1: Listen for app-wide event (this, from within a ScreenView)
app.setModal("OK", "Cancel");
app.addEventListener(AppBase.EVENT_MODAL_DIALOG_CLOSED, onModalClosed);

// ...
private function onModalClosed(event:Event):void {
        app.removeEventListener(AppBase.EVENT_MODAL_DIALOG_CLOSED,
            onModalClosed);

    switch (app.selectedModalButton){
        case ModalView.BUTTON_OK :
            // Handle OK pressed
            break;
        case ModalView.BUTTON_CANCEL :
            // Handle Cancel pressed
            break;
    }
}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Method 2: Use callbacks (again, within a ScreenView)
app.setModal(onOKButtonPressed, onCancelButtonPressed);

// ...
private function onOKButtonPressed():void {
    // Handle OK pressed
}

private function onCancelButtonPressed():void {
    // Handle Cancel pressed
}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



Constructing the Modal Arguments
--------------------------------

If you inspect the constructor of `ModalView`, you will see that it accepts an
arguments called `buttons` which is a Vector of `ModalButtonData` elements. The
`ModalButtonData` value object has the following properties:

-   `id` - String (required): this is the "value" of the button and is returned
    when the button is clicked.

-   `label` - String: the actual text that is displayed on the button. This must
    be pre-localized.

-   `callback` - Function: an (optional) function that will be called as soon as
    the button is clicked.

-   `clip` - MovieClip: the on-screen interactive element that represents this
    button.



The `ModalFactory` takes care of assembling correct `ModalButtonData` items
while implementing a lot of clever business logic to help you write as little
code as possible for 90% of your use cases. There are three ways you can define
your Modal's list of buttons depending on how 'default' your button behaviour
needs to be. Further, these three methods can be completely mixed
interchangeably within your ModalFactory/AppBase `setModal()` call.



### Free Arguments

Simply provide a list of labels and callbacks and let the Factory do the rest.
Probably best explained with some examples:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Create a default Modal with one "OK" button:
app.setModal();

// Create a Modal with "Go" instead of "OK":
app.setModal("Go");

// Create a Modal with "OK" and "Cancel" buttons:
app.setModal(2); // Not yet implemented

// Create a Modal with "Yes" and "No" buttons:
app.setModal("Yes", "No");

// Create a Modal where clicking "OK" will call a custom callback:
app.setModal(onOKClickedCallback);

// Same thing, adding a "Cancel" button:
app.setModal("OK", onOKClickedCallback, "Cancel");

// Same thing:
app.setModal("OK", "Cancel", onOKClickedCallback);

// Same thing, but add a different callback for Cancel:
app.setModal(onOKClickedCallback, onCancelClickedCallback);

// Create a Modal with "Go" and "Cancel" buttons:
app.setModal("Go", onGoClickedCallback, onCancelClickedCallback);
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



As you can see, you can define your callbacks and labels in any order, as long
as they are aligned. In the last example, we provide more callbacks than labels,
so the default label is used. The first defined label is always aligned with
"OK" and the second with "Cancel". After that, button labels default to "Button
3", "Button 4", "Button 5" etc with their IDs being, respectively "button_3",
"button_4", "button_5".



If a label is provided, the id is a sanitized version of the label text. If no
label is provided, the default label / ID is used.



### Object Notation

For more control, and possibly greater clarity within your code, you may choose
Object notation, providing 1 Object per button, again aligning to the default
order of "OK" and "Cancel":

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Explicitly define a custom "OK" button
app.setModal({
    id: ModalView.BUTTON_OK,
    label: "Go!!!!",
    callback: onGoButtonClicked
});

// Add a default Cancel button...
app.setModal({
    id: ModalView.BUTTON_OK,
    label: "Go!!!!",
    callback: onGoButtonClicked
},
{
    id: ModalView.BUTTON_CANCEL
});


// Add a third button
app.setModal({
    id: ModalView.BUTTON_OK,
    label: "Go!!!!",
    callback: onGoButtonClicked
},
{
    id: ModalView.BUTTON_CANCEL
},
{
    id: "my_custom_button",
    label: "Maybe...",
    callback: onMaybeButtonClicked
});
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



### ModelButtonData

The most formal way of declaring your button behaviour is using the
`ModalButtonData` value object. This is certainly more verbose, but has the
added benefit of type checking, which might benefit debugging complex code.
However, there is much less "intelligence" around defaults, especially labels.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Define 3 buttons using ModalButtonData
app.setModal(
    new ModalButtonData(ModalView.BUTTON_OK, "Go!!!", onGoButtonClicked),
    new ModalButtonData(ModalView.BUTTON_CANCEL, "Cancel"),
    new ModalButtonData("my_custom_button", "Maybe...", onMaybeButtonClicked)
);
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
