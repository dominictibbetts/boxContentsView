&ANALYZE-SUSPEND _VERSION-NUMBER AB_v10r12
&ANALYZE-RESUME
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS Procedure 
/*------------------------------------------------------------------------
    File        : job stack template
    Purpose     : template procedure for use in job stacker
 
    Syntax      :
 
    Description :
 
    Author(s)   :
    Created     :
    Notes       :
  ----------------------------------------------------------------------*/
/*          This .W file was created with the Progress AppBuilder.      */
/*----------------------------------------------------------------------*/
 
/* ***************************  Definitions  ************************** */
 
{utils/system.i}
{services/psadmin/dac/queueparams.i}
{pslang/import.i &lib = "dac"}
 
 
DEFINE VARIABLE iReportSeqno   AS INTEGER   NO-UNDO.
DEFINE VARIABLE iReportLine    AS INTEGER   NO-UNDO.
 
DEFINE TEMP-TABLE gttReportLogHdrV1         NO-UNDO LIKE ttReportLogHdr.
DEFINE TEMP-TABLE gttReportLogLineV1        NO-UNDO LIKE ttReportLogLine.
 
DEFINE TEMP-TABLE ttloaded NO-UNDO
    FIELD ediseqno AS INTEGER.

DEFINE TEMP-TABLE gttEdiSalesOrderV1 NO-UNDO LIKE ttEdiSalesOrderv1.
DEFINE TEMP-TABLE gttValidatedEdiSalesOrderV1 NO-UNDO LIKE ttEdiSalesOrderv1.

DEFINE VARIABLE cEDIPartner  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE haDataSource AS HANDLE      NO-UNDO.
DEFINE VARIABLE cInEntity    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cArEntity    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cOrderCode   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cImportPath  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cDefaultPath AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cFileName    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cErrorMsg    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cInfo        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cErrorList   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iNumMsgs     AS INTEGER     NO-UNDO.
DEFINE VARIABLE cMsgIdList   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iCnt         AS INTEGER     NO-UNDO.
DEFINE VARIABLE cFieldList   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cPath        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cErrorPath   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCloseOrders AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cClosedOrdersFileName AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cClosedOrdersError AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTimeString AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cErrorComment AS CHARACTER   NO-UNDO.
DEFINE TEMP-TABLE gttEdiErrorsV1 NO-UNDO LIKE ttEdiErrorsV1 .
DEFINE VARIABLE iseqno  AS INTEGER     NO-UNDO.

DEFINE TEMP-TABLE ttEdiFile NO-UNDO
    FIELD FullPath AS CHAR
    FIELD DefaultFileName AS CHAR
    FIELD Errors AS LOG.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Procedure
&Scoped-define DB-AWARE no



/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


/* ************************  Function Prototypes ********************** */

&IF DEFINED(EXCLUDE-CreateEDIErrors) = 0 &THEN

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD CreateEDIErrors Procedure 
FUNCTION CreateEDIErrors RETURNS LOGICAL
    (INPUT ipcException     AS CHARACTER,
     INPUT ipcFieldName     AS CHARACTER,
     INPUT ipiFieldNumber   AS INTEGER,
     INPUT ipcFieldValue    AS CHARACTER,
     INPUT ipiRecordNumber  AS INTEGER,
     INPUT iprEdiSalesOrder AS ROWID,
     INPUT ipcMessage       AS CHARACTER) FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ENDIF

&IF DEFINED(EXCLUDE-SetOperationType) = 0 &THEN

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD SetOperationType Procedure 
FUNCTION SetOperationType RETURNS LOGICAL
  ( phBuf as handle, pcOperationType as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ENDIF


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: Procedure
   Allow: 
   Frames: 0
   Add Fields to: Neither
   Other Settings: CODE-ONLY COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
/* DESIGN Window definition (used by the UIB) 
  CREATE WINDOW Procedure ASSIGN
         HEIGHT             = 15
         WIDTH              = 60.
/* END WINDOW DEFINITION */
                                                                        */
&ANALYZE-RESUME

 


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK Procedure 


/* ***************************  Main Block  *************************** */
 

DEFINE VARIABLE cDefaultFilename AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cname            AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cNewName         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE hAsafSvc         AS HANDLE      NO-UNDO.
DEFINE VARIABLE lAsafProcess     AS Logical     NO-UNDO.
DEFINE VARIABLE cArchivePath     AS CHARACTER   NO-UNDO.


cEDIPartner = (GetParam(pcparams,'EDIPartner')).
cArEntity = (GetParam(pcparams,'ArEntity')).
cInEntity = (GetParam(pcparams,'InEntity')).
cCloseOrders = (GetParam(pcparams,'CloseOrders')).
cClosedOrdersFileName = (GetParam(pcparams,'ClosedOrdersFileName')).

EMPTY TEMP-TABLE ttEdiFile.
haDataSource = requestService("EdiSalesOrder":u, this-procedure, "":u).

assign lAsafProcess = false.

FIND EDIPartner NO-LOCK
WHERE EDIPartner.ArEntity = cArEntity
  AND EDIPartner.EDIpartnerIn = cEDIPartner NO-ERROR.


IF AVAIL EDIPartner THEN DO:
    ASSIGN 
    cOrderCode   = EDIPartner.OrderCode
    cDefaultPath = EDIPartner.PathName
    cFileName    = EDIPartner.DefaultFileName
    cArchivePath = EDIPartner.ArchiveDirectory
    lAsafProcess = EdiPartner.ASAFProcessing.

    /* // Import orders as 'Closed' logic */
    IF cCloseOrders = "YES":U THEN 
        ASSIGN cFileName = cClosedOrdersFileName.

    IF  cDefaultPath <> "" 
        AND ((SUBSTRING(cDefaultPath,(LENGTH(cDefaultPath) - 1),1) <> "\":U) 
             OR (SUBSTRING(cDefaultPath,(LENGTH(cDefaultPath) - 1),1) <> "/":U)) THEN DO:
        ASSIGN cDefaultPath = cDefaultPath + "\":U.
    END.
    
    IF  cArchivePath <> "" 
        AND ((SUBSTRING(cArchivePath,(LENGTH(cArchivePath) - 1),1) <> "\":U) 
             OR (SUBSTRING(cArchivePath,(LENGTH(cArchivePath) - 1),1) <> "/":U)) THEN DO:
        ASSIGN cArchivePath = cArchivePath + "\":U.
    END.        
    
    ASSIGN cImportPath = cDefaultPath + cFileName.
    cErrorPath = cImportPath + ".Error".

END.

/* keep a list of records already loaded for the edipartner */
FOR EACH EdiSalesOrder NO-LOCK
    WHERE EdiSalesOrder.ArEntity = cArEntity
      AND EdiSalesOrder.EDIPartnerCode = cEDIPartner :
    CREATE ttloaded.
    ttloaded.ediseqno = EdiSalesOrder.EdiSeqNo.
END.

EMPTY TEMP-TABLE ttEdiFile.
INPUT FROM OS-DIR (cDefaultPath). 
REPEAT:
    IMPORT cDefaultFileName NO-ERROR.

    cName = cDefaultPath + cDefaultFileName. 
 /* does not work at parkies  */
    IF cFileName = "":u THEN 
        cName = SEARCH(cName).

    ELSE DO:
       IF cDefaultFilename = cFilename 
           THEN cName = SEARCH(cName).
       ELSE cName = ?.

    END. 


    IF cName <> ? AND (SUBSTRING(cname,LENGTH(cname)- 3, LENGTH(cname)) = ".csv") THEN DO:
        CREATE ttEdiFile.
        ASSIGN ttEdiFile.FullPath = cName
               ttEdiFile.DefaultFileName = cDefaultFileName.
    END.
END.
INPUT CLOSE.


  {&xtry}:

  
    FOR EACH ttEdiFile EXCLUSIVE-LOCK: 


      RUN LoadEdiData IN haDataSource(INPUT getGlobalChar({&xcModEntPrefix} + string({&xiModAccountReceivable})), 
                                      INPUT getGlobalChar({&xcModEntPrefix} + string({&xiModInventory})), 
                                      INPUT cEDIPartner,
                                      INPUT cOrderCode,
                                      INPUT ttEdiFile.FullPath,
                                      OUTPUT TABLE gttEdiErrorsV1).
      FIND FIRST gttEdiErrorsV1 NO-LOCK NO-ERROR.
      IF NOT AVAILABLE gttEdiErrorsV1 THEN
          ASSIGN ttEdiFile.Errors = FALSE.
      ELSE ASSIGN ttEdiFile.Errors = TRUE.
     END. 
  END.  

    FOR EACH EdiSalesOrder NO-LOCK
        WHERE EdiSalesOrder.ArEntity = cArEntity
          AND EdiSalesOrder.EDIPartnerCode = cEDIPartner :
    
        IF CAN-FIND (ttloaded WHERE ttloaded.ediseqno = EdiSalesOrder.EdiSeqNo) THEN NEXT.
        CREATE gttEdiSalesOrderV1.
        BUFFER-COPY EdiSalesOrder TO gttEdiSalesOrderv1.
        PackRowInfo (INPUT-OUTPUT gttEdiSalesOrderv1.RowInfo,(BUFFER EdiSalesOrder:HANDLE)).
    END.
    
    IF NOT CAN-FIND(FIRST gttEdiSalesOrderv1) THEN DO:
       /* pcinfomessage = "No records loaded ":u.*/
        NEXT.
    END. 
    
    RUN ValidateEdiOrders 
        IN haDataSource
        (INPUT-OUTPUT TABLE gttEdiSalesOrderV1,
         NO,
         OUTPUT TABLE gttEdiErrorsV1).
    

    FIND FIRST gttEdiErrorsV1 NO-LOCK NO-ERROR.
    IF AVAILABLE gttEdiErrorsV1 THEN
    DO:

        FOR EACH gttEdiSalesOrderV1 
            WHERE gttEdiSalesOrderV1.Validated = NO:

            ASSIGN cTimeString = STRING(TIME,"HH:MM:SS":U)
                   cTimeString = REPLACE(cTimeString,":":U,"":U)
                   cClosedOrdersError = cDefaultPath + gttEdiSalesOrderV1.EdiPartnerCode
                                                    + "-":u + STRING(gttEdiSalesOrderV1.EdiSeqNo) 
                                                    + "_ValidationError_":U 
                                                    + STRING(YEAR(TODAY))
                                                    + "-":U + STRING(MONTH(TODAY))
                                                    + "-":U + STRING(DAY(TODAY))
                                                    + "_":U + cTimeString
                                                    + ".txt".

            OUTPUT TO VALUE(cClosedOrdersError) APPEND.
            FOR EACH gttEdiErrorsV1 WHERE gttEdiErrorsV1.FieldNumber = gttEdiSalesOrderV1.EdiSeqNo NO-LOCK:
                PUT UNFORMATTED "ERROR: Line: " gttEdiErrorsV1.RecordNumber 
                                " Exception: " gttEdiErrorsV1.Exception " " gttEdiErrorsV1.FieldValue SKIP.
            END.
            PUT UNFORMATTED gttEdiSalesOrderV1.Data SKIP.
            DO TRANSACTION:
                FOR EACH EdiSalesOrderLine WHERE EdiSalesOrderLine.ArEntity = gttEdiSalesOrderV1.ArEntity
                                             AND EdiSalesOrderLine.EdiSeqNo = gttEdiSalesOrderV1.EdiSeqNo
                                             NO-LOCK:
                    PUT UNFORMATTED EdiSalesOrderLine.Data SKIP.
                END.
                FOR EACH EdiSalesOrderAddCharges 
                    WHERE EdiSalesOrderAddCharges.ArEntity = gttEdiSalesOrderV1.ArEntity
                      AND EdiSalesOrderAddCharges.EdiSeqNo = gttEdiSalesOrderV1.EdiSeqNo
                                             NO-LOCK:
                    PUT UNFORMATTED EdiSalesOrderAddCharges.Data SKIP.
                END.
            END.
            OUTPUT CLOSE.
        END.
    END.


    IF CAN-FIND(gttEdiSalesOrderV1 WHERE gttEdiSalesOrderV1.Validated = NO) THEN
        pcinfomessage = "validation errors, error file saved as ":u + cClosedOrdersError.
    ELSE pcinfomessage = "":u.
    
    /* if any failed validation then write the lines to an error file */
    /* the actual line data is saved in EDISalesOrder/Line.data */
    IF cCloseOrders <> "YES":U THEN DO:
        FOR EACH gttEdiSalesOrderV1
            WHERE gttEdiSalesOrderV1.Validated = NO :
            OUTPUT TO VALUE(cClosedOrdersError) APPEND.
            PUT UNFORMATTED  gttEdiSalesOrderV1.Data SKIP.
        
            FOR EACH EdiSalesOrderLine NO-LOCK
                WHERE EdiSalesOrderLine.ArEntity = gttEdiSalesOrderV1.ArEntity
                  AND EdiSalesOrderLine.EdiSeqNo = gttEdiSalesOrderV1.EdiSeqNo :
        
                PUT UNFORMATTED EdiSalesOrderLine.Data SKIP.
            END.
            FOR EACH EdiSalesOrderAddCharges NO-LOCK
                WHERE EdiSalesOrderAddCharges.ArEntity = gttEdiSalesOrderV1.ArEntity
                  AND EdiSalesOrderAddCharges.EdiSeqNo = gttEdiSalesOrderV1.EdiSeqNo :
                
                PUT UNFORMATTED EdiSalesOrderAddCharges.Data SKIP.
            END.

            OUTPUT CLOSE.
        END.
    END.
    ELSE DO:
        /* // Closed Orders */
        ASSIGN cTimeString = STRING(TIME,"HH:MM:SS":U)
               cTimeString = REPLACE(cTimeString,":":U,"":U)
               cClosedOrdersError = cImportPath + ".CloseOrdersError_":U 
                                                + STRING(YEAR(TODAY))
                                                + "-":U + STRING(MONTH(TODAY))
                                                + "-":U + STRING(DAY(TODAY))
                                                + "_":U + cTimeString.
        FOR EACH gttEdiSalesOrderV1 WHERE gttEdiSalesOrderV1.Validated = NO:
            OUTPUT TO VALUE(cClosedOrdersError) APPEND.
            FOR EACH gttEdiErrorsV1 WHERE gttEdiErrorsV1.FieldNumber = gttEdiSalesOrderV1.EdiSeqNo NO-LOCK:
                PUT UNFORMATTED "ERROR: Line: " gttEdiErrorsV1.RecordNumber 
                                " Exception: " gttEdiErrorsV1.Exception " " gttEdiErrorsV1.FieldValue.
            END.
            PUT UNFORMATTED gttEdiSalesOrderV1.Data SKIP.
            DO TRANSACTION:
                FOR EACH EdiSalesOrderLine WHERE EdiSalesOrderLine.ArEntity = gttEdiSalesOrderV1.ArEntity
                                             AND EdiSalesOrderLine.EdiSeqNo = gttEdiSalesOrderV1.EdiSeqNo
                                             EXCLUSIVE-LOCK:
                    PUT UNFORMATTED EdiSalesOrderLine.Data SKIP.
                    /* // These must not display in EDI SalesOrder Import as they are closed orders */
                    DELETE EdiSalesOrderLine.
                END.
                RELEASE EdiSalesOrderLine.
                FOR EACH EdiSalesOrderAddCharges WHERE EdiSalesOrderAddCharges.ArEntity = gttEdiSalesOrderV1.ArEntity /*AddCharges*/
                                             AND EdiSalesOrderAddCharges.EdiSeqNo = gttEdiSalesOrderV1.EdiSeqNo
                                             EXCLUSIVE-LOCK:
                                             
                    PUT UNFORMATTED EdiSalesOrderAddCharges.Data SKIP.
                            /* // These must not display in EDI SalesOrder Import as they are closed orders */
                    DELETE EdiSalesOrderAddCharges.
                END.
                        RELEASE EdiSalesOrderAddCharges.
            END.
            OUTPUT CLOSE.
        END.
    END.

    FOR EACH ttEdiFile 
        WHERE ttEdiFile.Errors = TRUE
        NO-LOCK: 

    END.

    FOR EACH ttEdiFile 
        WHERE ttEdiFile.Errors = FALSE
        NO-LOCK: 


          iseqno = iseqno + 1.
         /* rename the input file */
         /*cNewName = cDefaultPath + EdiPartner.EDIpartnerCode + ttEdiFile.DefaultFileName
               + STRING(TODAY,"999999":U) + STRING(iseqno) + ".old":U.*/
                           
         /* rename the input file */
         cNewName = cArchivePath + EdiPartner.EDIpartnerCode + ttEdiFile.DefaultFileName
               + STRING(TODAY,"999999":U) + STRING(TIME) + ".old":U.                           

 
          OS-COPY VALUE(ttEdiFile.FullPath) VALUE(cNewName).
          OS-DELETE VALUE(ttEdiFile.FullPath).
    END.
    
    FOR EACH gttEdiSalesOrderV1 WHERE gttEdiSalesOrderV1.Validated :
        CREATE gttValidatedEdiSalesOrderV1.
        BUFFER-COPY gttEdiSalesOrderV1 TO gttValidatedEdiSalesOrderV1.
        IF cCloseOrders = "YES":U THEN
            ASSIGN gttValidatedEdiSalesOrderV1.CloseOrder = TRUE.
    END.
    
    RELEASE gttValidatedEdiSalesOrderV1.
    FIND FIRST gttValidatedEdiSalesOrderV1 NO-LOCK NO-ERROR.
    IF AVAILABLE (gttValidatedEdiSalesOrderV1) THEN DO:
    
        RUN CreateSalesOrder IN haDataSource 
        (INPUT-OUTPUT TABLE gttValidatedEdiSalesOrderV1,
        INPUT "":u,
         OUTPUT cInfo).
        IF RETURN-VALUE <> {&xcsuccess} THEN 
        DO:
            /* Transaction failed, extract the errors and display them */
            ASSIGN cErrorList = getParamValue(cInfo, "ErrorList":u)
                   iNumMsgs   = NUM-ENTRIES(cErrorList, {&xcMsgDelimiter}).
           
            IF iNumMsgs = 1 
            THEN cMsgIdList = cErrorList.
            ELSE
            DO iCnt = 1 TO iNumMsgs BY 2:
              
                ASSIGN cMsgIdList = cMsgIdList + {&xcMsgDelimiter} + ENTRY(iCnt, cErrorList, {&xcMsgDelimiter}) NO-ERROR.
                       cFieldList = cFieldList + "," + ENTRY(iCnt + 1, cErrorList, {&xcMsgDelimiter}).
            END.
    
            cMsgIdList = TRIM(cMsgIdList, {&xcMsgDelimiter}).
            MESSAGE 
                cMsgIdList
                VIEW-AS ALERT-BOX INFO BUTTONS OK.
        END.
 
END.    
IF catchall() THEN 
DisplayException().
 
/* ======FOR GENERIC LIST REPORT======*/

{services/psadmin/dac/createheader.i
    &xcReportTitle = "EDI Auto Load"
    &xcColumnLables    = "EDI Seq,Customer PO,Customer Code,Order Date,Validated,Error,Order Number"
    &xcFieldTypes      = "CHARACTER,CHARACTER,CHARACTER,CHARACTER,CHARACTER,CHARACTER,CHARACTER"
    &xcColumnSizes      = "80,100,100,80,80,200,80"}
 

IF cCloseOrders = "YES":U THEN
    ASSIGN cErrorComment = "Closed Order Error - view error file " + cClosedOrdersError.
ELSE
    ASSIGN cErrorComment = "View in EDI Sales Order Errors":U.

FOR EACH gttEdiSalesOrderV1 :

    FIND EdiSalesOrder NO-LOCK 
        WHERE EdiSalesOrder.ArEntity = gttEdiSalesOrderV1.ArEntity
          AND EdiSalesOrder.EDIPartnerCode = gttEdiSalesOrderV1.EDIPartnerCode
          AND EdiSalesOrder.EdiSeqNo = gttEdiSalesOrderV1.EdiSeqNo NO-ERROR.

    FIND gttValidatedEdiSalesOrderV1 
        WHERE gttValidatedEdiSalesOrderV1.EDISeqNo = gttEdiSalesOrderV1.EDISeqNo NO-ERROR.
    RUN createline( string(gttEdiSalesOrderV1.EdiSeqNo) + ",":u +
                    gttEdiSalesOrderV1.CustomerPurchaseOrder + ",":u +
                    gttEdiSalesOrderV1.CustomerCode + ",":u +
                    string(gttEdiSalesOrderV1.OrderDate) + ",":u +
                    string(gttEdiSalesOrderV1.Validated) + ",":u +
                    /* (IF gttEdiSalesOrderV1.Validated THEN "" ELSE "View in EDI Sales Order Errors") + ",":u + */
                    (IF gttEdiSalesOrderV1.Validated THEN "" ELSE cErrorComment) + ",":u +
                    IF AVAIL gttValidatedEdiSalesOrderV1 THEN string( gttValidatedEdiSalesOrderV1.OrderNumber) ELSE "").

    /* // If closed orders and failed validation then remove from EdiSalesOrder to prevent the order 
          from being validated and loaded as 'open' in EDI Sales Order function */
    IF cCloseOrders = "YES":U THEN DO:
        IF EdiSalesOrder.Validated = FALSE THEN 
        DO TRANSACTION:
            FIND CURRENT EdiSalesOrder EXCLUSIVE-LOCK NO-ERROR.
            IF AVAILABLE EdiSalesOrder THEN 
                DELETE EdiSalesOrder.                   
            RELEASE EdiSalesOrder.
        END.
    END.
END.


if lAsafProcess then
do:
    /*asaf processing*/
    hAsafSvc = requestService("PpsConfirmAsaf":u, this-procedure, "":u) NO-ERROR.
    IF VALID-HANDLE(hAsafSvc) THEN
        RUN AllocateAndPickAsaf IN hAsafSvc.
end.
 

plshowreport = YES. 
 
pcSuccess = {&xcSuccess}.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&IF DEFINED(EXCLUDE-CreateLine) = 0 &THEN

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CreateLine Procedure 
PROCEDURE CreateLine :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 
{services/psadmin/dac/createline.i}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ENDIF

&IF DEFINED(EXCLUDE-CreateReportLine) = 0 &THEN

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CreateReportLine Procedure 
PROCEDURE CreateReportLine :
/*------------------------------------------------------------------------------
  Purpose: create report log header and report log line records
  for the generic report
  Parameters:  <none>
  Notes:
------------------------------------------------------------------------------*/
    {services/cb/bfc/createreport.i
 
     &xcReportTitle     = "<insert report title>"
     &xiNoColumns       = "1"
     &xcColumnLables    = "col1,col2"
     &xcColumnSize      = "20,20,20,20"
     &xcColumnAlignment = "L,L,L,L"  }
 
 
 
 
 
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ENDIF

&IF DEFINED(EXCLUDE-validateediorders) = 0 &THEN

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE validateediorders Procedure 
PROCEDURE validateediorders :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE VARIABLE hCustomerSvc       AS HANDLE      NO-UNDO.
DEFINE VARIABLE hHoldReasonSvc     AS HANDLE    NO-UNDO.
DEFINE VARIABLE cHoldReason        AS CHARACTER NO-UNDO.
DEFINE VARIABLE cHoldReasonDesc    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOpHoldReason      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOpHoldReasonDesc  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTransactionType   AS CHARACTER NO-UNDO.
DEFINE VARIABLE lAllowOrder        AS LOGICAL   NO-UNDO.
DEFINE VARIABLE lOpAllowOrder      AS LOGICAL   NO-UNDO.
DEFINE VARIABLE lAllowAllocation   AS LOGICAL     NO-UNDO.
DEFINE VARIABLE lOpAllowAllocation AS LOGICAL     NO-UNDO.
DEFINE VARIABLE cWarehouse AS CHARACTER   NO-UNDO.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ENDIF

/* ************************  Function Implementations ***************** */

&IF DEFINED(EXCLUDE-CreateEDIErrors) = 0 &THEN

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION CreateEDIErrors Procedure 
FUNCTION CreateEDIErrors RETURNS LOGICAL
    (INPUT ipcException     AS CHARACTER,
     INPUT ipcFieldName     AS CHARACTER,
     INPUT ipiFieldNumber   AS INTEGER,
     INPUT ipcFieldValue    AS CHARACTER,
     INPUT ipiRecordNumber  AS INTEGER,
     INPUT iprEdiSalesOrder AS ROWID,
     INPUT ipcMessage       AS CHARACTER):
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE BUFFER EdiSalesOrder FOR EdiSalesOrder.
DEFINE VARIABLE cErrorDescription AS CHARACTER NO-UNDO.
DEFINE VARIABLE iRowNum AS INTEGER     NO-UNDO.


FIND LAST gttEdiErrorsV1 NO-ERROR.

IF AVAIL gttEdiErrorsV1
THEN ASSIGN iRowNum = gttEdiErrorsV1.RowNum + 1.

CREATE gttEdiErrorsV1.
ASSIGN gttEdiErrorsV1.Exception    = ipcException
       gttEdiErrorsV1.FieldName    = ipcFieldName
       gttEdiErrorsV1.FieldNumber  = ipiFieldNumber
       gttEdiErrorsV1.FieldValue   = ipcFieldValue
       gttEdiErrorsV1.RecordNumber = ipiRecordNumber
       gttEdiErrorsV1.RowNum       = iRowNum.
  
FIND EdiSalesOrder EXCLUSIVE-LOCK
    WHERE ROWID(EdiSalesOrder) = iprEdiSalesOrder NO-ERROR.

IF AVAIL EdiSalesOrder 
THEN DO:
    ASSIGN cErrorDescription = EdiSalesOrder.ErrorDescription 
                               + (IF EdiSalesOrder.ErrorDescription = "":U 
                                  THEN "":U 
                                  ELSE {&xcMsgDelimiter})
                               + (IF ipcMessage = "Exception + FieldName":U
                                  THEN ipcException + {&xcMsgArgDelim} + ipcFieldName
                                  ELSE ipcMessage).

    FOR EACH EdiTrans
        WHERE EdiTrans.ArEntity = EdiSalesOrder.ArEntity
        AND   EdiTrans.EdiSEqNo = EdiSalesOrder.EdiSeqNo
        EXCLUSIVE.

        ASSIGN EdiTrans.ErrorDescription = cErrorDescription /*EdiSalesOrder.ErrorDescription*/
               EdiTrans.AuditTime        = DATETIME(TODAY).
    END.
    RELEASE EdiTrans.
END.
ELSE RETURN NO.

RETURN YES.
  
END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ENDIF

&IF DEFINED(EXCLUDE-SetOperationType) = 0 &THEN

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION SetOperationType Procedure 
FUNCTION SetOperationType RETURNS LOGICAL
  ( phBuf as handle, pcOperationType as char ) :
/*------------------------------------------------------------------------------
 Sets the type of operation that is to be performed on the row. Will be
 one of:
 
 {&xcDACAdd}
 {&xcDACDelete}
 {&xcDACUpdate}
------------------------------------------------------------------------------*/
 
  def var hFld as handle no-undo.
 
  assert(pcOperationType = {&xcDACAdd} or
         pcOperationType = {&xcDACDelete} or
         pcOperationType = {&xcDACUpdate},
         substitute("Invalid operation type requested [&1].":u, pcOperationType)).
 
  hFld = phBuf:buffer-field("RowInfo":u) no-error.
 
  assert(valid-handle(hFld), "Unable to obtain a handle to the RowInfo field.":u).
 
  hFld:buffer-value = putParam(hFld:buffer-value, "OperationType":u, pcOperationType).
 
  return true.
 
END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ENDIF

