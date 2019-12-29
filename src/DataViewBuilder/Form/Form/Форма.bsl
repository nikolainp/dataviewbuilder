
#Region FormEventHandlers
// Enter code here.
#EndRegion

#Region FormHeaderItemsEventHandlers
// Enter code here.
#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ViewSQLCode(Command)
	
	var sqlCode;
	
	
	sqlCode = CreateSQLCode(Items.MetaStructure.CurrentRow);
	ShowValue(,sqlCode);
	
EndProcedure

&AtClient
Procedure MetaStructureOnActivateRow(Item)
	
	Var CurrentData;
	
	
	CurrentData = Item.CurrentData;
	If not CurrentData = Undefined Then
		Items.MetaStructureContextMenuViewSQLCode.Visible = CurrentData.IsTable;
	EndIf;
	
EndProcedure

&AtClient
Procedure MetaStructureFlagOnChange(Item)
	
	Var parentTable, parentFlag;
	Var curRow;
	
	
	parentTable = Item.Parent;
	curRow = parentTable.CurrentData;
	parentFlag = curRow.Flag;
	SetFlagOnTree(curRow, parentFlag);
	
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
// At Client

&AtClient
Procedure SetFlagOnTree(Val parentTree, Val parentFlag)
	
	Var curRow;
	
	
	For Each curRow In parentTree.GetItems() Do
		curRow.Flag = parentFlag;
		SetFlagOnTree(curRow, parentFlag);
	EndDo;
	
EndProcedure

///////////////
// At Server

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
	
	Var CurItem;
	
	
	CurItem = Object.MetaStructure.FindByID(CurrentRow);
	
	
	Return Object().CreateSQLCode(CurItem);
	
EndFunction

#EndRegion
