
#Region Variables

Var TableID;
Var FieldID;

Var ADOConnection;

#EndRegion

#Region Public

Procedure CheckDestinationDB() Export
	
	OpenDB();
	
EndProcedure

Function GetListDB() Export
	
	Var Records, List;
	
	
	Records = ReadData(
		"SELECT
		|	name
		|FROM
		|	sys.databases");
	
	List = New Array;
	If Records = Undefined Then
		Return List;
	EndIf;
	While Records.EOF() = 0 Do
		
		List.Add(Records.Fields(0).Value);
		Records.MoveNext();
		
	EndDo;
	
	
	Return List;
	
EndFunction

Function LoadDBStorageStructure() Export
	
	MakeLoadDBStorageStructure();
	
	
	Return ThisObject;
	
EndFunction

Function CreateSQLCode(Val Table) Export
	
	Return lStrConcat(GetSQLCodeForTable(Table)
		, "
		|GO
		|
		|");
	
EndFunction

Function CreateDataView(Val Table) Export
	
	Var curQuery;
	
	
	For Each curQuery in GetSQLCodeForTable(Table) Do
		WriteData(curQuery);
	EndDo;
	
EndFunction

#EndRegion

#Region EventHandlers
// Enter code here.
#EndRegion

#Region Internal

#Region StringFunction

Function lStrConcat(Val Strings, Val Separator) Export
	
	Var strBuffer, strIndex;
	
	
	If Strings.Count() = 0 Then
		Return "";
	EndIf;
	
	strBuffer = Strings[0];
	For strIndex = 1 To Strings.UBound() Do
		strBuffer = strBuffer + Separator + Strings[strIndex];
	EndDo;
	
	
	Return strBuffer;
	
EndFunction

Function lStrFind(Val String, Val SearchString) Export
	
	Return Find(String, SearchString);
	
EndFunction

Function lStrTemplate(Val Template
	, Val Val1 = ""
	, Val Val2 = ""
	, Val Val3 = ""
	, Val Val4 = ""
	, Val Val5 = ""
	, Val Val6 = ""
	, Val Val7 = ""
	, Val Val8 = ""
	, Val Val9 = "") Export
	
	Var I;
	Var lTemplate;
	
	
	lTemplate = Template;
	lTemplate = StrReplace(lTemplate, "%1", Val1);
	lTemplate = StrReplace(lTemplate, "%2", Val2);
	lTemplate = StrReplace(lTemplate, "%3", Val3);
	lTemplate = StrReplace(lTemplate, "%4", Val4);
	lTemplate = StrReplace(lTemplate, "%5", Val5);
	lTemplate = StrReplace(lTemplate, "%6", Val6);
	lTemplate = StrReplace(lTemplate, "%7", Val7);
	lTemplate = StrReplace(lTemplate, "%8", Val8);
	lTemplate = StrReplace(lTemplate, "%9", Val9);
	
	
	Return lTemplate;
	
EndFunction

Function lStrStartsWith(Val String, Val SearchString) Export
	
	If StrLen(String) < StrLen(SearchString) Then
		Return False;
	EndIf;
	
	If Left(String, StrLen(SearchString)) = SearchString Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function lStrEndsWith(Val String, Val SearchString) Export
	
	If StrLen(String) < StrLen(SearchString) Then
		Return False;
	EndIf;
	
	If Right(String, StrLen(SearchString)) = SearchString Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion 

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
	SortStorageStructure();
	
EndProcedure


Procedure ClearAndCheckStorageStructure()
	
	Var ExpectedColumns, CurExpColumn;
	Var Columns, CurColumn;
	
	
	ThisObject.MetaStructure.Rows.Clear();
	
	ExpectedColumns = New Array;
	ExpectedColumns.Add(New Structure("Name, Type", "Flag", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "FullName", New TypeDescription("String")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsObject", New TypeDescription("Boolean")));
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
		TableRow.IsObject = True;
		TableRow = AddTableRow(TableRow.Rows, CurTable.Get(TableID.Purpose));
	Endif;
	
	TableRow.IsTable = True;
	TableRow.Storage = CurTable.Get(TableID.StorageTableName);
	For Each CurField In CurTable.Get(TableID.Fields) Do
		
		FieldRow = TableRow.Rows.Add();
		FieldRow.Name = GetColumnName(CurField.Get(FieldID.FieldName), CurField.Get(FieldID.StorageFieldName));
		FieldRow.FullName = TableRow.FullName + "." + FieldRow.Name;
		FieldRow.Storage = CurField.Get(FieldID.StorageFieldName);
		FieldRow.IsField = True;
		
	EndDo;
	
EndProcedure

Procedure SortStorageStructure()
	
	SortLevelStorageStructure(ThisObject.MetaStructure.Rows);
	
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

Function GetColumnName(Name, Storage)
	
	Var curNamem, curSufName;
	
	
	If IsBlankString(Name) Then
		
		If Storage = "_KeyField" Then
			curName = NStr("en = 'UniqueKeyField'; ru = 'УникальнйИдентификаторСтроки'");
			
		ElsIf Storage = "_NumberPrefix" Then
			curName = NStr("en = 'NumberPrefix'; ru = 'ПрефиксНомера'");
			
		ElsIf Storage = "_SimpleKey" Then
			curName = NStr("en = 'SimpleKey'; ru = 'КороткийКлючЗаписи'");
			
		EndIf;
		
	Else
		curName = Name;
		
	EndIf;
	
	curSufName = "";
	If lStrEndsWith(Storage, "_TYPE") Then
		curSufName = NStr("en = '_Type'; ru = '_Тип'");
		
	ElsIf lStrEndsWith(Storage, "_RTRef") Then
		curSufName = NStr("en = '_ReferenceType'; ru = '_ТипСсылки'");
		
	ElsIf lStrEndsWith(Storage, "_L") Then
		curSufName = NStr("en = '_Boolean'; ru = '_Булево'");
		
	ElsIf lStrEndsWith(Storage, "_N") Then
		curSufName = NStr("en = '_Numeric'; ru = '_Число'");
		
	ElsIf lStrEndsWith(Storage, "_T") Then
		curSufName = NStr("en = '_DateTime'; ru = '_ДатаВремя'");
		
	ElsIf lStrEndsWith(Storage, "_S") Then
		curSufName = NStr("en = '_String'; ru = '_Строка'");
		
	ElsIf lStrEndsWith(Storage, "_B") Then
		curSufName = NStr("en = '_Binary'; ru = '_ДвоичныеДанные'");
		
	ElsIf lStrEndsWith(Storage, "_RRRef") Then
		
	EndIf;
	
	
	Return lStrTemplate("%1%2", curName, curSufName);
	
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


Procedure SortLevelStorageStructure(Rows)
	
	Var CurRow;
	
	
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	
	If Rows[0].IsObject Then
		Rows.Sort("Name", False);
	EndIf;
	
	For Each CurRow In Rows Do
		SortLevelStorageStructure(CurRow.Rows);
	EndDo;
	
EndProcedure

#EndRegion

#Region CreateSQLCode

Function GetSQLCodeForTable(Val curTable)
	
	Var tableName, tableColumns, curColumn;
	Var viewColums, storageColumns;
	Var queries;
	
	
	tableName = StrReplace(curTable.FullName, ".", "_");
	If ThisObject.DataView_AddDBName Then
		tableName = lStrTemplate("%1_%2", ThisObject.SourceDB, tableName);
	EndIf;
	
	tableColumns = curTable.GetItems();
	viewColums = New Array;
	storageColumns = New Array;
	For Each curColumn in tableColumns do
		
		viewColums.Add(curColumn.Name);
		storageColumns.Add(curColumn.Storage);
		
	EndDo;
	
	queries = New Array;
	queries.Add(
		lStrTemplate(
			"IF OBJECT_ID('[dbo].[%1]', 'V') IS NOT NULL
			|	DROP VIEW [dbo].[%1]"
			, tableName));
			
	queries.Add(
		lStrTemplate(
			"CREATE VIEW [dbo].[%1]
			|	(%2)
			|AS
			|	SELECT
			|		%3
			|	FROM [%4].[dbo].[%5]"
			, tableName
			, lStrConcat(viewColums, "
			|	, ")
			, lStrConcat(storageColumns, "
			|		, ")
			, ThisObject.SourceDB
			, curTable.Storage));
	
	
	Return queries;
	
EndFunction

#EndRegion

#Region SQLWork

Procedure OpenDB()
	
	If not ADOConnection = Undefined Then
		Return;
	EndIf;
	
	ADOConnection = New COMObject("ADODB.Connection");
	ADOConnection.ConnectionString = ThisObject.DestinationDB;
	ADOConnection.ConnectionTimeOut = 1200;
	ADOConnection.CursorLocation = 3;
	
	Try
		
		ADOConnection.Open();
		
	Except
		
		Message = New UserMessage;
		Message.Text = NStr("en = 'Connection failed'; ru = 'Невозможно установить соединение'")
			+ ErrorDescription();
		Message.Field = "DestinationDB";
		Message.DataPath = "Object";
		Message.Message();
		
		ADOConnection = Undefined;
		
		Return;
		
	EndTry;
	
EndProcedure // OpenDB

Procedure CloseDB()
	
	If ADOConnection = Undefined Then
		Return;
	EndIf;
	
	ADOConnection.Close();
	ADOConnection = Undefined;
	
EndProcedure // CloseDB

Procedure WriteData(Val QueryText, Val Data = Undefined)
	
	Var ADOCommand;
	Var I;
	
	
	OpenDB();
	If ADOConnection = Undefined Then
		Return;
	EndIf;
	
	ADOCommand = New ComObject("ADODB.Command");
	ADOCommand.ActiveConnection = ADOConnection;
	ADOCommand.CommandType = 1;
	ADOCommand.CommandText = QueryText;
	
	If TypeOf(Data) = Type("Array") Then
		
		For I = 0 To Data.UBound() Do
			ADOCommand.Parameters(I).Value = Data.Get(I);
		EndDo;
		
	EndIf;
	
	ADOCommand.Execute();
	
EndProcedure // WriteData

Function ReadData(Val QueryText, Val Data = Undefined)
	
	Var ADOCommand;
	Var ADOQuery;
	Var I;
	
	
	OpenDB();
	If ADOConnection = Undefined Then
		Return Undefined;
	EndIf;
	
	ADOCommand = New COMОбъект("ADODB.Command");
	ADOQuery = New ComObject("ADODB.RecordSet");
	
	ADOCommand.ActiveConnection = ADOConnection; 
	ADOCommand.CommandType = 1;
	ADOCommand.CommandText = QueryText;
	ADOCommand.CommandTimeout = 1200;
	ADOCommand.Prepared = True;
	
	If TypeOf(Data) = Type("Array") Then
		
		For I = 0 To Data.UBound() Do
			ADOCommand.Parameters(I).Value = Data.Get(I);
		EndDo;
		
	EndIf;
	
	ADOQuery = ADOCommand.Execute();
	If ADOQuery.BOF = False
		And ADOQuery.EOF = False Then
		ADOQuery.MoveFirst();
	EndIf;
	
	
	Return ADOQuery;
	
EndFunction // ReadData

//Функция		ПолучитьНомерНового (ТипЗначения)
//	
//	Перем	АДОКоманда;
//	Перем	Номер;
//	
//	
//	АДОКоманда = Новый ComObject("ADODB.Command");
//	АДОКоманда.ActiveConnection = ADOConnection;
//	АДОКоманда.CommandType = 4;
//	АДОКоманда.CommandText = "sp_InsertNewDoc";
//	
//	// 133 = adDBDate, 200 = adVarChar, 2 = adInteger
//	// 1 = adParamInput, 2 = adParamOutput
//	АДОКоманда.Parameters.Append (АДОКоманда.CreateParameter ("@_Type",			200, 1, 150,	ТипЗначения	));
//	АДОКоманда.Parameters.Append (АДОКоманда.CreateParameter ("@_Ref",			200, 1, 36,		""			));
//	АДОКоманда.Parameters.Append (АДОКоманда.CreateParameter ("@LastNumber",	2,	 2						));
//	АДОКоманда.Prepared			= 1;
//	
//	АДОКоманда.Execute();
//	
//	
//	Номер	= АДОКоманда.Parameters.Item("@LastNumber").Value;
//	
//	
//	Возврат		Номер;
//	
//КонецФункции

Function DateToSQL(Val DateTime, Val IsTime = False)
	
	Var Year, Month, Day;
	Var Hour, Minute, Second;
	
	
	DateTime = ?(DateTime = Date(1,1,1), Date(1754,1,1), DateTime);
	
	Year = Year(DateTime);
	Year = Year + 2000;
	Year = XMLString(Year);
	
	Month = Month(DateTime);
	Month = Format(Month, "ND=2; NLZ=");
	
	Day = Day(DateTime);
	Day = Format(Day, "ND=2; NLZ=");
	
	If IsTime = True Then
		
		Hour = Format(Hour(DateTime), "ND=2; NZ=00; NLZ=");
		Minute = Format(Minute(DateTime), "ND=2; NZ=00; NLZ=");
		Second = Format(Second(DateTime), "ND=2; NZ=00; NLZ=");;
		
		Return lStrTemplate("%1-%2-%3 %4:%5:%6", Year, Month, Day, Hour, Minute, Second);
		
	Else
		
		Return lStrTemplate("%1-%2-%3", Year, Month, Day);
		
	EndIf;
	
EndFunction

Function DateFromSQL(Val DateTime)
	
	If DateTime = NULL Then
		Return Date(1, 1, 1);
	EndIf;
	
	DateTime = Date(DateTime);
	
	
	Return ?(DateTime = Date(1754,1,1), Date(1,1,1), DateTime);
	
EndFunction

#EndRegion

#EndRegion
