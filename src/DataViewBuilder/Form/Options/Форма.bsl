
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(Object, Parameters.Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
// Enter code here.
#EndRegion

#Region FormTableItemsEventHandlers
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveOptions(Command)
	
	ThisForm.Close(Object);
	
EndProcedure

#EndRegion

#Region Private
#EndRegion
