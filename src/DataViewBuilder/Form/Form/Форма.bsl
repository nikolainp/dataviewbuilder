
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
	
	Var parentTable, curRow;
	
	
	parentTable = Item.Parent;
	curRow = parentTable.CurrentData;
	
	SetFlagOnUpTree(curRow, curRow.Flag);
	SetFlagOnSubTree(curRow, curRow.Flag);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure LoadDBStorageStructure(Command)
	
	LoadDBStorageStructureAtServer();
	
	Items.FormCreateAll.Enabled = True;
	
EndProcedure

&AtClient
Procedure CreateAll(Command)
	
	CreateAllAtServer();
	
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
Procedure SetFlagOnUpTree(Val childRow, Val childFlag)
	
	Var parentRow;
	
	
	If childFlag = False Then
		Return;
	EndIf;
	
	parentRow = childRow.GetParent();
	If parentRow = Undefined Then
		Return;
	EndIf;
	
	parentRow.Flag = childFlag;
	SetFlagOnUpTree(parentRow, childFlag);
	
EndProcedure

&AtClient
Procedure SetFlagOnSubTree(Val parentTree, Val parentFlag)
	
	Var curRow;
	
	
	For Each curRow In parentTree.GetItems() Do
		
		If Object.DataView_SkipChanges
			and curRow.IsChangesTable Then
			Continue;
		EndIf;
		
		curRow.Flag = parentFlag;
		SetFlagOnSubTree(curRow, parentFlag);
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
Procedure LoadDBStorageStructureAtServer()
	
	ToForm(Object().LoadDBStorageStructure());
	//GetDBStorageStructureInfo
	
EndProcedure

&AtServer
Procedure CreateAllAtServer()
	
	IterateOverTables(Object(), Object.MetaStructure.GetItems());
	
EndProcedure

&AtServer
Procedure IterateOverTables(Module, Val Tables)
	
	Var curTable;
	
	
	For Each curTable In Tables Do
		
		If curTable.Flag = False Then
			Continue;
		EndIf;
		
		If curTable.isTable Then
			
			Module.CreateDataView(curTable)
			
		Else
			
			IterateOverTables(Module, curTable.GetItems());
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function CreateSQLCode(Val CurrentRow)
	
	Var CurItem;
	
	
	CurItem = Object.MetaStructure.FindByID(CurrentRow);
	
	
	Return Object().CreateSQLCode(CurItem);
	
EndFunction

#EndRegion
