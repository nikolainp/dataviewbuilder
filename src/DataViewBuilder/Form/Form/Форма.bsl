﻿
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
	
	If curRow = Undefined Then
		Return;
	EndIf;
	
	If curRow.Flag = 2 Then
		curRow.Flag = 0;
	EndIf;
	
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
	
	ClearMessages();
	CreateAllAtServer();
	
	ShowQueryBox(New NotifyDescription("CreateAllContunie", ThisForm)
		, NStr("en = 'Creation completed'; ru = 'Создание завершено'")
		, QuestionDialogMode.OK
		, 10);
	
EndProcedure
&AtClient
Procedure CreateAllContunie(Result, AdditionalParameters) Export
	
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

/////////////////////////////////////////////
// At Client

&AtClient
Procedure SetFlagOnUpTree(Val childRow, Val childFlag)
	
	Var parentRow;
	
	// 0 - False, 1 - True
	parentRow = childRow.GetParent();
	If parentRow = Undefined Then
		Return;
	EndIf;
	
	parentRow.Flag = GetFlagOnLevel(parentRow);
	SetFlagOnUpTree(parentRow, childFlag);
	
EndProcedure

&AtClient
Procedure SetFlagOnSubTree(Val parentTree, Val parentFlag)
	
	Var curRow;
	
	
	For Each curRow In parentTree.GetItems() Do
		
		If SkipFlagOnLevel(curRow) Then
			Continue;
		EndIf;
		
		curRow.Flag = parentFlag;
		SetFlagOnSubTree(curRow, parentFlag);
		
	EndDo;
	
EndProcedure

&AtClient
Function GetFlagOnLevel(Val level)
	
	Var curRow, flagOnLevel;
	
	
	For Each curRow In level.GetItems() Do
		
		If SkipFlagOnLevel(curRow) Then
			Continue;
		EndIf;
		
		If flagOnLevel = Undefined Then
			flagOnLevel = curRow.Flag;
		EndIf;
		
		If Not flagOnLevel = curRow.Flag Then 
			Return 2;
		EndIf;
		
	EndDo;
	
	
	Return flagOnLevel;
	
EndFunction

&AtClient
Function SkipFlagOnLevel(Val curRow)
	
	Return (Object.DataView_SkipChanges And curRow.IsChangesTable)
		Or (Object.DataView_SkipPredefined And curRow.IsPredefinedTable);
	
EndFunction

/////////////////////////////////////////////
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
			
			Module.CreateDataView(curTable);
			
			Message(Module.lStrTemplate(
				NStr("en = 'Created: %1'; ru = 'Создано: %1'")
				, Module.DataViewName(curTable)));
			
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
