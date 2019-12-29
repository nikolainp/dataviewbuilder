
#Region FormEventHandlers
// Enter code here.
#EndRegion

#Region FormHeaderItemsEventHandlers
// Enter code here.
#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ViewSQLCode(Command)
	
	CreateSQLCode(Items.MetaStructure.CurrentRow)
	
EndProcedure

&AtClient
Procedure MetaStructureOnActivateRow(Item)
	
	Var CurrentData;
	
	
	CurrentData = Item.CurrentData;
	If not CurrentData = Undefined Then
		Items.MetaStructureContextMenuViewSQLCode.Visible = CurrentData.IsTable;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure LoadDBStorageStructure(Command)
	
	LoadDBStorageStructureOnServer();
	
EndProcedure

&AtClient
Procedure Options(Command)
	
	Var Params, NotifyOfClose;
	
	
	Params = New Structure;
	Params.Insert("Source", Object);
	
	NotifyOfClose = New NotifyDescription("OptionsAtClose"
		, ThisForm);
	
	OpenForm("ExternalDataProcessor.DataViewBuilder.Form.Options"
		, Params
		, ThisForm
		, ThisForm.UniqueKey
		, 
		, 
		, NotifyOfClose
		, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure
&AtClient
Procedure OptionsAtClose(Result, Params) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(Object, Result);
	
EndProcedure

#EndRegion

#Region Private


///////////////
// On Server

&AtServer
Function Object()
	
	Return FormAttributeToValue("Object");
	
EndFunction

&AtServer
Procedure ToForm(Data)
	
	ValueToFormAttribute(Data, "Object");
	
EndProcedure

&AtServer
Procedure LoadDBStorageStructureOnServer()
	
	ToForm(Object().LoadDBStorageStructure());
	//GetDBStorageStructureInfo
	
EndProcedure

&AtServer
Function CreateSQLCode(Val CurrentRow)
	
	Return Object().CreateSQLCode(CurrentRow)
	
EndFunction

#EndRegion
