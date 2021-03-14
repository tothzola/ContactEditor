VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ADOlib"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Attribute VB_Description = "Provides ADO related helpers"
'@Folder "ContactEditor.Storage.Table.ADOlib"
'@ModuleDescription "Provides ADO related helpers"
'@PredeclaredId
'@IgnoreModule IndexedDefaultMemberAccess
Option Explicit


Public Function Create() As ADOlib
    Dim ADOTool As ADOlib
    Set ADOTool = New ADOlib
    'ADOTool.Init
    Set Create = ADOTool
End Function


Public Function GetSQLiteConnectionString(Optional ByVal DBPath As String = vbNullString, _
                                          Optional ByVal Features As String = vbNullString) As Scripting.Dictionary
    Dim Driver As String
    Driver = "SQLite3 ODBC Driver"
    
    Dim Database As String
    Database = Right$(DBPath, Abs(Len(DBPath) - 7))
    Database = VerifyOrGetDefaultPath(Database, Array("db", "sqlite"))
    
    Dim Options As String
    Options = IIf(Len(Features) > 0, Features, "SyncPragma=NORMAL;LongNames=True;NoCreat=True;FKSupport=True;OEMCP=True;")
    
    Dim ConnectionString As Scripting.Dictionary
    Set ConnectionString = New Scripting.Dictionary
    ConnectionString.CompareMode = TextCompare
    
    ConnectionString("ADO") = "Driver=" & Driver & ";" & "Database=" & Database & ";" & Options
    ConnectionString("QT") = "OLEDB;" + ConnectionString("ADO")
    
    Set GetSQLiteConnectionString = ConnectionString
End Function

 
' Takes and array of field names and types (ADODB.DataTypeEnum) collected by the
' DataTableADODB.CollectTableMetadata routine, and empties and populates
' ADODB.Command.Parameters.
'
' LIMITATIONS:
' The first field in FieldNames/FieldTypes is assumed to be primary key, which is added last,
' as it is expected to be used in the WHERE clause.
'
'@Description "Prepares ADODB.Parameters for record update."
Public Sub MakeAdoParamsForRecordUpdate(ByVal FieldNames As Variant, _
                                        ByVal FieldTypes As Variant, _
                                        ByVal AdoCommand As ADODB.Command, _
                               Optional ByVal TypeCast As FieldFormat = FieldFormat.CastAsIs)
Attribute MakeAdoParamsForRecordUpdate.VB_Description = "Prepares ADODB.Parameters for record update."
    '''' Make sure that both FieldNames and FieldTypes are arrays and have the same base and size
    Guard.IncompatibleArrays FieldNames, FieldTypes
    Guard.EmptyString FieldNames(LBound(FieldNames))
    Guard.NullReference AdoCommand
    
    Dim AdjustedTypes() As ADODB.DataTypeEnum
    ReDim AdjustedTypes(LBound(FieldTypes) To UBound(FieldTypes))
    Dim FieldIndex As Long
    
    ' Skip primary key types
    For FieldIndex = LBound(FieldNames) + 1 To UBound(FieldNames)
        AdjustedTypes(FieldIndex) = IIf(TypeCast <> CastAllAsText, FieldTypes(FieldIndex), adVarWChar)
    Next FieldIndex
    
    ' Primary key type
    FieldIndex = LBound(FieldNames)
    AdjustedTypes(FieldIndex) = IIf(TypeCast = CastAsIs, FieldTypes(FieldIndex), adVarWChar)
    
    ' Discard any existing parameters
    Dim AdoParams As ADODB.Parameters: Set AdoParams = AdoCommand.Parameters
    Dim ParamIndex As Long
    For ParamIndex = AdoParams.Count - 1 To 0 Step -1
        AdoParams.Delete ParamIndex
    Next ParamIndex
    
    Dim AdoParam As ADODB.Parameter
    For FieldIndex = LBound(FieldNames) + 1 To UBound(FieldNames)
        Set AdoParam = AdoCommand.CreateParameter(FieldNames(FieldIndex), AdjustedTypes(FieldIndex), , 1, 0)
        AdoParams.Append AdoParam
    Next FieldIndex
    FieldIndex = LBound(FieldNames)
    Set AdoParam = AdoCommand.CreateParameter(FieldNames(FieldIndex), AdjustedTypes(FieldIndex), , 1, 0)
    AdoParams.Append AdoParam
End Sub


Public Sub RecordToAdoParams(ByVal Record As Scripting.Dictionary, ByVal AdoCommand As ADODB.Command)
    Guard.NullReference Record
    Guard.NullReference AdoCommand
    
    Dim AdoParam As Variant
    Dim FieldName As String
    Dim FieldValue As Variant
    For Each AdoParam In AdoCommand.Parameters
        FieldName = AdoParam.Name
        If Record.Exists(FieldName) Then
            FieldValue = Record(FieldName)
            AdoParam.Size = Len(FieldValue)
            AdoParam.Value = FieldValue
        End If
    Next AdoParam
End Sub