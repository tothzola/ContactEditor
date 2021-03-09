# Contact Editor

## Acknowledgments

This project is largely an exercise for me aimed at both learning and making a template for the Model-View-Presenter (MVP) pattern backed by persistent storage in VBA. A special thanks goes to Mathieu Guindon, a co-founder of the [Rubber Duck VBA project](https://rubberduckvba.com) and his [RDVBA blog](https://rubberduckvba.wordpress.com). Initially, I closely followed the [post][RDVBA No Worksheet] describing a possible approach, as well as a template provided in the comments, eventually making an extended template.

## Background

This projects targets the User <---> Database interaction workflow as a sample application. Basically, the user sends a query to the database, receives a response table, uses a form to browse/edit record data, and, possibly, updates the database, as shown in the figure below. This project only covers the left part of the diagram (no actual database interaction).

![Overview][Overview]

## Design

### Data Model

At the basis of the project model are two data data model classes, DataRecordModel and DataTableModel representing a single Record (table row) shown to the user on the UserForm and a Table respectively. Model classes know nothing about data storage, which is the responsibility of the backend classes. Presently, each of the two base model classes has one backend, DataRecordWSheet and DataTableWSheet each, in turn, implementing a corresponding storage interface, IDataRecordStorage and IDataTableStorage and generated by their respective abstract factories: DataRecordFactory\IDataRecordFactory and  DataTableFactory\IDataTableFactory. Finally, DataRecordManager\IDataRecordManager and DataTableManager\IDataTableManager incorporate by composition one model and one backend class, yielding a "backend-managed" model.

![Base classes][Base classes]

For present purposes, data needs to be transferred between DataRecordModel and DataTableModel; hence, the need for additional functionality, which should not go in the base classes. Thus, DataCompositeManager class is added. It can be implemented either via a composition of "backend-managed" classes, or via a composition of two model and two backend classes directly. The latter pathway has been chosen for  DataCompositeManager class, and it exposes the necessary features of the constituent classes and implements the "inter-model" functionality. Finally, the viewModel class ContactEditorModel incorporates DataCompositeManager.

![Composite classes][Composite classes]

### Implementation details 

DataRecordModel also includes IsDirty flag, indicating whether there are changes not saved to its backend (not to the Table backend). RecordIndex field is at present not used and possibly can be removed. It is set when the DataRecordModel is populated from the DataTableModel and points to record index in the Values array of the DataTableModel.

The main data field in the DataTableModel is Values Variant, which is populated with a record-wise 2D array (the faster changing index is the field index).  The first column is assumed to be the id field named "id" (though most of the time only the name is assumed or its position).

Since id can be of any type, it can not be used directly to index records in the Values array. The IdIndices field is a dictionary, with the key being the id field cast as a String and the value is the corresponding 1-based index of the record in the backend table / Values array.  IdIndices is used as a map between id and its index.

FieldNames - 1D 1-based Variant array containing the names of the fields in the order they appear in the table from left to right. It is used for transferring the data to/from the DataRecordModel, which stores the values in a Dictionary object.

DirtyRecords - dictionary, mapping a CStr(id) and its index for records that have been modified in the model. This way, only modified records can be send back to the backend if requested.

### Table updating

Changes made to the form are immediately saved into the DataRecordModel, which in turn is saved to its backend if Apply or Ok buttons are pressed. Nothing else is saved if table updating is disabled. Otherwise, every time the  DataRecordModel is saved to its backend, it also updates the corresponding record in the DataTableModel. When option "On apply" is selected, DataTableModel is saved to its backend after each update. When option "On exit" is selected, DataTableModel is saved with all changes at once only when Ok button is pressed, closing the form.

### Worksheet backend and naming convention

It is assumed that the form displays all of the fields from the table. Further, the names of the corresponding controls are set to match exactly the names of the fields in the table. And they also match the keys in the data dictionary of the DataRecordModel. With this convention, data can be transferred between the form and the DataRecordModel and between DataRecordModel and DataTableModel efficiently without ever hardcoding any field names.

In the current implementation, the "Contacts" worksheet stores the table filled with fake generated data and is used by the DataTableWSheet. The name of the worksheet is not hardcoded either. It is supplied in the form of ConnectionString parameter to the factory, which for the worksheet backend is expected to be in the form of workbook filename with extension" (as returned by Thisworkbook.name) followed by the exclamation mark, and followed by the worksheet name. The present implementation, however, makes no attempts to handle, for example, unopened workbooks. The only confirmed test runs were with the target worksheet being in the same file as the VBA code. In fact, the name of the worksheet is not actually used, as the backend expects that the table name must also be supplied, which is in this case is a globally scoped named  range. It is expected that the first row of this range contains the field names, and the first column is the id column. It expects two more named ranges with names formed as concatenation of the given table name and "Body" for the data range (without the header) and "Id" suffix for the id column data (without the header). While the "Body" range can be straightforwardly calculated from the table range, the lack of necessary support in Excel/VBA makes such calculations not very intuitive and complicates the code. With this convention, the backend collects the field names for the first row of the table, avoiding the need for hardcoding specific names. For example, presenter initializes DataTableWSheet via the corresponding interface with table name "Contacts", which is a (dynamic) named range, "ContactsId" range refers to the "id" column, and "ContactsBody" range refers to the data area without the header. "ContactsHeader" range is also defined and refers to the header row only. (N.B.: because these ranges are defined using a formula, these names are not shown in the range name / address bar (top left corner)).

"ContactBrowser" worksheet is used by the worksheet backend DataRecordWSheet. Saved "ContactBrowser"  data is also used to populate the form at the start. The convention here is as follows. Again, only named ranges are used, no Excel addresses. Each each field from the Record/Table has a corresponding cell, and the name of that cell is set to match the name of the field. This convention means that in principle, once DataTableWSheet pulled the table including the field names from the header, this information is sufficient to pull the data by the DataRecordWSheet from the corresponding worksheet. Nevertheless, DataRecordWSheet collects the field names independently (well, this is an exploratory project after all). All named ranges are accessible via the Workbook object. DataRecordWSheet goes through the collection members and filters out all the names the match all of the following:
- Name.RefersTo  starts with the name of the worksheet supplied to the DataRecordWSheet constructor;
- target range is a single cell range;
- the value of an adjacent cell either above or to the left of the target cell contains a text that also matches the field name.

For example, the cell ContactBrowser!E5 is a single cell named range "LastName", which matches the value of the cell ContactBrowser!D5, name of the field in the table on the "Contacts" worksheet, and the name of the TextBox control on the UserForm.

## Additional considerations

The entry point of the demo is RunContactEditor in the ContactEditorRunner module.

The UserForm - view/viewModel - ContactEditorForm is displayed as *modeless*, so custom UserForm events to pass control to the appropriate routines in the presenter (ContactEditorPresenter). For this reason, a WithEvents view reference is defined as a module level field in the presenter, and a module level reference to the presenter is defined in the entry point module. Presenter also defines a second view reference as IDialogView interface, containing the main entry point for the view.

Since UserForm events cannot be programmatically enabled/disabled (at least straightforwardly) at run time, SuppressEvents Boolean flag is added to the ContactEditorModel to cancel event processing when the form fields are programmatically updated.

## Limitations and outlook

Presently, this project contains no validation of data read from Excel Worksheets.  

The CSV backend is at least at present very slow. The bottleneck is appears to be the loop that parses/encodes data, which is not necessary in case of the "Worksheet" backend, where data table can be transferred between an Excel.Range object and a 2D variant array directly. CSV code is adapted from the [CSVParser repo][CSV Parser repo]. There is a start up performance problem with the CSV backend (when compared to the Worksheet backend), but its nature is not clear at present and would require further investigation.  

It also is planned to incorporate the [SecureADODB][SecureADODB] package and implement a backend that pulls data from an actual database (my [fork][SecureADODB fork] of this package with some modifications also incorporates test examples with ADODB mediated quires against CSV and SQLite mock databases).


[RDVBA No Worksheet]: https://rubberduckvba.wordpress.com/2017/12/08/there-is-no-worksheet
[Overview]: https://github.com/pchemguy/ContactEditor/blob/develop/Assets/Diagrams/Overview.jpg
[Composite classes]: https://github.com/pchemguy/ContactEditor/blob/develop/Assets/Diagrams/Class%20Diagram.svg
[Base classes]: https://github.com/pchemguy/ContactEditor/blob/develop/Assets/Diagrams/Class%20Diagram%20-%20Table%20and%20Record.svg
[SecureADODB]: https://github.com/rubberduck-vba/examples/tree/master/SecureADODB
[SecureADODB fork]: [https://github.com/pchemguy/RDVBA-examples]
[CSV Parser repo]: https://github.com/pchemguy/CSVParser
