
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	AttachActionsAfterOpening();
	
EndProcedure

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
Procedure LoadDBStorageStructure(Command = Undefined)
	
	LoadDBStorageStructureAtServer();
	
	Items.FormCreateAll.Enabled = True;
	
EndProcedure

&AtClient
Procedure DropAll(Command)
	
	ShowQueryBox(New NotifyDescription("DropAllContunie", ThisForm)
		, NStr("en = 'All views will be drop. Continue?';
			| ru = 'Все представления данных будут удалены. Продолжит?'")
		, QuestionDialogMode.OKCancel
		, 10
		, DialogReturnCode.Cancel
		, NStr("en = 'Attention'; ru = 'Внимание'")
		, DialogReturnCode.Cancel);
	
EndProcedure
&AtClient
Procedure DropAllContunie(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.OK Then
		Return;
	EndIf;
	
	
	DropAllAtServer();
	
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
Procedure AttachActionsAfterOpening()
	
	AttachIdleHandler("AttachActionsAfterOpeningContinue", 0.1, True);
	
EndProcedure
&AtClient
Procedure AttachActionsAfterOpeningContinue() Export
	
	AskForLoadDBStorageStructure();
	
EndProcedure

&AtClient
Procedure AskForLoadDBStorageStructure()
	
	Var Notification;
	
	
	Notification = New NotifyDescription("AskForLoadDBStorageStructureContinue", ThisForm);
	ShowQueryBox(Notification
		, NStr("en = 'Before you begin, you need to get the database storage structure."
			+ " This operation may take a long time."
			+ " During this the interface will not respond to your actions."
			+ " Start execution?';"
			+ " ru = 'Перед началом работы необходимо получить структуру хранения базы данных."
			+ " Эта операция может занять продолжительно время."
			+ " При этом интерфейс не будет отвечать на ваши действия"
			+ " Начать выполнение?'")
		, QuestionDialogMode.YesNo
		, 30
		, DialogReturnCode.Yes
		, NStr("en = 'Attention'; ru = 'Внимание'")
		, DialogReturnCode.Yes);
	
EndProcedure
&AtClient
Procedure AskForLoadDBStorageStructureContinue(Val QuestionResult, Val AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes
		And Not QuestionResult = DialogReturnCode.Timeout Then
		Return;
	EndIf;
	
	
	LoadDBStorageStructure();
	
EndProcedure

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
Procedure DropAllAtServer()
	
	Object().DropAllDataView();
	
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
