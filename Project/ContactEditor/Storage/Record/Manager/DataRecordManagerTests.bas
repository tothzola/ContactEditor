Attribute VB_Name = "DataRecordManagerTests"
'@Folder "ContactEditor.Storage.Record.Manager"
'@TestModule
'@IgnoreModule AssignmentNotUsed, VariableNotUsed, LineLabelNotUsed, UnhandledOnErrorResumeNext, IndexedDefaultMemberAccess
Option Explicit
Option Private Module


#Const LateBind = LateBindTests
#If LateBind Then
    Private Assert As Object
#Else
    Private Assert As Rubberduck.PermissiveAssertClass
#End If


'This method runs once per module.
'@ModuleInitialize
Private Sub ModuleInitialize()
    #If LateBind Then
        Set Assert = CreateObject("Rubberduck.PermissiveAssertClass")
    #Else
        Set Assert = New Rubberduck.PermissiveAssertClass
    #End If
End Sub


'This method runs once per module.
'@ModuleCleanup
Private Sub ModuleCleanup()
    Set Assert = Nothing
    Set Guard = Nothing
End Sub


'This method runs after every test in the module.
'@TestCleanup
Private Sub TestCleanup()
    Err.Clear
End Sub


'===================================================='
'==================== TEST CASES ===================='
'===================================================='


'@TestMethod("DataRecordManager")
Private Sub ztcSaveDataFromModel_ValidatesDirtyStatus()
    On Error GoTo TestFail

    Dim ClassName As String: ClassName = "Worksheet"
    Dim ConnectionString As String: ConnectionString = ThisWorkbook.Name & "!" & TestSheet.Name
    Dim TableName As String: TableName = vbNullString
    
    Dim Storman As IDataRecordManager
    Set Storman = DataRecordManager.Create(ClassName, ConnectionString, TableName)
    
    Storman.LoadDataIntoModel
    Dim StorageModel As DataRecordModel: Set StorageModel = Storman.Model
    Assert.IsFalse StorageModel.IsDirty, "Model should not be dirty"
    StorageModel.SetField "TestEmail", "Edna.Jennings@@neuf.fr"
    Assert.IsTrue StorageModel.IsDirty, "Model should be dirty"
    Assert.AreEqual "Edna.Jennings@@neuf.fr", StorageModel.GetField("TestEmail"), "Set/Get field error"
    
    Storman.SaveDataFromModel
    Assert.IsFalse StorageModel.IsDirty, "Model should not be dirty"
    Assert.AreEqual "Edna.Jennings@@neuf.fr", TestSheet.Range("TestEmail"), "Saved data mismatch"
    StorageModel.SetField "TestEmail", "Edna.Jennings@neuf.fr"
    Storman.SaveDataFromModel
    Assert.AreEqual "Edna.Jennings@neuf.fr", TestSheet.Range("TestEmail"), "Saved data mismatch"
    
CleanExit:
    Exit Sub
TestFail:
    Assert.Fail "Error: " & Err.number & " - " & Err.description
End Sub


