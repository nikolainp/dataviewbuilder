
#Region Variables

Var TableID;
Var FieldID;

#EndRegion

#Region Public

Function LoadDBStorageStructure() Export
	
	MakeLoadDBStorageStructure();
	
	
	Return ThisObject;
	
EndFunction

Function CreateSQLCode(Val Table) Export
	
	Return GetSQLCodeForTable(Table);
	
EndFunction

#EndRegion

#Region EventHandlers
// Enter code here.
#EndRegion

#Region Internal
// Enter code here.
#EndRegion

#Region Private

#Region StorageStructure

Procedure MakeLoadDBStorageStructure()
	
	Var StorageStructure, CurTable;
	Var InDBMSTerms;
	
	
	ClearAndCheckStorageStructure();
	
	InDBMSTerms = True;
	StorageStructure = GetDBStorageStructureInfo(, InDBMSTerms);
	SetUpTableAndFieldID(StorageStructure);
	For Each CurTable In StorageStructure Do
		LoadTableStorageStructure(CurTable);
	EndDo;
	
EndProcedure

Procedure ClearAndCheckStorageStructure()
	
	Var ExpectedColumns, CurExpColumn;
	Var Columns, CurColumn;
	
	
	ThisObject.MetaStructure.Rows.Clear();
	
	ExpectedColumns = New Array;
	ExpectedColumns.Add(New Structure("Name, Type", "Flag", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "FullName", New TypeDescription("String")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsTable", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsField", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "Name", New TypeDescription("String")));
	ExpectedColumns.Add(New Structure("Name, Type", "Storage", New TypeDescription("String")));
	
	Columns = ThisObject.MetaStructure.Columns;
	For Each CurExpColumn In ExpectedColumns Do
		
		CurColumn = Columns.Find(CurExpColumn.Name);
		If CurColumn = Undefined Then
			Columns.Add("Flag", CurExpColumn.Type);
		EndIf;
		
	EndDo
	
EndProcedure

Procedure SetUpTableAndFieldID(Val Storage)
	
	var Fields;
	
	
	If Storage.Count() = 0 Then 
		Return;
	EndIf;
	
	
	TableID = New Structure;
	TableID.Insert("TableName", GetColumnByName(Storage, "TableName", "ИмяТаблицы"));
	TableID.Insert("Fields", GetColumnByName(Storage, "Fields", "Поля"));
	TableID.Insert("Purpose", GetColumnByName(Storage, "Purpose", "Назначение"));
	TableID.Insert("MetaData", GetColumnByName(Storage, "MetaData", "Метаданные"));
	TableID.Insert("StorageTableName", GetColumnByName(Storage, "StorageTableName", "ИмяТаблицыХранения"));
	
	Fields = Storage[0].Get(TableID.Fields);
	FieldID = New Structure;
	FieldID.Insert("FieldName", GetColumnByName(Fields, "FieldName", "ИмяПоля"));
	FieldID.Insert("StorageFieldName", GetColumnByName(Fields, "StorageFieldName", "ИмяПоляХранения"));
	
	
EndProcedure

Function GetColumnByName(Val Collection, Val NameEn, Val NameRu)
	
	Var Columns, ID;
	
	
	Columns = Collection.Columns;
	ID = Columns.Find(NameEn);
	If ID = Undefined Then
		ID = Columns.Find(NameRu);
	EndIf;
	
	
	Return Columns.IndexOf(ID);
	
EndFunction

Procedure LoadTableStorageStructure(Val CurTable)
	
	Var TableRow, CurField, FieldRow;
	
	
	If IsBlankString(CurTable.Get(TableID.MetaData)) Then
		Return; // - System table, skip
	EndIf;
	
	TableRow = GetRowByTableName(GetTableName(CurTable));
	If IsMainTable(CurTable) Then
		TableRow = AddTableRow(TableRow.Rows, CurTable.Get(TableID.Purpose));
	Endif;
	
	TableRow.IsTable = True;
	TableRow.Storage = CurTable.Get(TableID.StorageTableName);
	For Each CurField In CurTable.Get(TableID.Fields) Do
		
		FieldRow = TableRow.Rows.Add();
		FieldRow.Name = CurField.Get(FieldID.FieldName);
		FieldRow.FullName = TableRow.FullName + "." + FieldRow.Name;
		FieldRow.Storage = CurField.Get(FieldID.StorageFieldName);
		FieldRow.IsField = True;
		
	EndDo;
	
EndProcedure

Function GetTableName(Val CurTable)
	
	Var Name;
	
	
	Name = CurTable.Get(TableID.TableName);
	If IsBlankString(Name) Then
		Name = CurTable.Get(TableID.MetaData) + "." + CurTable.Get(TableID.Purpose);
	EndIf;
	
	
	Return Name;
	
EndFunction

Function IsMainTable(Val CurTable)
	
	Var Purpose;
	
	
	Purpose = CurTable.Get(TableID.Purpose);
	
	
	Return Purpose = "Main" Or Purpose = "Основная";
	
EndFunction

Function GetRowByTableName(Val TableName)
	
	Var Names;
	
	
	//StrSplit(TableName, ".");
	Names = StrReplace(TableName, ".", Chars.LF);
	
	
	Return GetSubRowByTableName(ThisObject.MetaStructure.Rows, Names);
	
EndFunction

Function GetSubRowByTableName(Val Rows, Val Names, Val NameIndex = 1)
	
	Var SubName, SubRow;
	
	
	If StrLineCount(Names) < NameIndex Then
		Return Rows.Parent;
	EndIf;
	
	SubName = StrGetLine(Names, NameIndex);
	SubRow = Rows.Find(SubName, "Name", False);
	If SubRow = Undefined Then
		SubRow = AddTableRow(Rows, SubName);
	EndIf;
	
	Return GetSubRowByTableName(SubRow.Rows, Names, NameIndex + 1);
	
EndFunction

Function AddTableRow(Val Rows, Val SubName)
	
	Var SubRow;
	
	
	SubRow = Rows.Add();
	SubRow.Name = SubName;
	If SubRow.Parent = Undefined Then
		SubRow.FullName = SubName;
	Else
		SubRow.FullName = SubRow.Parent.FullName + "." + SubName;
	EndIf;
	
	
	Return SubRow;
	
EndFunction

#EndRegion

#Region CreateSQLCode

Function GetSQLCodeForTable(Val curTable)
	
	Var tableColumns, curColumn;
	Var viewColums, storageColumns;
	Var template;
	
	
	tableColumns = curTable.GetItems();
	viewColums = New Array;
	storageColumns = New Array;
	For Each curColumn in tableColumns do
		
		viewColums.Add(curColumn.Name);
		storageColumns.Add(curColumn.Storage);
		
	EndDo;
	
	template = "CREATE [ OR ALTER ] VIEW
	| [dbo].[%1]
	| (%2)
	|AS 
	|	SELECT
	|		%3
	|	FROM [dbo].[%4]";
	
	
	Return StrTemplate(template
		, curTable.Name
		, StrConcat(viewColums, "
		|	,")
		, StrConcat(storageColumns, "
		|		,")
		, curTable.Storage);
	
EndFunction

#EndRegion

#EndRegion
