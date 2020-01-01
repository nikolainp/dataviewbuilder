
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(Object, Parameters.Source);
	SetupFormRequisites();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DestinationDBOnChange(Item)
	SetupSourceDB();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveOptions(Command)
	
	ThisForm.Close(Object);
	
EndProcedure

&AtClient
Procedure CheckDestinationDB(Command)
	CheckDestinationDBAtServer();
EndProcedure

#EndRegion

#Region Private

///////////////
// At Server

&AtServer
Function Object()
	
	Return FormAttributeToValue("Object");
	
EndFunction

&AtServer
Procedure SetupFormRequisites()
	
	SetupSourceDB();
	
EndProcedure

&AtServer
Procedure SetupSourceDB()
	
	Var Module;
	Var IBConnection, StrIndex;
	
	
	Module = Object();
	If IsBlankString(Object.SourceDB) Then
		
		IBConnection = InfoBaseConnectionString();
		If Module.lStrStartsWith(IBConnection, "Srvr=") Then
			
			StrIndex = Module.lStrFind(IBConnection, ";Ref=");
			If StrIndex = 0 Then
				Return;
			EndIf;
			
			Object.SourceDB = Right(IBConnection, StrIndex + 5);
			Object.SourceDB = StrReplace(Object.SourceDB, """", "");
			Object.SourceDB = StrReplace(Object.SourceDB, ";", "");
			
		EndIf;
		
	EndIf;
	
	Items.SourceDB.ChoiceList.LoadValues(Module.GetListDB());
	
EndProcedure

&AtServer
Procedure CheckDestinationDBAtServer()
	
	Object().CheckDestinationDB();
	
EndProcedure

#EndRegion
