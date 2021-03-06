﻿
#Region Variables

Var TableID;
Var FieldID;

Var TablePurposes;
Var ColumnNames;

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

Function DropAllDataView() Export
	
	Var curQuery;
	
	
	For Each curQuery in GetSQLCodeForDropAllDataViews() Do
		
		WriteData(curQuery);
		
	EndDo;
	
EndFunction

Function DataViewName(Val Table) Export
	
	Return GetSQLNameForTable(Table);
	
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

Function lStrFindFromEnd(Val String, Val SearchString) Export
	
	Var lString, StringCount, LastString;
	Var LastPosition;
	
	
	lString = StrReplace(String, SearchString, Chars.LF);
	StringCount = StrLineCount(lString);
	If StringCount = 1 Then 
		Return 0;
	EndIf;
	
	LastString = StrGetLine(lString, StringCount);
	LastPosition = StrLen(LastString) + StrLen(SearchString);
	
	
	Return LastPosition;
	
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

Function lToArray(Array = Undefined
	, Val Val1 = Undefined
	, Val Val2 = Undefined
	, Val Val3 = Undefined
	, Val Val4 = Undefined
	, Val Val5 = Undefined
	, Val Val6 = Undefined
	, Val Val7 = Undefined
	, Val Val8 = Undefined
	, Val Val9 = Undefined) Export
	
	
	If Not TypeOf(Array) = Type("Array") Then
		Array = New Array;
	EndIf;
	
	If Not Val1 = Undefined Then Array.Add(Val1) EndIf;
	If Not Val2 = Undefined Then Array.Add(Val2) EndIf;
	If Not Val3 = Undefined Then Array.Add(Val3) EndIf;
	If Not Val4 = Undefined Then Array.Add(Val4) EndIf;
	If Not Val5 = Undefined Then Array.Add(Val5) EndIf;
	If Not Val6 = Undefined Then Array.Add(Val6) EndIf;
	If Not Val7 = Undefined Then Array.Add(Val7) EndIf;
	If Not Val8 = Undefined Then Array.Add(Val8) EndIf;
	If Not Val9 = Undefined Then Array.Add(Val9) EndIf;
	
	
	Return Array;
	
EndFunction

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
	ExpectedColumns.Add(New Structure("Name, Type", "Flag", TypeNumeric(1, 0, False)));
	ExpectedColumns.Add(New Structure("Name, Type", "FullName", New TypeDescription("String")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsObject", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsTable", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsChangesTable", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsPredefinedTable", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "IsField", New TypeDescription("Boolean")));
	ExpectedColumns.Add(New Structure("Name, Type", "Name", New TypeDescription("String")));
	ExpectedColumns.Add(New Structure("Name, Type", "Storage", New TypeDescription("String")));
	
	Columns = ThisObject.MetaStructure.Columns;
	For Each CurExpColumn In ExpectedColumns Do
		
		CurColumn = Columns.Find(CurExpColumn.Name);
		If CurColumn = Undefined Then
			Columns.Add(CurExpColumn.Name, CurExpColumn.Type);
		EndIf;
		
	EndDo;
	
	
	SetupTablePurposes();
	SetupColumnNames();
	
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
	
	Var TableRow, TablePurpose;
	Var CurField, FieldRow;
	
	
	If IsBlankString(CurTable.Get(TableID.MetaData)) Then
		Return; // - System table, skip
	EndIf;
	
	TableRow = GetRowByTableName(GetTableName(CurTable));
	TablePurpose = GetTablePurpose(CurTable);
	If TablePurpose.IsObjectTable Then
		TableRow = AddTableRow(TableRow.Rows, CurTable.Get(TableID.Purpose));
	Endif;
	
	FillPropertyValues(TableRow, TablePurpose);
	
	If TablePurpose.IsMainTable Then
		TableRow.Parent.IsObject = True;
	EndIf;
	
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

Procedure SetupColumnNames()
	
	If Not ColumnNames = Undefined Then 
		Return;
	EndIf;
	
	ColumnNames = New Structure;
	ColumnNames.Insert("_ActivationCondition", NStr("en = 'ActivationCondition'; ru = 'Расписание'"));
	ColumnNames.Insert("_ConstID", NStr("en = 'ConstantID'; ru = 'ИДКонстанты'"));
	ColumnNames.Insert("_Description", NStr("en = 'Description'; ru = 'Описание'"));
	ColumnNames.Insert("_FinishTime", NStr("en = 'FinishTime'; ru = 'ВремяПоследнегоЗавершения'"));
	ColumnNames.Insert("_ID", NStr("en = 'JobID'; ru = 'ИДЗадания'"));
	ColumnNames.Insert("_JobKey", NStr("en = 'JobKey'; ru = 'КлючЗадания'"));
	ColumnNames.Insert("_KeyField", NStr("en = 'UniqueKeyField'; ru = 'УникальныйИдентификаторСтроки'"));
	ColumnNames.Insert("_MessageNo", NStr("en = 'MessageNumber'; ru = 'НомерСообщения'"));
	ColumnNames.Insert("_MetadataID", NStr("en = 'MetadataID'; ru = 'ИДМетаданных'"));
	ColumnNames.Insert("_NodeRRef", NStr("en = 'Node'; ru = 'Узел'"));
	ColumnNames.Insert("_NodeTRef", NStr("en = 'Node'; ru = 'Узел'"));
	ColumnNames.Insert("_NumberPrefix", NStr("en = 'NumberPrefix'; ru = 'ПрефиксНомера'"));
	ColumnNames.Insert("_Parameters", NStr("en = 'Parameters'; ru = 'Параметры'"));
	ColumnNames.Insert("_Predefined", NStr("en = 'Predifined'; ru = 'Предопределенное'"));
	ColumnNames.Insert("_PredefinedID", NStr("en = 'PredifinedRef'; ru = 'ПредопределеннаяСсылка'"));
	ColumnNames.Insert("_RecordKey", NStr("en = 'RecordKey'; ru = 'КлючЗаписи'"));
	ColumnNames.Insert("_RestartAttemptNumber", NStr("en = 'RestartAttemptNumber'; ru = 'ТекущаяПопыткаПерезапуска'"));
	ColumnNames.Insert("_RestartCount", NStr("en = 'RestartCount'; ru = 'КоличествоПопытокПерезапуска'"));
	ColumnNames.Insert("_RestartPeriod", NStr("en = 'RestartPeriod'; ru = 'ЗадержкаПерезапуска'"));
	ColumnNames.Insert("_SimpleKey", NStr("en = 'SimpleKey'; ru = 'КороткийКлючЗаписи'"));
	ColumnNames.Insert("_StartTime", NStr("en = 'StartTime'; ru = 'ВремяПоследнегоЗапуск'"));
	ColumnNames.Insert("_State", NStr("en = 'State'; ru = 'ВыполняетсяСейчас'"));
	ColumnNames.Insert("_Use", NStr("en = 'Use'; ru = 'Включено'"));
	ColumnNames.Insert("_UserName", NStr("en = 'UserName'; ru = 'ИмяПользователя'"));
	ColumnNames.Insert("_Version", NStr("en = 'Version'; ru = 'Версия'"));
	
EndProcedure

Function GetColumnName(Name, Storage)
	
	Var curName, curSufName;
	
	
	If IsBlankString(Name) Then
		
		If Not ColumnNames.Property(Storage, curName) Then
			curName = Storage;
		EndIf;
		
	Else
		curName = Name;
		
	EndIf;
	
	curSufName = "";
	If lStrEndsWith(Storage, "_TYPE") Then
		curSufName = NStr("en = '_Type'; ru = '_Тип'");
		
	ElsIf lStrEndsWith(Storage, "_RTRef")
		or lStrEndsWith(Storage, "TRef") Then
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


Procedure SetupTablePurposes()
	
	If Not TablePurposes = Undefined Then
		Return;
	EndIf;
	
	TablePurposes = New Structure;
	TablePurposes.Insert(NStr("en = 'ChangeRecords'; ru = 'РегистрацияИзменений'"), SetTablePurpose(False, False, True));
	TablePurposes.Insert(NStr("en = 'Constant'; ru = 'Константа'"), SetTablePurpose(True, True, False));
	TablePurposes.Insert(NStr("en = 'ConstantChangeRecords'; ru = 'РегистрацияИзмененийКонстанты'"), SetTablePurpose(False, False, True));
	TablePurposes.Insert(NStr("en = 'Main'; ru = 'Основная'"), SetTablePurpose(True, True, False));
	TablePurposes.Insert(NStr("en = 'ScheduledJobs'; ru = 'РегламентныеЗадания'"), SetTablePurpose(False, True, False));
	
	TablePurposes.Insert(NStr("en = 'InitializedPredefinedDataInChartOfCharacteristicTypes';
		| ru = 'ИнициализированныеПредопределенныеДанныеПланаВидовХарактеристик'"), SetTablePurpose( , , , True));
	TablePurposes.Insert(NStr("en = 'InitializedPredefinedDataInChartOfAccounts';
		| ru = 'ИнициализированныеПредопределенныеДанныеПланаСчетов'"), SetTablePurpose( , , , True));
	TablePurposes.Insert(NStr("en = 'InitializedPredefinedDataInChartOfCalculationTypes';
		| ru = 'ИнициализированныеПредопределенныеДанныеПланаВидовРасчета'"), SetTablePurpose( , , , True));
	TablePurposes.Insert(NStr("en = 'InitializedPredefinedDataInCatalog';
		| ru = 'ИнициализированныеПредопределенныеДанныеСправочника'"), SetTablePurpose( , , , True));
	
EndProcedure

Function SetTablePurpose(Val Object = False, Val Main = False
	, Val Changes = False, Val Predifined = False)
	
	Var Purpose;
	
	
	Purpose = New Structure;
	Purpose.Insert("IsObjectTable", Object);
	Purpose.Insert("IsMainTable", Main);
	Purpose.Insert("IsChangesTable", Changes);
	Purpose.Insert("IsPredefinedTable", Predifined);
	
	
	Return Purpose;
	
EndFunction

Function GetTablePurpose(Val CurTable)
	
	Var Purpose, Value;
	
	
	Purpose = CurTable.Get(TableID.Purpose);
	TablePurposes.Property(Purpose, Value);
	
	
	Return ?(Value = Undefined, SetTablePurpose(False, False, False), Value);
	
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
	
	
	tableName = GetSQLNameForTable(curTable);
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
			|	FROM [%4].[dbo].[%5] %6"
			, tableName
			, lStrConcat(viewColums, "
			|	, ")
			, lStrConcat(storageColumns, "
			|		, ")
			, ThisObject.SourceDB
			, curTable.Storage
			, WithNoLock()));
	
	
	Return queries;
	
EndFunction

Function GetSQLNameForTable(Val curTable)
	
	Var TableName;
	
	TableName = curTable.FullName;
	If curTable.IsMainTable Then
		TableName = Left(TableName, StrLen(TableName) - lStrFindFromEnd(TableName, "."));
	EndIf;
	TableName = StrReplace(TableName, ".", "_");
	
	If ThisObject.DataView_AddDBName Then
		TableName = lStrTemplate("%1_%2", ThisObject.SourceDB, TableName);
	EndIf;
	
	
	Return TableName;
	
EndFunction

Function WithNoLock()
	
	Return ?(ThisObject.DataView_AddWithNOLOCK, "WITH (NOLOCK)", "");
	
EndFunction

#EndRegion

#Region MaintenanceSQL

Function GetSQLCodeForDropAllDataViews()
	
	Var Views;
	Var Queries;
	
	
	Views = ReadData(
		"SELECT
		|	v.name
		|FROM
		|	sys.views v
		|	INNER JOIN sys.sql_modules m 
		|	ON m.object_id = v.object_id
		|WHERE
		|	m.definition LIKE ? ESCAPE '\'"
		, lToArray(, lStrTemplate("%FROM \[%1\]%", ThisObject.SourceDB)));
		
	Queries = New Array;
	While Views.EOF() = 0 do
		
		Queries.Add(lStrTemplate(
			"DROP VIEW [dbo].[%1]"
			, Views.Fields("Name").Value));
		
		Views.MoveNext();
	EndDo;
	Views.Close();
	
	
	Return Queries;
	
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

#Region Service

Function TypeNumeric(numberOfDigits = 10, numberDecimalPoint = 2, sign = True)
	
	Var qualifier, typeDesc;
	
	
	sign = ?(sign = True, AllowedSign.Any, AllowedSign.Nonnegative);
	qualifier = New NumberQualifiers(numberOfDigits, numberDecimalPoint, sign);
	typeDesc = New TypeDescription("Number", qualifier);
	
	
	Return typeDesc;
	
EndFunction

#EndRegion

#EndRegion
