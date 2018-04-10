&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v9r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
          dwtemp           PROGRESS
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW


/* Temp-Table and Buffer definitions                                    */
DEFINE TEMP-TABLE gttAllocationOrderLineV1 NO-UNDO LIKE ttOrderLineV1.
DEFINE TEMP-TABLE gttItemClassStockV1 NO-UNDO LIKE ttItemClassStockV1.
DEFINE TEMP-TABLE gttItemStockV1 NO-UNDO LIKE ttItemStockV1.
DEFINE TEMP-TABLE gttItemV1 NO-UNDO LIKE ttItemV1.
DEFINE TEMP-TABLE gttKitOrderLineV1 NO-UNDO LIKE ttOrderLineV1.
DEFINE TEMP-TABLE gttLinkOrderLineV1 NO-UNDO LIKE ttOrderLineV1.
DEFINE TEMP-TABLE gttMasterKitOrderLineV1 NO-UNDO LIKE ttOrderLineV1.
DEFINE TEMP-TABLE gttMasterLinkOrderLineV1 NO-UNDO LIKE ttOrderLineV1.
DEFINE TEMP-TABLE gttOrderAllocLineDetailV1 NO-UNDO LIKE ttOrderAllocLineDetailV1.
DEFINE TEMP-TABLE gttOrderLineV1 NO-UNDO LIKE ttOrderLineV1.
DEFINE TEMP-TABLE gttOrderLogoV1 NO-UNDO LIKE ttOrderLogoV1.
DEFINE TEMP-TABLE gttUomV1 NO-UNDO LIKE ttUomV1.



&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS a 
/*------------------------------------------------------------------------
 aorderline.w
  
 DataAccessComponent to support access to the OrderLine table.
 
  11/12/2002 Item Entity fix                                            - GCW 
  12/12/2002 Entity on itemwhs                                          - GCW
  24/02/2003 Added functionality to allocate orders that have been      - SS
             partly picked. 
  02/04/2003 removed invoice table from export to excel procedure       - TC
  17/07/2003 cErrorMsg Variable in procedure UpdateBlanketOrderRelease  - TC
             should be type CHARACTER.
  15/07/2003 Added OrderImpact request for stock movements              - MAB
  02/09/2003 Added procedure to find customer pricing item details      - TC
  11/09/2003 When adding a new line then we need validation to check    - SS
             for zero quantity, otherwise we should allow user to
             update open qty to zero. 
  30/09/2003 Added Reserve and PoReservation requests for the           - MAB
             processing of SO/PO Reservations.
             Also added CustomerCode into gttOrderLineV1.
  10/10/2003 Added WoReservation request for the processing of          - MAB
             SO/WO Reservations.
  02/12/2003 Default page 1 memo to customer pricing psmemo             - SS     
  26/05/2004 Item validation fails                          PocketERp   - GCW  
  01/06/2004 Development for customer order enquiry                     - SS SP012-PS02   
  09/07/2004 Added TransferAlloc request for Transfer Allocations.      - MAB   
  28/07/2004 Sales orders are not appearing in tab of Wo Entry          - SS (Franklins workshop)
  13/10/2004 Added CreateCPM request for Critical Path Management.      - MAB
  26/10/2004 Mods for Alternative stock enquiry                         - SS (ST018)           
  06/12/2004 Credit limit checks should use the Statement Customer.     - MAB (638242)
  16/11/2005 The BaseUomCode is not populated if the line number is     - MAB (640247)
             not the generic line.
  02/02/2006 Changes for the alternative stock enquiry                  - SS (639011)
  08/01/2007 CreditLimit message enhancements                           - PJH (642621)
  20/07/2007 Market Segmentation.                                       - MAB (ICW034)
  24/10/2007 F7 does not work becuase fetch is incorrect                - SS (645108) RTB 3092
  04/07/2008 Region Segmentation.                                       - MAB         RTB 3744
  11/02/2009 Kits deve                                                  - SS  5343
  24/03/2009 Validation to check valid item / whs combination needs to  - SS 650093 RTB 5610
  21/04/2009 Credit limit message is sometimes wrong                    - HEW 646673 and 649937 RTB 5714 
  02/07/2009 Bodyguard Item link add customer code                      - PMC RTB 5998
  18/09/2009 Corrected problem with -nb and also quantity on work order - SS (651611)
             Value is wrong.
  07/12/2009 Improve getcustomeritemcode                                - HEW 6622 652426                 
  04/03/2010 Store the EcServiceItem flag. (ESL Sales)                    MAB  6854
  30/03/2010 Eveden Credit check modification.  Scope 12400.              HEW  6865
  06/08/2010 Region Segmentation Changes. (653979)                        JT/KKB 7231
             - In CheckRegionSegmentation(), check region effective date  
               against order request date.
             - Check against itemcode region segments before genericitem 
               code.
             - Copy Promise/Request Dates Checks.  
             - Check region segment expiry date against TODAY and not 
               order request date.
             - Don't perform Expiry Date check on Copy Promise/Req Date 
               check.  
  17/05/2012 Change generic region segment validation from < TODAY to     KKB 8594  
             <= TODAY to be consistent with other expiry date checks.
             (658297)
  06/11/2012 Correct assert error on xditemstock                          HEW 8773
  22/10/2012 CheckSalesOrder GetQuantityOpenOrdered (DC Development)      HEW 8745
  30/07/2015 Eveden XD allocation development                             HEW 10407 663391
  11/08/2015 Conditional validation in CheckRegionSegmentation            HEW 10494 664490

 A fetchViewName routine is needed for each view that this DAC supports.

 A updateViewName and refreshViewName routine is needed for each view 
 through which the user can update the database.  
  ----------------------------------------------------------------------*/
/*          This .W file was created with the Progress AppBuilder.      */
/*----------------------------------------------------------------------*/

{utils/system.i}
{utils/uom.i}
{utils/opLibrary.i}

/* Identifies the version of the DAC internals that this DAC is 
 * to use. */
&scop xiDACVersion 2

/* ***************************  Definitions  ************************** */

/* Contains a comma-separated list of the requests that this DAC 
 * supports. */
&scop xcSupportedRequests "all,OrderNumberSC,OrderLineForWoSalesOrder,ValidOrderLine,customer,OrderNumberForAlloc,OrderImpact,Reserve,PoReservation,WoReservation,OrderNumber,TransferAlloc,CreateCPM,OpenOrderNumber,SingleOrderLine,OutstandingEmb,NoMatsLines":u

/* Define buffers that will be passed to assignViewName() functions.
 * If this is not done then the incorrect buffer s passed to them. */

def buffer OrderLine for OrderLine.
  DEFINE TEMP-TABLE xttOrderLineV1 NO-UNDO LIKE ttOrderLineV1
  FIELD InvoiceNumber    LIKE ttOrderV1.InvoiceNumber
  FIELD InvoiceDate      LIKE ttOrderV1.InvoiceDate
  FIELD SalesRepCode     LIKE ttOrderV1.salesRepCode
  FIELD ppsNumber        LIKE ttOrderV1.ppsNumber
  FIELD OpenValue        LIKE ttOrderV1.OpenValue
  FIELD Base1OpenValue   LIKE ttOrderV1.Base1OpenValue
  FIELD ViaDescription   LIKE ttOrderV1.viaDescription
  FIELD ShipTo           LIKE ttOrderV1.ShipTo
  FIELD CustomerName     LIKE ttCustomerV1.NAME
  FIELD ItemDescription  LIKE ttItemV1.DESCRIPTION
  FIELD InvoiceVatAmount LIKE ttInvoiceLineV1.VatAmount
  FIELD OrderVatAmount   LIKE ttOrderLineV1.VatAmount.
  

DEFINE TEMP-TABLE ttchkorderlinev1 NO-UNDO LIKE ttorderlinev1.

DEFINE TEMP-TABLE ttLogoStockItems NO-UNDO
       FIELD InEntity        AS CHAR
       FIELD ItemCode        AS CHAR
       FIELD WarehouseCode   AS CHAR
       FIELD Quantity        AS INT.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE DataAccessComponent
&Scoped-define DB-AWARE no


/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


/* ************************  Function Prototypes ********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD assignOrderLineV1 a 
FUNCTION assignOrderLineV1 returns logical
  ( buffer pbgttOrderLineV1 for gttOrderLineV1, 
    buffer pbOrderLine for OrderLine, 
    piRowNum as int )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD CheckOrderStock a 
FUNCTION CheckOrderStock RETURNS LOGICAL
  (   INPUT TABLE FOR ttchkorderlinev1,
      OUTPUT pcmessage AS CHARACTER )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD deleteAllowed a 
FUNCTION deleteAllowed returns logical PRIVATE
  ( input phBuf as handle, pcOptions as char, output pcMsg as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD getCustMemo a 
FUNCTION getCustMemo RETURNS CHARACTER
  ( pcCustomerCode AS CHAR, pcInEntity AS CHAR, pcItemCode AS CHAR, pcGenericItemCode AS CHAR )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD getNumAttributesForItem a 
FUNCTION getNumAttributesForItem RETURNS INTEGER
  ( pcItemCode AS CHAR , pcInEntity AS CHAR)  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD HasLogoStockItem a 
FUNCTION HasLogoStockItem RETURNS LOGICAL
  ( cArEntity AS CHAR, iOrderNumber AS INT, iLineNumber AS INT )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD OrderEntryCustItemLookup a 
FUNCTION OrderEntryCustItemLookup RETURNS CHARACTER
  ( /* parameter-definitions */ )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD populateKeyDesc a 
FUNCTION populateKeyDesc returns logical
  ( input phBuf as handle )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD PreDBUpdate a 
FUNCTION PreDBUpdate RETURNS LOGICAL
  ( /* parameter-definitions */ )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD ReturnShopCalendarDays a 
FUNCTION ReturnShopCalendarDays RETURNS INTEGER
      ( INPUT piLeadTimeDays AS INT,
        OUTPUT piNumberOfDays AS INT )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD valDaysToShip a 
FUNCTION valDaysToShip RETURNS CHARACTER
  ( input phDaysToShip as handle, 
    input plAddMode    as logical, 
    input pcMsg        as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD validateRow a 
FUNCTION validateRow returns character PRIVATE
  ( input phBuf as handle, plAdding as log, pcOptions as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD validItem a 
FUNCTION validItem RETURNS CHARACTER
  ( input  pcInEntity    as char,
    input  pcItemCode    as char,
    output pcMsg         as char)  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD valPromiseDate a 
FUNCTION valPromiseDate RETURNS CHARACTER
  ( input phPromiseDate as handle, 
    input plAddMode    as logical, 
    input pcMsg        as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD valRequestDate a 
FUNCTION valRequestDate RETURNS CHARACTER
  ( input phRequestDate as handle, 
    input plAddMode    as logical, 
    input pcMsg        as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD valVolumeDiscount a 
FUNCTION valVolumeDiscount RETURNS CHARACTER
  ( input phVolumeDiscount as handle, 
    input plAddMode  as logical, 
    input pcMsg      as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD valWarehouseCode a 
FUNCTION valWarehouseCode RETURNS CHARACTER
  ( input phWarehouseCode as handle, 
    input plAddMode       as logical, 
    input pcMsg           as char )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD XDInUse a 
FUNCTION XDInUse RETURNS LOGICAL
  ( /* parameter-definitions */ )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* ***********************  Control Definitions  ********************** */


/* ************************  Frame Definitions  *********************** */


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: DataAccessComponent
   Allow: 
   Frames: 0
   Add Fields to: Neither
   Other Settings: PERSISTENT-ONLY COMPILE
   Temp-Tables and Buffers:
      TABLE: gttAllocationOrderLineV1 T "?" NO-UNDO dwtemp ttOrderLineV1
      TABLE: gttItemClassStockV1 T "?" NO-UNDO dwtemp ttItemClassStockV1
      TABLE: gttItemStockV1 T "?" NO-UNDO dwtemp ttItemStockV1
      TABLE: gttItemV1 T "?" NO-UNDO dwtemp ttItemV1
      TABLE: gttKitOrderLineV1 T "?" NO-UNDO dwtemp ttOrderLineV1
      TABLE: gttLinkOrderLineV1 T "?" NO-UNDO dwtemp ttOrderLineV1
      TABLE: gttMasterKitOrderLineV1 T "?" NO-UNDO dwtemp ttOrderLineV1
      TABLE: gttMasterLinkOrderLineV1 T "?" NO-UNDO dwtemp ttOrderLineV1
      TABLE: gttOrderAllocLineDetailV1 T "?" NO-UNDO dwtemp ttOrderAllocLineDetailV1
      TABLE: gttOrderLineV1 T "?" NO-UNDO dwtemp ttOrderLineV1
      TABLE: gttOrderLogoV1 T "?" NO-UNDO dwtemp ttOrderLogoV1
      TABLE: gttUomV1 T "?" NO-UNDO dwtemp ttUomV1
   END-TABLES.
 */

/* This procedure should always be RUN PERSISTENT.  Report the error,  */
/* then cleanup and return.                                            */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
  MESSAGE "{&FILE-NAME} should only be RUN PERSISTENT.":U
          VIEW-AS ALERT-BOX ERROR BUTTONS OK.
  RETURN.
END.

&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
/* DESIGN Window definition (used by the UIB) 
  CREATE WINDOW a ASSIGN
         HEIGHT             = 3.33
         WIDTH              = 65.
/* END WINDOW DEFINITION */
                                                                        */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB a 
/* ************************* Included-Libraries *********************** */

{psobject/dac/dac.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW a
  VISIBLE,,RUN-PERSISTENT                                               */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK a 


/* ***************************  Main Block  *************************** */

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CheckCreditLimit a 
PROCEDURE CheckCreditLimit :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input param pcCustomerCode       as char no-undo.
  def input param pdTotalExtendedValue as dec no-undo.
  def output param pcErrorMsg          as char no-undo.

  /* 06/12/2004 MAB 638242 */
  DEFINE VARIABLE cStatementCustomer    AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cArEntity             AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lOEPPSGenCreditCheck  AS LOGICAL NO-UNDO.
  DEFINE VARIABLE cUsername             AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE cGlEntity             AS CHARACTER NO-UNDO.

  ASSIGN cArEntity = GetGlobalChar({&xcModEntPrefix} + STRING({&xiModOrderProcessing})).
  
  IF cGlEntity = "" OR cGlEntity = ? THEN 
  DO:
      FIND  ControlEntity WHERE  ControlEntity.entitycode =  cArEntity /* change to the module you are currently in AR AP etc */
                       AND   ControlEntity.moduleid = {&xiModGeneralLedger} NO-LOCK.
      
      ASSIGN cGlEntity = ControlEntity.ControlEntityCode.
  END.

  FIND OpControl WHERE OpControl.ArEntity = cArEntity NO-LOCK NO-ERROR.
  
  IF AVAILABLE OpControl
  THEN ASSIGN lOEPPSGenCreditCheck = opControl.OEPPSGenCreditCheck.
  ELSE ASSIGN lOEPPSGenCreditCheck = NO.

  FIND Customer NO-LOCK
       WHERE Customer.CustomerCode = pcCustomerCode
       NO-ERROR.

  IF AVAILABLE Customer
  THEN DO:
       ASSIGN cStatementCustomer = Customer.StatementCustomer.

       IF Customer.CustomerCode <> cStatementCustomer
       THEN FIND Customer NO-LOCK
                 WHERE Customer.CustomerCode = cStatementCustomer
                 NO-ERROR.

       cUserName = GetGlobalChar("USER/UserName":u).

       FIND FIRST psUser NO-LOCK WHERE psuser.psUSERID = cUserName NO-ERROR.


       IF AVAILABLE Customer
       THEN DO:
            FIND CustomerTotals NO-LOCK
                 WHERE CustomerTotals.CustomerCode = cStatementCustomer
                 AND   CustomerTotals.GlEntity     = cGlEntity
                 NO-ERROR.

            IF AVAILABLE CustomerTotals
            THEN DO:
                IF lOEPPSGenCreditCheck THEN
                DO:
                    IF pdTotalExtendedValue > CustomerTotals.CreditLimit - CustomerTotals.Balance - CustomerTotals.PPSValue
                    THEN DO: 
                        IF CAN-FIND(FIRST psMessage NO-LOCK WHERE psMessage.MessageKey = "CreditLimitExceedingQues2":U
                                    AND psmessage.languageid = psUser.languageid
                                    ) 
                        THEN ASSIGN pcErrorMsg = "CreditLimitExceedingQues2":u 
                                      + {&xcMsgArgDelim} + cStatementCustomer 
                                      + {&xcMsgArgDelim} 
                                      + "~n~nCredit Limit = " + TRIM(String(Customer.CreditLimit,"->,>>>,>>9.99"))
                                      + "~nAccount Balance = " + TRIM(String(CustomerTotals.Balance,"->,>>>,>>9.99"))
                                      + "~nCurrent Outstanding PPS Value = " + TRIM(String(CustomerTotals.PPSValue,"->,>>>,>>9.99"))
                                      + "~nThis Order = " + TRIM(String(pdTotalExtendedValue,"->,>>>,>>9.99")) 
                                      + "~nAll Values in " + getGlobalChar("Base1Currency":u)
                                      + "~n~n".
                        ELSE ASSIGN pcErrorMsg = "CreditLimitExceedingQues":u + {&xcMsgArgDelim} + cStatementCustomer. 
                    END.
                    ELSE ASSIGN pcErrorMsg = "":u.
                END.
                ELSE DO:
                    IF pdTotalExtendedValue > Customer.CreditLimit - CustomerTotals.Balance - CustomerTotals.OpenOrderValue
                    THEN DO: 

                        IF CAN-FIND(FIRST psMessage NO-LOCK WHERE psMessage.MessageKey = "CreditLimitExceedingQues2":U
                                    AND psmessage.languageid = psUser.languageid
                                    ) THEN
                        ASSIGN pcErrorMsg = "CreditLimitExceedingQues2":u 
                                      + {&xcMsgArgDelim} + cStatementCustomer 
                                      + {&xcMsgArgDelim} 
                                      + "~n~nCredit Limit = " + TRIM(String(CustomerTotals.CreditLimit,"->,>>>,>>9.99"))
                                      + "~nAccount Balance = " + TRIM(String(CustomerTotals.Balance,"->,>>>,>>9.99"))
                                      + "~nOpen Orders = " + TRIM(String(CustomerTotals.OpenOrderValue,"->,>>>,>>9.99"))
                                      + "~nThis Order = " + TRIM(String(pdTotalExtendedValue,"->,>>>,>>9.99")) 
                                      + "~nAll Values in " + getGlobalChar("Base1Currency":u)
                                      + "~n~n".
                        ELSE
                        ASSIGN pcErrorMsg = "CreditLimitExceedingQues":u + {&xcMsgArgDelim} + cStatementCustomer. 
                    END.
                    ELSE ASSIGN pcErrorMsg = "":u.
                END.
            END. /* IF AVAILABLE CustomerTotals */

       END. /* IF AVAILABLE Customer */

  END. /* IF AVAILABLE Customer */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CheckCreditLimit2 a 
PROCEDURE CheckCreditLimit2 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input param pcCustomerCode       as char no-undo.
  def input param pdTotalExtendedValue as dec no-undo.
  def input param piOrderNumber        as INT no-undo.
  def input param pcArEntity           as char no-undo.
  def output param pcErrorMsg          as char no-undo.

  DEFINE VARIABLE cStatementCustomer AS CHARACTER NO-UNDO.
  DEFINE VARIABLE dOpenOrderValue AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dBase1LineDNIAmount AS DECIMAL    NO-UNDO.
  DEFINE VARIABLE dBase2LineDNIAmount AS DECIMAL    NO-UNDO.
  DEFINE VARIABLE dLineDNIValue AS DECIMAL    NO-UNDO.
  DEFINE VARIABLE dTotalBase1DNIAmount AS DECIMAL    NO-UNDO.

  DEFINE VARIABLE cGlEntity            AS CHARACTER NO-UNDO.
  DEFINE VARIABLE hInvoiceLine AS HANDLE     NO-UNDO.
  DEFINE VARIABLE cEntity       AS CHARACTER NO-UNDO.  
  DEFINE VARIABLE lInterCompany AS LOGICAL     NO-UNDO.
  DEFINE VARIABLE cInterCompanyEntity AS CHARACTER   NO-UNDO.

  hInvoiceLine = requestService("InvoiceLine":u, this-procedure, "":u).

  IF cglentity = "" OR cglentity = ? 
      THEN 
      DO:
         cEntity = GetGlobalChar({&xcModEntPrefix}  + STRING({&xiModAccountReceivable})).
         FIND  ControlEntity WHERE  ControlEntity.entitycode = centity  /* change to the module you are currently in AR AP etc */
                              AND   ControlEntity.moduleid = {&xiModGeneralLedger} NO-LOCK.
         ASSIGN  cGlEntity = ControlEntity.ControlEntityCode.
      END.

  DEFINE BUFFER bCustomer FOR Customer.

  DEFINE VARIABLE lOEPPSGenCreditCheck  AS LOGICAL NO-UNDO.

  FIND OpControl WHERE OpControl.ArEntity = pcArEntity NO-LOCK NO-ERROR.

  IF AVAILABLE OpControl
  THEN ASSIGN lOEPPSGenCreditCheck = opControl.OEPPSGenCreditCheck.
  ELSE ASSIGN lOEPPSGenCreditCheck = NO.
    
  FIND Customer NO-LOCK WHERE Customer.CustomerCode = pcCustomerCode NO-ERROR.

  lInterCompany = Customer.InterCompany.
  cInterCompanyEntity = Customer.InterCompanyEntity.


  IF AVAILABLE Customer THEN 
  DO:
    ASSIGN cStatementCustomer = Customer.StatementCustomer.

    IF Customer.CustomerCode <> cStatementCustomer THEN 
      FIND Customer NO-LOCK WHERE Customer.CustomerCode = cStatementCustomer NO-ERROR.

    IF AVAILABLE Customer THEN 
    DO:
      
      IF lInterCompany THEN
          FIND CustomerTotals NO-LOCK
               WHERE CustomerTotals.CustomerCode = cStatementCustomer
               AND   CustomerTotals.GlEntity     = cInterCompanyEntity
               NO-ERROR.
      ELSE  
          FIND CustomerTotals NO-LOCK
               WHERE CustomerTotals.CustomerCode = cStatementCustomer
               AND   CustomerTotals.GlEntity     = cGlEntity
               NO-ERROR.

      IF AVAILABLE CustomerTotals THEN 
      DO:
        dOpenOrderValue = 0.0.
/*
        FOR EACH bcustomer WHERE bcustomer.statementcustomer = customer.customercode NO-LOCK:   
          FOR EACH order OF bcustomer NO-LOCK 
              WHERE Order.ArEntity = pcArEntity:

           /*   AND   Order.ordernumber <> piOrderNumber:      */


            IF Order.OrderNumber = piOrderNumber THEN NEXT.

            dOpenOrderValue = dOpenOrderValue + order.base1openvalue.
                FOR EACH OrderLine WHERE OrderLine.ArEntity = Order.ArEntity
                                     AND Orderline.OrderNumber = Order.OrderNumber NO-LOCK:
                    /* work out the value of the qty despatched not invoiced (DNI) */
                    run OpenValueCalculation IN hInvoiceLine (input  0, 
                                                                  input  0,
                                                                  input  OrderLine.DespatchedNotInvoiced, 
                                                                  input  OrderLine.BookingAmount,
                                                                  input  OrderLine.UomCode,
                                                                  input  Order.OrderDate, 
                                                                  input  Order.CurrencyCode,
                                                                  input  Order.CustomerCode,
                                                                  input  Order.ExchangeRate1,
                                                                  input  Order.ExchangeRate2,
                                                                  input  OrderLine.PriceConversionFactor,
                                                                  output dLineDNIValue,  
                                                                  output dBase1LineDNIAmount,
                                                                  output dBase2LineDNIAmount).

                    dTotalBase1DNIAmount = dTotalBase1DNIAmount + dBase1LineDNIAmount.
                END.
          END.
        END.  */
        FIND order WHERE order.ArEntity = pcArEntity
                     AND order.ordernumber = piOrderNumber
                   NO-LOCK NO-ERROR.
        
        IF AVAILABLE order
        THEN dOpenOrderValue = order.Base1OpenValue. /*already part of customertotals openvalue*/
        ELSE dOpenOrderValue = 0.
        IF lOEPPSGenCreditCheck
        THEN DO:
            IF pdTotalExtendedValue > CustomerTotals.CreditLimit - CustomerTotals.Balance - CustomerTotals.PPSValue 
            THEN DO: 
                IF CAN-FIND(FIRST psMessage NO-LOCK WHERE psMessage.MessageKey = "CreditLimitExceedingQues2":U
                            AND psmessage.languageid = psUser.languageid)
                THEN ASSIGN pcErrorMsg = "CreditLimitExceedingQues2":u + {&xcMsgArgDelim} + cStatementCustomer 
                                         + {&xcMsgArgDelim} 
                                         + "~n~nCredit Limit = " + TRIM(String(CustomerTotals.CreditLimit,"->,>>>,>>9.99"))
                                         + "~nAccount Balance = " + TRIM(String(CustomerTotals.Balance,"->,>>>,>>9.99"))
                                         + "~nCurrent Outstanding PPS Value = " + TRIM(String(CustomerTotals.PPSValue,"->,>>>,>>9.99"))
                                         + "~nThis Order = " + TRIM(String(pdTotalExtendedValue,"->,>>>,>>9.99")) 
                                         + "~nAll Values in " + getGlobalChar("Base1Currency":u)
                                         + "~n~n".
                ELSE ASSIGN pcErrorMsg = "CreditLimitExceedingQues":u + {&xcMsgArgDelim} + cStatementCustomer. 
            END.
            ELSE ASSIGN pcErrorMsg = "":u.
        END.
            
        ELSE DO:
            IF pdTotalExtendedValue - dOpenOrderValue /*order value added this session*/
                > CustomerTotals.CreditLimit - CustomerTotals.Balance - CustomerTotals.OpenOrderValue 
            THEN DO: 
                IF CAN-FIND(FIRST psMessage NO-LOCK WHERE psMessage.MessageKey = "CreditLimitExceedingQues2":U
                            AND psmessage.languageid = psUser.languageid)
                THEN ASSIGN pcErrorMsg = "CreditLimitExceedingQues2":u + {&xcMsgArgDelim} + cStatementCustomer 
                                         + {&xcMsgArgDelim} 
                                         + "~n~nCredit Limit = " + TRIM(String(CustomerTotals.CreditLimit,"->,>>>,>>9.99"))
                                         + "~nAccount Balance = " + TRIM(String(CustomerTotals.Balance,"->,>>>,>>9.99"))
                                         + "~nOpen Orders (Excluding This One) = " + TRIM(String(CustomerTotals.OpenOrderValue
                                                                                                             - dOpenOrderValue 
                                                                                                              ,"->,>>>,>>9.99"))
                                         + "~nThis Order = " + TRIM(String(pdTotalExtendedValue,"->,>>>,>>9.99")) 
                                         + "~nAll Values in " + getGlobalChar("Base1Currency":u)
                                         + "~n~n".
                ELSE ASSIGN pcErrorMsg = "CreditLimitExceedingQues":u + {&xcMsgArgDelim} + cStatementCustomer. 
            END.
            ELSE ASSIGN pcErrorMsg = "":u.
        END.
      END. /* IF AVAILABLE CustomerTotals */
    END. /* IF AVAILABLE Customer */
  END. /* IF AVAILABLE Customer */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CheckOptionKitRevision a 
PROCEDURE CheckOptionKitRevision :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input param pcItemCode      as char no-undo.
  def input param pcInEntity      as char no-undo.
  def input param ptOrderLineDate as date no-undo.
  def Output param pcErrorList    as char no-undo.
  def var cArEntity as character no-undo.
  
  ASSIGN cArEntity = GetGlobalChar({&xcModEntPrefix}  + STRING({&xiModAccountReceivable})).
  find opcontrol where opcontrol.arentity = cArEntity no-lock.
  find itemStock where itemStock.InEntity = pcInEntity
              and itemStock.ItemCode = pcItemCode 
              and itemstock.warehousecode = opcontrol.defaultwarehouse no-lock no-error.

  if itemStock.itemOrigin = "k":u then
  do:
    find last revision where revision.InEntity  = pcInEntity                     
                         and revision.ItemCode  = pcItemCode                       
                         and revision.Effective le ptOrderLineDate
                         and revision.Expiry    gt ptOrderLineDate no-lock no-error.

      if not avail(revision) then       
        pcErrorlist = "RevisionDoesNotExistsForComp":u.                   
  end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CheckRegionSegmentation a 
PROCEDURE CheckRegionSegmentation :
/*------------------------------------------------------------------------------
  Purpose:     To check if the item is allowed via Region Segmentation.
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

  DEFINE INPUT  PARAMETER pcCustomerCode AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER pcInEntity     AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER pcItemCode     AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER ptRequestDate  AS DATE      NO-UNDO.
  DEFINE INPUT  PARAMETER plWarningsOnly AS LOGICAL   NO-UNDO. /* TRUE = Warnings only, FALSE = Errors and Warnings */
  DEFINE OUTPUT PARAMETER pcErrorList    AS CHARACTER NO-UNDO.
  DEFINE OUTPUT PARAMETER pcWarningList  AS CHARACTER NO-UNDO.

  DEFINE VARIABLE cGenericItemCode       AS CHARACTER NO-UNDO.

  ASSIGN pcErrorList   = "":u
         pcWarningList = "":u.

  FIND Customer NO-LOCK
       WHERE Customer.CustomerCode = pcCustomerCode
       NO-ERROR.

  IF NOT AVAILABLE Customer THEN RETURN.

  IF Customer.RegionCode = "":u THEN RETURN.

  FIND ITEM NO-LOCK
       WHERE ITEM.InEntity = pcInEntity
       AND   ITEM.ItemCode = pcItemCode
       NO-ERROR.

  IF NOT AVAILABLE ITEM THEN RETURN.

  ASSIGN cGenericItemCode = "":u.

  FIND ProductGroup NO-LOCK
       WHERE ProductGroup.ProdGroup = ITEM.ProdGroup
       NO-ERROR.

  IF AVAILABLE ProductGroup
  THEN DO:
       IF ProductGroup.AttributedGroup = YES
       THEN ASSIGN cGenericItemCode = SUBSTRING(pcItemCode,1,ProductGroup.AttributeLength).
  END.
  
  IF cGenericItemCode <> "":u
  THEN DO:

   /* Region Segment Expiry date */
       IF CAN-FIND(FIRST RegionSegment NO-LOCK
                   WHERE RegionSegment.InEntity      = pcInEntity
                   AND   RegionSegment.ItemCode      = cGenericItemCode
                   AND   RegionSegment.RegionCode    = Customer.RegionCode
                   /* 658297 */                        
                   AND   RegionSegment.EffectiveDate <= TODAY)
       THEN DO:
            IF NOT plWarningsOnly THEN
            ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                               + "GenericRegionClosed":u.
       END.

       
       /* // Check the generic item against the start date for the RegionSegment also (657442) */

       IF pcErrorList = "":u THEN DO:
           FIND FIRST RegionSegment 
                       WHERE RegionSegment.InEntity   = pcInEntity
                       AND   RegionSegment.ItemCode   = cGenericItemCode
                       AND   RegionSegment.RegionCode = Customer.RegionCode
                       AND   RegionSegment.StartDate  > ptRequestDate 
                       NO-LOCK NO-ERROR.
           IF AVAILABLE RegionSegment THEN DO:
               IF NOT plWarningsOnly THEN
               ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                    + "GenericRegionStartClosed":u 
                                    + {&xcMsgArgDelim} + STRING(ptRequestDate) 
                                    + {&xcMsgArgDelim} + STRING(RegionSegment.StartDate).
           END.
       END.

  END.
  IF pcErrorList = "":u
  THEN DO:
       IF CAN-FIND(FIRST RegionSegment NO-LOCK
                   WHERE RegionSegment.InEntity      = pcInEntity
                   AND   RegionSegment.ItemCode      = pcItemCode
                   AND   RegionSegment.RegionCode    = Customer.RegionCode
                   AND   RegionSegment.EffectiveDate <= TODAY
                   )
       THEN DO:
            IF NOT plWarningsOnly THEN
            ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                               + "ItemRegionClosed":u.
       END.

       /* Region Segment Start/Effective date */
       IF pcErrorList = "":u THEN
       DO:
           FIND FIRST RegionSegment NO-LOCK
                       WHERE RegionSegment.InEntity   = pcInEntity
                       AND   RegionSegment.ItemCode   = pcItemCode
                       AND   RegionSegment.RegionCode = Customer.RegionCode
                       AND   RegionSegment.StartDate  > ptRequestDate
               NO-ERROR.

           IF AVAILABLE RegionSegment 
           THEN DO:
               IF NOT plWarningsOnly THEN
               ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                    + "ItemRegionStartClosed":u 
                                    + {&xcMsgArgDelim} + STRING(ptRequestDate) 
                                    + {&xcMsgArgDelim} + STRING(RegionSegment.StartDate) 
                                    .
           END.
       END.
  END.

  IF pcErrorList = "":u AND cGenericItemCode <> "":u AND pcItemCode = cGenericItemCode
  THEN DO:
        
       /* Region Segment Expiry date */
       IF CAN-FIND(FIRST RegionSegment NO-LOCK
                   WHERE RegionSegment.InEntity      = pcInEntity
                   AND   RegionSegment.ItemCode      = cGenericItemCode
                   AND   RegionSegment.RegionCode    = Customer.RegionCode
                   AND   RegionSegment.EffectiveDate <= TODAY  
                   )
       THEN DO:
           IF NOT plWarningsOnly THEN
           ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                               + "GenericRegionClosed":u.
       END.

       /* Region Segment Start/Effective date */
       IF pcErrorList = "":u THEN
       DO:
           FIND FIRST RegionSegment NO-LOCK
               WHERE RegionSegment.InEntity   = pcInEntity
               AND   RegionSegment.ItemCode   = cGenericItemCode
               AND   RegionSegment.RegionCode = Customer.RegionCode
               AND   RegionSegment.StartDate  > ptRequestDate
               NO-ERROR.

           IF AVAILABLE RegionSegment 
           THEN DO:
               IF NOT plWarningsOnly THEN
               ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                    + "GenericRegionStartClosed":u 
                                    + {&xcMsgArgDelim} + STRING(ptRequestDate) 
                                    + {&xcMsgArgDelim} + STRING(RegionSegment.StartDate) 
                                    .
           END.
       END.
  END.
  
  IF pcErrorList = "":u AND cGenericItemCode <> "":u AND pcItemCode = cGenericItemCode
  THEN DO:
       IF CAN-FIND(FIRST RegionSegment NO-LOCK
                   WHERE RegionSegment.InEntity   =      pcInEntity
                   AND   RegionSegment.ItemCode   BEGINS cGenericItemCode
                   AND   RegionSegment.ItemCode   <>     cGenericItemCode
                   AND   RegionSegment.RegionCode =      Customer.RegionCode
                   AND   (RegionSegment.EffectiveDate < TODAY OR
                          RegionSegment.StartDate > ptRequestDate)
                   )
       THEN DO:
            ASSIGN pcWarningList = pcWarningList + (IF pcWarningList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                 + "ItemRegionWarning":u.
       END.
  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CheckRegionSegmentCopyDates a 
PROCEDURE CheckRegionSegmentCopyDates :
/*------------------------------------------------------------------------------
  Purpose:     To check if the item is allowed via Region Segmentation.
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

  DEFINE INPUT  PARAMETER pcCustomerCode AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER pcInEntity     AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER pcItemCode     AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER ptRequestDate  AS DATE      NO-UNDO.
  DEFINE INPUT  PARAMETER piLineNumber   AS INT       NO-UNDO.
  DEFINE OUTPUT PARAMETER pcErrorList    AS CHARACTER NO-UNDO.
  DEFINE OUTPUT PARAMETER pcWarningList  AS CHARACTER NO-UNDO.

  DEFINE VARIABLE cGenericItemCode       AS CHARACTER NO-UNDO.

  ASSIGN pcErrorList   = "":u
         pcWarningList = "":u.

  FIND Customer NO-LOCK
       WHERE Customer.CustomerCode = pcCustomerCode
       NO-ERROR.

  IF NOT AVAILABLE Customer THEN RETURN.

  IF Customer.RegionCode = "":u THEN RETURN.

  FIND ITEM NO-LOCK
       WHERE ITEM.InEntity = pcInEntity
       AND   ITEM.ItemCode = pcItemCode
       NO-ERROR.

  IF NOT AVAILABLE ITEM THEN RETURN.

  ASSIGN cGenericItemCode = "":u.

  FIND ProductGroup NO-LOCK
       WHERE ProductGroup.ProdGroup = ITEM.ProdGroup
       NO-ERROR.

  IF AVAILABLE ProductGroup
  THEN DO:
       IF ProductGroup.AttributedGroup = YES
       THEN ASSIGN cGenericItemCode = SUBSTRING(pcItemCode,1,ProductGroup.AttributeLength).
  END.

  IF pcItemCode <> "":u
  THEN DO:
       /* Don't carry out expiry date check on Copy Promise Req function for existing order
          lines.
          
       /* Region Segment Expiry date */
       FIND FIRST RegionSegment NO-LOCK
           WHERE RegionSegment.InEntity      = pcInEntity
           AND   RegionSegment.ItemCode      = pcItemCode
           AND   RegionSegment.RegionCode    = Customer.RegionCode
           AND   RegionSegment.EffectiveDate < TODAY
           NO-ERROR.
       IF AVAILABLE RegionSegment
       THEN DO:
            ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                + "ItemRegionClosed2":u
                                + {&xcMsgArgDelim} + STRING(TODAY) 
                                + {&xcMsgArgDelim} + STRING(RegionSegment.EffectiveDate)
                                + {&xcMsgArgDelim} + pcItemCode                   
                                + {&xcMsgArgDelim} + STRING(piLineNumber)
                                .
       END.
       */

       /* Region Segment Start/Effective date */
       IF pcErrorList = "":u THEN
       DO:
           FIND FIRST RegionSegment NO-LOCK
                       WHERE RegionSegment.InEntity   = pcInEntity
                       AND   RegionSegment.ItemCode   = pcItemCode
                       AND   RegionSegment.RegionCode = Customer.RegionCode
                       AND   RegionSegment.StartDate  > ptRequestDate
               NO-ERROR.

           IF AVAILABLE RegionSegment 
           THEN DO:
               ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                    + "ItemRegionStartClosed2":u 
                                    + {&xcMsgArgDelim} + STRING(ptRequestDate) 
                                    + {&xcMsgArgDelim} + STRING(RegionSegment.StartDate) 
                                    + {&xcMsgArgDelim} + pcItemCode                   
                                    + {&xcMsgArgDelim} + STRING(piLineNumber)
                                    .
           END.
       END.
  END.

  IF cGenericItemCode <> "":u AND pcErrorList = "":u
  THEN DO:
        
       /* Don't carry out expiry date check on Copy Promise Req function for existing order
          lines.
          
       /* Region Segment Expiry date */
       FIND FIRST RegionSegment NO-LOCK
                   WHERE RegionSegment.InEntity      = pcInEntity
                   AND   RegionSegment.ItemCode      = cGenericItemCode
                   AND   RegionSegment.RegionCode    = Customer.RegionCode
                   AND   RegionSegment.EffectiveDate < TODAY  
            NO-ERROR.
       IF AVAILABLE RegionSegment 
       THEN DO:
           ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                + "GenericRegionClosed2":u
                                + {&xcMsgArgDelim} + STRING(TODAY) 
                                + {&xcMsgArgDelim} + STRING(RegionSegment.EffectiveDate)
                                + {&xcMsgArgDelim} + cGenericItemCode
                                + {&xcMsgArgDelim} + STRING(piLineNumber)
                                .
       END.
       */

       /* Region Segment Start/Effective date */
       IF pcErrorList = "":u THEN
       DO:
           FIND FIRST RegionSegment NO-LOCK
               WHERE RegionSegment.InEntity   = pcInEntity
               AND   RegionSegment.ItemCode   = cGenericItemCode
               AND   RegionSegment.RegionCode = Customer.RegionCode
               AND   RegionSegment.StartDate  > ptRequestDate
               NO-ERROR.

           IF AVAILABLE RegionSegment 
           THEN DO:
               ASSIGN pcErrorList = pcErrorList + (IF pcErrorList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                    + "GenericRegionStartClosed2":u 
                                    + {&xcMsgArgDelim} + STRING(ptRequestDate) 
                                    + {&xcMsgArgDelim} + STRING(RegionSegment.StartDate)
                                    + {&xcMsgArgDelim} + cGenericItemCode
                                    + {&xcMsgArgDelim} + STRING(piLineNumber)
                                    .
           END.
       END.
  END.

  IF pcErrorList = "":u AND cGenericItemCode <> "":u AND pcItemCode = cGenericItemCode
  THEN DO:
       IF CAN-FIND(FIRST RegionSegment NO-LOCK
                   WHERE RegionSegment.InEntity   =      pcInEntity
                   AND   RegionSegment.ItemCode   BEGINS cGenericItemCode
                   AND   RegionSegment.ItemCode   <>     cGenericItemCode
                   AND   RegionSegment.RegionCode =      Customer.RegionCode
                   AND   (RegionSegment.EffectiveDate < TODAY OR
                          RegionSegment.StartDate > ptRequestDate)
                   )
       THEN DO:
            ASSIGN pcWarningList = pcWarningList + (IF pcWarningList = "":u THEN "":u ELSE {&xcMsgDelimiter})
                                 + "ItemRegionWarning":u.
       END.
  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CheckSalesOrder a 
PROCEDURE CheckSalesOrder :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER pcArEntity      AS CHARACTER    NO-UNDO.
DEFINE INPUT  PARAMETER piOrderNumber   AS INTEGER      NO-UNDO.
DEFINE INPUT  PARAMETER piLineNumber    AS INTEGER      NO-UNDO.
DEFINE INPUT  PARAMETER pcItemCode      AS CHARACTER    NO-UNDO.
DEFINE INPUT  PARAMETER pcWarehouseCode AS CHARACTER    NO-UNDO.
DEFINE OUTPUT PARAMETER pcError         AS CHARACTER    NO-UNDO.

DEFINE VARIABLE cText       AS CHARACTER    NO-UNDO.

FIND FIRST Order
    WHERE Order.ArEntity        = pcArEntity
      AND Order.OrderNumber     = piOrderNumber
    NO-LOCK NO-ERROR.
IF NOT AVAILABLE Order THEN
DO:
    cText = " Sales Order Number " + STRING(piOrderNumber).
    pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) + 
              "Invalid":u + {&xcMsgArgDelim} + cText.
    RETURN.
END.
ELSE DO:
    IF Order.StatusCode = "C":u THEN
    DO:
        pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) + 
              "SalesOrderComplete":u.
        RETURN.
    END.
    FIND FIRST PpsHeader 
        WHERE PpsHeader.ArEntity = pcArEntity
          AND   PpsHeader.OrderNumber = piOrderNumber
          AND   PpsHeader.PpsStatus <> "A":u
          AND   PpsHeader.PpsStatus <> "I":u 
          NO-LOCK NO-ERROR.
    IF AVAILABLE PpsHeader THEN
    DO:
        ASSIGN pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) +
            "CannotBe":u + {&xcMsgArgDelim} + "Sales Order"
            + {&xcMsgArgDelim} + "selected. PPS quantities exist".
        RETURN.
    END.
    FIND FIRST Despatch
        WHERE Despatch.ArEntity = pcArEntity
          AND Despatch.OrderNumber = piOrderNumber
          AND Despatch.CreateInvoice = FALSE
        NO-LOCK NO-ERROR.
    IF AVAILABLE Despatch THEN
    DO:
         ASSIGN pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) +
            "CannotBe":u + {&xcMsgArgDelim} + "Sales Order"
            + {&xcMsgArgDelim} + "selected. Despatch quantities exist".
         RETURN.
    END.
END.
    
FIND FIRST OrderLine
    WHERE OrderLine.ArEntity    = pcArEntity
      AND OrderLine.OrderNumber = piOrderNumber
      AND OrderLine.LineNumber  = piLineNumber
    NO-LOCK NO-ERROR.
IF NOT AVAILABLE OrderLine THEN
DO:
    cText = " Sales Order Line" + STRING(piOrderNumber) + " ":u + STRING(piLineNumber) .
    pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) + 
              "Invalid":u + {&xcMsgArgDelim} + cText.
    RETURN.
END.
ELSE DO:
    IF OrderLine.WarehouseCode <> pcWarehouseCode THEN
    DO:
        pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) + 
                "CannotBe":u + {&xcMsgArgDelim} + "Sales Order Line Warehouse"
                + {&xcMsgArgDelim} + "different to the stock transaction".
        RETURN.
    END.
    IF OrderLine.ItemCode <> pcItemCode THEN
    DO:
        pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) + 
                "CannotBe":u + {&xcMsgArgDelim} + "Sales Order Line ItemCode"
                + {&xcMsgArgDelim} + "different to the stock transaction".
        RETURN.
    END.
    IF OrderLine.QuantityOpenOrdered <= 0 THEN
    DO:
        pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) + 
                "CannotBe":u + {&xcMsgArgDelim} + "Sales Order Line"
                + {&xcMsgArgDelim} + "selected. No open quantity exists".
        RETURN.
    END.
    IF OrderLine.QuantityAllocated <> 0 THEN
    DO:
        pcError = pcError + (IF pcError = "":u THEN "":u ELSE {&xcMsgDelimiter}) + 
                "CannotBe":u + {&xcMsgArgDelim} + "Sales Order Line"
                + {&xcMsgArgDelim} + "selected. Allocated quantities exist".
        RETURN.
    END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE createKitComponents a 
PROCEDURE createKitComponents :
/*------------------------------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none> 
  Notes: gttMasterKitOrderLineV1 contains One Kit Header Record.
         gttKitOrderLineV1 contains Kit Header + All Components records.     
--------------------------------------------------------------------------------------------------------*/
  def input  parameter piNextOrderLineNumber as int no-undo.
  def input  parameter table for gttMasterKitOrderLineV1.  
  def output parameter table for gttKitOrderLineV1.  
  def output parameter pcErrorMsg as char no-undo.

  def var iNextOrderLineNumber  as int  no-undo.
  def var cKitItemWarehouseCode as char no-undo.
  def var dConversionFactor     as decimal decimals 6 no-undo.
  def var cLocalValues          as char no-undo.
  def var cAmountPercent        as char no-undo.
  def var cTaxCode              as char no-undo.
  def var cTempCustomerQuantityOnOrder as char no-undo.
  DEFINE VARIABLE dGrossPrice AS DECIMAL     NO-UNDO.

  def buffer bRevision for Revision.

  iNextOrderLineNumber = piNextOrderLineNumber. /* next OrderLine Number */

  empty temp-table gttKitOrderLineV1.
  find first gttMasterKitOrderLineV1 no-lock no-error.
  assertNoError().

  /* Copy Kit Header Line to the temp table */  
  create gttKitOrderLineV1.
  buffer-copy gttMasterKitOrderLineV1 to gttKitOrderLineV1.

  /* check Exists Item Code */ 
  find first Item where Item.InEntity = gttMasterKitOrderLineV1.InEntity
                    and Item.ItemCode = gttMasterKitOrderLineV1.ItemCode no-lock no-error. 
  if not avail(Item) then
  do:
    pcErrorMsg = "ItemCodeDoesExists":u.
    return.
  end.

    /* check Exists Item Code */ 
    find first ItemStock where ItemStock.InEntity = gttMasterKitOrderLineV1.InEntity
                    and ItemStock.ItemCode = gttMasterKitOrderLineV1.ItemCode 
                    and ItemStock.WarehouseCode = gttMasterKitOrderLineV1.WarehouseCode 
                    no-lock no-error. 


  find last revision where revision.InEntity  = gttMasterKitOrderLineV1.InEntity                     
                       and revision.ItemCode  = gttMasterKitOrderLineV1.ItemCode                       
                       and revision.Effective le gttMasterKitOrderLineV1.RequestDate
                       and revision.Expiry    GE gttMasterKitOrderLineV1.RequestDate 
                       no-lock no-error.        

  if not avail(revision) then                     
  do:
  
    pcErrorMsg = "RevisionDoesNotExists":u.
    return.
  end.


  find first uom where uom.uomCode = gttMasterKitOrderLineV1.uomCode no-lock no-error.
  if not avail(uom) then
  do:
    pcErrorMsg = "InvalidUomCode":u.
    return.
  end.

  /* Creating Components Order Lines */
  for each component where component.InEntity  = revision.Inentity         
                       and component.ItemCode  = revision.ItemCode           
                       and component.Type      = revision.Type              
                       and component.Effective = revision.Effective no-lock:

    /* Check Component Code Exists */ 
    find first Item where Item.InEntity = component.InEntity
                      and Item.ItemCode = component.component no-lock no-error. 
    if not avail(Item) then
    do:
      pcErrorMsg = "ComponentDoesNotExistInItem":u.
      return.
    end.

    if not can-find ( first itemWhs where itemWhs.InEntity      = Item.InEntity
                                      and itemWhs.ItemCode      = component.Component
                                      and itemWhs.warehouseCode = gttMasterKitOrderLineV1.WarehouseCode) then
    do:                                     
      pcErrorMsg = "InValidItemForWhsCode":u.
      return.
    end.  

    if not can-find(first ItemStock where ItemStock.InEntity      = Item.InEntity                
                                      and ItemStock.ItemCode      = component.Component                      
                                      and ItemStock.WarehouseCode = gttMasterKitOrderLineV1.WarehouseCode) then                                          
    do:                                       
      pcErrorMsg = "ComponentDoesNotExistInWarehouse".                                                      
      return.
    end.                                                                       
 /*
    if ItemStock.ItemOrigin = "k":u then
    do:
      if not can-find(last bRevision where bRevision.InEntity = Item.InEntity                     
                                      and bRevision.ItemCode  = Item.ItemCode
                                      and bRevision.Effective le gttMasterKitOrderLineV1.OrderDate
                                      and bRevision.Expiry    gt gttMasterKitOrderLineV1.OrderDate ) then
        pcErrorMsg = "RevisionDoesNotExists".                                                      
        return.
    end.
   */
    /* yet to be implemented - current version can only price by kit header------------------->
    
    /*price by kit header or kit component - logical price by kit = true, price by item = false*/
     IF Revision.PriceBy = FALSE THEN
         ASSIGN dGrossPrice = 0.
     else do:
        price by kit components
     end.
     
    <---------------------------------------------------------------------------------------*/
    ASSIGN dGrossPrice = 0.
    /****************************************************************************************/

    create gttKitOrderLineV1.                                                     
    assign gttKitOrderLineV1.lineNumber          = iNextOrderLineNumber                                   
           gttKitOrderLineV1.kitheaderline       = gttMasterKitOrderLineV1.LineNumber         
           gttKitOrderLineV1.Genericline         = iNextOrderLineNumber
           gttKitOrderLineV1.ItemCode            = component.component                        
           gttKitOrderLineV1.warehouseCode       = gttMasterKitOrderLineV1.WarehouseCode 
           gttKitOrderLineV1.CurrencyCode        = gttMasterKitOrderLineV1.CurrencyCode
           gttKitOrderLineV1.KitCode             = component.ItemCode
           gttKitOrderLineV1.OriginalItemCode    = component.Component
           gttKitOrderLineV1.PrintLineOn         = component.PrintLineOn
           gttKitOrderLineV1.description         = Item.description                          
           gttKitOrderLineV1.uomcode             = Item.uomcode
           gttKitOrderLineV1.Priceuomcode        = Item.uomcode
           gttKitOrderLineV1.BaseUomcode         = Item.uomcode
           gttKitOrderLineV1.arentity            = gttMasterKitOrderLineV1.arentity                             
           gttKitOrderLineV1.InEntity            = gttMasterKitOrderLineV1.InEntity   
           gttKitOrderLineV1.Orderdate           = gttMasterKitOrderLineV1.Orderdate
           gttKitOrderLineV1.OrderNumber         = gttMasterKitOrderLineV1.OrderNumber                               
           gttKitOrderLineV1.requestdate         = gttMasterKitOrderLineV1.requestdate                         
           gttKitOrderLineV1.CommissionType      = gttMasterKitOrderLineV1.CommissionType                            
           gttKitOrderLineV1.CommissionRate      = gttMasterKitOrderLineV1.CommissionRate                            
           gttKitOrderLineV1.warehouseCode       = gttMasterKitOrderLineV1.warehouseCode                       
           gttKitOrderLineV1.requestdate         = gttMasterKitOrderLineV1.requestdate                 
           gttKitOrderLineV1.salehistory         = gttMasterKitOrderLineV1.salehistory              
           gttKitOrderLineV1.PrintLineOn         = Component.PrintLineOn                
           gttKitOrderLineV1.IncludePrice        = gttMasterKitOrderLineV1.IncludePrice                  
           gttKitOrderLineV1.grossprice          = dGrossPrice                
           gttKitOrderLineV1.CustomerDiscount    = gttMasterKitOrderLineV1.CustomerDiscount                    
           gttKitOrderLineV1.CommissionType      = gttMasterKitOrderLineV1.CommissionType                   
           gttKitOrderLineV1.CommissionRate      = gttMasterKitOrderLineV1.CommissionRate                   
           gttKitOrderLineV1.AmountPercent       = gttMasterKitOrderLineV1.AmountPercent                        
           gttKitOrderLineV1.VolumeDiscount      = gttMasterKitOrderLineV1.VolumeDiscount                
           gttKitOrderLineV1.BookingAmount       = gttMasterKitOrderLineV1.BookingAmount                
           gttKitOrderLineV1.TaxableAmount       = gttMasterKitOrderLineV1.TaxableAmount                
           gttKitOrderLineV1.TaxLevel            = gttMasterKitOrderLineV1.TaxLevel
           gttKitOrderLineV1.PromiseDate         = gttMasterKitOrderLineV1.PromiseDate                
           gttKitOrderLineV1.RequestDate         = gttMasterKitOrderLineV1.RequestDate                
           gttKitOrderLineV1.RevisedPromiseDate  = gttMasterKitOrderLineV1.RevisedPromiseDate                
           gttKitOrderLineV1.taxable             = gttMasterKitOrderLineV1.taxable                     
           gttKitOrderLineV1.cost                = gttMasterKitOrderLineV1.cost
           gttKitOrderLineV1.RowInfo             = gttMasterKitOrderLineV1.RowInfo
           gttKitOrderLineV1.QuantityPerKit      = Component.QuantityPer
           gttKitOrderLineV1.Attrib1             = "Not Required":u
           gttKitOrderLineV1.Attrib2             = "Not Required":u
           gttKitOrderLineV1.Attrib3             = "Not Required":u.

   /* do we have first attribute */
   FIND FIRST Attribute
       WHERE Attribute.ProdGroup = ITEM.ProdGroup
       NO-LOCK NO-ERROR.
   IF AVAILABLE Attribute THEN
   DO:
       gttKitOrderLineV1.Attrib1 = "Please Choose":u.
       /* do we have a second attribute */
       FIND NEXT Attribute
           WHERE Attribute.ProdGroup = ITEM.ProdGroup
           NO-LOCK NO-ERROR.
       IF AVAILABLE Attribute THEN
       DO:
           gttKitOrderLineV1.Attrib2 = "Please Choose":u.
           /* do we have a third attribute */
           FIND NEXT Attribute
               WHERE Attribute.ProdGroup = ITEM.ProdGroup
               NO-LOCK NO-ERROR.
           IF AVAILABLE Attribute THEN
           DO:
               gttKitOrderLineV1.Attrib3 = "Please Choose":u.
           END.
       END.
   END.

    IF ITEM.GenericItem THEN
        ASSIGN gttKitOrderLineV1.GenericItemLine = TRUE.
    ELSE gttKitOrderLineV1.GenericItemLine = FALSE.


    if gttMasterKitOrderLineV1.CustomerQuantityOnOrder gt 0 then  
      gttKitOrderLineV1.CustomerQuantityOnOrder = gttMasterKitOrderLineV1.CustomerQuantityOnOrder * 
                                                  gttKitOrderLineV1.QuantityPerKit.                       

    ConvertToUomQty(input  gttKitOrderLineV1.CustomerQuantityOnOrder,  
                    input  gttKitOrderLineV1.UomCode,
                    output cTempCustomerQuantityOnOrder).

    gttKitOrderLineV1.cCustomerQuantityOnOrder = decimal(cTempCustomerQuantityOnOrder).

    if Item.UomCode ne gttKitOrderLineV1.UomCode then
    do:
      getUomConversionFactor (input  gttKitOrderLineV1.UomCode,
                              input  Item.UomCode,
                              output dConversionFactor).

      ConvertFromCustomerQtyToBaseQty(input  cTempCustomerQuantityOnOrder,  
                                      input  Item.UomCode,
                                      input  dConversionFactor,
                                      output gttKitOrderLineV1.QuantityOpenOrder).
                        

      ConvertToUomQty(input  gttKitOrderLineV1.QuantityOpenOrder,  
                      input  gttKitOrderLineV1.UomCode,
                      output gttKitOrderLineV1.cQuantityOpenOrder).
    end.
    else do:
      assign gttKitOrderLineV1.cQuantityOpenOrder = string(gttKitOrderLineV1.cCustomerQuantityOnOrder)
             gttKitOrderLineV1.QuantityOpenOrder  = gttKitOrderLineV1.CustomerQuantityOnOrder.
    end.

    if revision.HistoryBy = yes then
      gttKitOrderLineV1.SaleHistory = yes.
    else
      gttKitOrderLineV1.SaleHistory = no.
     

    if revision.PriceBy = yes then
      gttKitOrderLineV1.IncludePrice = yes.
    else
      gttKitOrderLineV1.IncludePrice = no.

    if not revision.priceBy then 
      gttKitOrderLineV1.IncludePrice = yes.   
    else 
      gttKitOrderLineV1.IncludePrice = no.                             

    iNextOrderLineNumber = iNextOrderLineNumber + 1. /* Increment Order Line Number */
  end.
                                                                             

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CreateLinkComponents a 
PROCEDURE CreateLinkComponents :
/*------------------------------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none> 
  Notes: gttMasterLinkOrderLineV1 contains One Kit Header Record.
         gttLinkOrderLineV1 contains Kit Header + All Components records.     
--------------------------------------------------------------------------------------------------------*/
  def input  parameter piNextOrderLineNumber as int no-undo.
  def input  parameter table for gttMasterLinkOrderLineV1.  
  def output parameter table for gttLinkOrderLineV1.  
  def output parameter pcErrorMsg as char no-undo.

  def var iNextOrderLineNumber  as int  no-undo.
  def var cKitItemWarehouseCode as char no-undo.
  def var dConversionFactor     as decimal decimals 6 no-undo.
  def var cLocalValues          as char no-undo.
  def var cAmountPercent        as char no-undo.
  def var cTaxCode              as char no-undo.
  def var cTempCustomerQuantityOnOrder as char no-undo.


  iNextOrderLineNumber = piNextOrderLineNumber. /* next OrderLine Number */

  empty temp-table gttLinkOrderLineV1.
  find first gttMasterLinkOrderLineV1 no-lock no-error.
  assertNoError().

  /* Copy Kit Header Line to the temp table */  
/*   create gttLinkOrderLineV1.                                  */
/*   buffer-copy gttMasterLinkOrderLineV1 to gttLinkOrderLineV1. */
/*                                                               */
  /* check Exists Item Code */ 
  find first Item where Item.InEntity = gttMasterLinkOrderLineV1.InEntity
                    and Item.ItemCode = gttMasterLinkOrderLineV1.ItemCode no-lock no-error. 
  if not avail(Item) then
  do:
    pcErrorMsg = "ItemCodeDoesExists":u.
    return.
  end.

 
  find first uom where uom.uomCode = gttMasterLinkOrderLineV1.uomCode no-lock no-error.
  if not avail(uom) then
  do:
    pcErrorMsg = "InvalidUomCode":u.
    return.
  end.

  /* Creating Components Order Lines */
  for each ItemLinks where ItemLinks.InEntity      = gttMasterLinkOrderLineV1.Inentity 
                       and ItemLinks.CustomerCode  = gttMasterLinkOrderLineV1.CustomerCode       
                       and ItemLinks.ItemCode      = gttMasterLinkOrderLineV1.ItemCode
                       AND ItemLinks.ACTIVE = TRUE no-lock: 

    /* Check Component Code Exists */ 
    find first Item where Item.InEntity = ItemLinks.InEntity
                      and Item.ItemCode = ItemLinks.LinkedItemCode no-lock no-error. 
    if not avail(Item) then
    do:
      pcErrorMsg = "LinkItemDoesNotExist":u.
      return.
    end.

    if not can-find ( first itemWhs where itemWhs.InEntity      = Item.InEntity
                                      and itemWhs.ItemCode      = ItemLinks.LinkedItemCode
                                      and itemWhs.warehouseCode = gttMasterLinkOrderLineV1.WarehouseCode) then
    do:                                     
      pcErrorMsg = "InValidItemForWhsCode":u.
      return.
    end.  

    if not can-find(first ItemStock where ItemStock.InEntity      = Item.InEntity                
                                      and ItemStock.ItemCode      = ItemLinks.LinkedItemCode                      
                                      and ItemStock.WarehouseCode = gttMasterLinkOrderLineV1.WarehouseCode) then                                          
    do:                                       
      pcErrorMsg = "LinkItemDoesNotExistInWarehouse".                                                      
      return.
    end.                                                                       

   
    create gttLinkOrderLineV1.                                                     
    assign gttLinkOrderLineV1.lineNumber          = iNextOrderLineNumber                                   
           gttLinkOrderLineV1.kitheaderline       = 0         
           gttLinkOrderLineV1.Genericline         = iNextOrderLineNumber
           gttLinkOrderLineV1.CustomerCode        = gttMasterLinkOrderLineV1.CustomerCode 
           gttLinkOrderLineV1.ItemCode            = ItemLinks.LinkedItemCode                        
           gttLinkOrderLineV1.warehouseCode       = gttMasterLinkOrderLineV1.WarehouseCode 
           gttLinkOrderLineV1.CurrencyCode        = gttMasterLinkOrderLineV1.CurrencyCode
           gttLinkOrderLineV1.KitCode             = ""
           gttLinkOrderLineV1.OriginalItemCode    = ItemLinks.ItemCode
           gttLinkOrderLineV1.PrintLineOn         = ""
           gttLinkOrderLineV1.description         = Item.description                          
           gttLinkOrderLineV1.uomcode             = gttMasterLinkOrderLineV1.uomcode
           gttLinkOrderLineV1.Priceuomcode        = gttMasterLinkOrderLineV1.Priceuomcode
           gttLinkOrderLineV1.BaseUomcode         = gttMasterLinkOrderLineV1.BaseUomcode
           gttLinkOrderLineV1.arentity            = gttMasterLinkOrderLineV1.arentity                             
           gttLinkOrderLineV1.InEntity            = gttMasterLinkOrderLineV1.InEntity   
           gttLinkOrderLineV1.Orderdate           = gttMasterLinkOrderLineV1.Orderdate
           gttLinkOrderLineV1.OrderNumber         = gttMasterLinkOrderLineV1.OrderNumber                               
           gttLinkOrderLineV1.requestdate         = gttMasterLinkOrderLineV1.requestdate                         
           gttLinkOrderLineV1.CommissionType      = gttMasterLinkOrderLineV1.CommissionType                            
           gttLinkOrderLineV1.CommissionRate      = gttMasterLinkOrderLineV1.CommissionRate                            
           gttLinkOrderLineV1.warehouseCode       = gttMasterLinkOrderLineV1.warehouseCode                       
           gttLinkOrderLineV1.requestdate         = gttMasterLinkOrderLineV1.requestdate                 
           gttLinkOrderLineV1.salehistory         = gttMasterLinkOrderLineV1.salehistory              
           gttLinkOrderLineV1.PrintLineOn         = gttMasterLinkOrderLineV1.PrintLineOn                
           gttLinkOrderLineV1.IncludePrice        = gttMasterLinkOrderLineV1.IncludePrice                  
           gttLinkOrderLineV1.grossprice          = gttMasterLinkOrderLineV1.grossprice                
           gttLinkOrderLineV1.CustomerDiscount    = gttMasterLinkOrderLineV1.CustomerDiscount                    
           gttLinkOrderLineV1.CommissionType      = gttMasterLinkOrderLineV1.CommissionType                   
           gttLinkOrderLineV1.CommissionRate      = gttMasterLinkOrderLineV1.CommissionRate                   
           gttLinkOrderLineV1.AmountPercent       = gttMasterLinkOrderLineV1.AmountPercent                        
           gttLinkOrderLineV1.VolumeDiscount      = gttMasterLinkOrderLineV1.VolumeDiscount                
           gttLinkOrderLineV1.BookingAmount       = gttMasterLinkOrderLineV1.BookingAmount                
           gttLinkOrderLineV1.TaxableAmount       = gttMasterLinkOrderLineV1.TaxableAmount                
           gttLinkOrderLineV1.TaxLevel            = gttMasterLinkOrderLineV1.TaxLevel
           gttLinkOrderLineV1.PromiseDate         = gttMasterLinkOrderLineV1.PromiseDate                
           gttLinkOrderLineV1.RequestDate         = gttMasterLinkOrderLineV1.RequestDate                
           gttLinkOrderLineV1.RevisedPromiseDate  = gttMasterLinkOrderLineV1.RevisedPromiseDate                
           gttLinkOrderLineV1.taxable             = gttMasterLinkOrderLineV1.taxable                     
           gttLinkOrderLineV1.cost                = gttMasterLinkOrderLineV1.cost
           gttLinkOrderLineV1.RowInfo             = gttMasterLinkOrderLineV1.RowInfo
           gttLinkOrderLineV1.QuantityPerKit      = ItemLinks.QuantityPer.

       if gttMasterLinkOrderLineV1.CustomerQuantityOnOrder gt 0 then  
          gttLinkOrderLineV1.CustomerQuantityOnOrder = gttMasterLinkOrderLineV1.CustomerQuantityOnOrder * gttLinkOrderLineV1.QuantityPerKit.           
 
    ConvertToUomQty(input  gttLinkOrderLineV1.CustomerQuantityOnOrder,  
                    input  gttLinkOrderLineV1.UomCode,
                    output cTempCustomerQuantityOnOrder).

    gttLinkOrderLineV1.cCustomerQuantityOnOrder = decimal(cTempCustomerQuantityOnOrder).

    if Item.UomCode ne gttLinkOrderLineV1.UomCode then
    do:
      getUomConversionFactor (input  gttLinkOrderLineV1.UomCode,
                              input  Item.UomCode,
                              output dConversionFactor).

      ConvertFromCustomerQtyToBaseQty(input  cTempCustomerQuantityOnOrder,  
                                      input  Item.UomCode,
                                      input  dConversionFactor,
                                      output gttLinkOrderLineV1.QuantityOpenOrder).
                        

      ConvertToUomQty(input  gttLinkOrderLineV1.QuantityOpenOrder,  
                      input  gttLinkOrderLineV1.UomCode,
                      output gttLinkOrderLineV1.cQuantityOpenOrder).
    end.
    else do:
      assign gttLinkOrderLineV1.cQuantityOpenOrder = string(gttLinkOrderLineV1.cCustomerQuantityOnOrder)
             gttLinkOrderLineV1.QuantityOpenOrder  = gttLinkOrderLineV1.CustomerQuantityOnOrder.
    end.                

    iNextOrderLineNumber = iNextOrderLineNumber + 1. /* Increment Order Line Number */
  end.
                                                                   

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE exportorderdata a 
PROCEDURE exportorderdata :
/*------------------------------------------------------------------------------
  Purpose: used in Orders By Customer Report viewers to get data
  to export to excel    
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

DEFINE INPUT  PARAMETER pcFromCustomerCode  AS CHARACTER  NO-UNDO.
DEFINE INPUT  PARAMETER pcToCustomerCode    AS CHARACTER  NO-UNDO.
DEFINE INPUT  PARAMETER piFromOrderNumber   AS INTEGER    NO-UNDO.
DEFINE INPUT  PARAMETER piToOrderNumber     AS INTEGER    NO-UNDO.
DEFINE INPUT  PARAMETER pcFromWarehouseCode AS CHARACTER  NO-UNDO.
DEFINE INPUT  PARAMETER pcToWarehouseCode   AS CHARACTER  NO-UNDO.
DEFINE INPUT  PARAMETER pcSalesReps         AS CHARACTER  NO-UNDO.
DEFINE INPUT  PARAMETER ptFromRequestDate   AS DATE       NO-UNDO.
DEFINE INPUT  PARAMETER ptToRequestDate     AS DATE       NO-UNDO.
DEFINE INPUT  PARAMETER ptCancelDate        AS DATE       NO-UNDO.

DEFINE OUTPUT PARAMETER TABLE FOR xttOrderLineV1.

DEFINE VARIABLE cArEntity AS CHARACTER   NO-UNDO.

ASSIGN cArEntity = GetGlobalChar({&xcModEntPrefix} + STRING({&xiModOrderProcessing})).


  FOR EACH Order NO-LOCK

    WHERE Order.ArEntity = cArEntity
    AND   Order.CustomerCode >= pcFromCustomerCode
    AND   Order.CustomerCode <= pcToCustomerCode
    AND   Order.OrderNumber  >= piFromOrderNumber
    AND   Order.OrderNumber  <= piToOrderNumber
    AND   Order.RequestDate  >= ptFromRequestDate
    AND   Order.RequestDate  <= ptToRequestDate
    AND   Order.RequestDate  <= ptCancelDate:

    FOR EACH OrderLine NO-LOCK
    WHERE OrderLine.ArEntity    = Order.ArEntity
    AND   OrderLine.OrderNumber = Order.OrderNumber
    AND   OrderLine.WarehouseCode >= pcFromwarehouseCode
    AND   OrderLine.WarehouseCode <= pcToWarehouseCode:

      FIND FIRST ITEM NO-LOCK
      WHERE ITEM.ItemCode = OrderLine.ItemCode
      AND   ITEM.InEntity = OrderLine.InEntity NO-ERROR.

      FIND FIRST Customer NO-LOCK
      WHERE   Customer.CustomerCode = Order.CustomerCode NO-ERROR.

/*       FIND FIRST InvoiceLine NO-LOCK                                       */
/*         WHERE InvoiceLine.ArEntity        = Order.ArEntity                 */
/*         AND   InvoiceLine.OrderNumber     = OrderLine.OrderNumber          */
/*         AND   invoiceLine.OrderLineNumber = OrderLine.LineNumber NO-ERROR. */

      CREATE xttOrderLineV1.
      BUFFER-COPY OrderLine TO xttOrderLineV1
      ASSIGN
      xttOrderLineV1.InvoiceNumber    = Order.InvoiceNumber
      xttOrderLineV1.InvoiceDate      = Order.InvoiceDate
      xttOrderLineV1.salesRepCode     = Order.salesRepCode
      xttOrderLineV1.ppsNumber        = Order.ppsNumber
      xttOrderLineV1.OpenValue        = Order.OpenValue
      xttOrderLineV1.Base1OpenValue   = Order.Base1OpenValue
      xttOrderLineV1.viaDescription   = Order.viaDescription
      xttOrderLineV1.ShipTo           = Order.ShipTo
      xttOrderLineV1.CustomerName     = Customer.NAME
      xttOrderLineV1.ItemDescription  = Item.Description
      xttOrderLineV1.OrderDate        = Order.OrderDate
/*    xttOrderLineV1.QuantityShipped  = (IF AVAIL InvoiceLine THEN InvoiceLine.QuantityShipped ELSE 0)  */
      xttOrderLineV1.QuantityShipped  = OrderLine.QuantityShipped
      xttOrderLineV1.InvoiceVatAmount = OrderLine.VatAmount
/*    xttOrderLineV1.InvoiceVatAmount = (IF AVAIL InvoiceLine THEN InvoiceLine.VatAmount ELSE 0) */
      xttOrderLineV1.OrderVatAmount   = OrderLine.VatAmount
      xttOrderLineV1.CustomerPurchaseOrder = Order.CustomerPurchaseOrder .
    END.




  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE fetchOrderLineV1 a 
PROCEDURE fetchOrderLineV1 :
/*------------------------------------------------------------------------------
 Routine to populate the view 'gttOrderLineV1' based on database table 
 'OrderLine'.     
------------------------------------------------------------------------------*/
&scop xViewName gttOrderLineV1

  {psobject/dac/fetchparam.i} 

  case pcRequestName:

    when "all":u or when "OrderLineForWoSalesOrder" or when "ValidOrderLine":u 
        OR WHEN "OrderNumber":u OR WHEN "OrderNumberForAlloc":u OR WHEN "OrderImpact":u 
        OR WHEN "PoReservation":u OR WHEN "WoReservation":u  OR WHEN "SingleOrderLine":u
        OR WHEN "CreateCPM":u OR WHEN "OpenOrderNumber":U THEN
      {psobject/dac/processrequest.i &xcDBTableList = "'OrderLine':u" }
      WHEN "customer"  THEN
          {psobject/dac/processrequest.i &xcDBTableList = "'Order,OrderLine,uom':u" }
      WHEN "OrderNumberSC"  THEN
          {psobject/dac/processrequest.i &xcDBTableList = "'OrderLine':u" }

      WHEN "TransferAlloc" OR WHEN "Reserve" THEN
          {psobject/dac/processrequest.i &xcDBTableList = "'Order,OrderLine':u" }

      WHEN "Reserve" THEN
          {psobject/dac/processrequest.i &xcDBTableList = "'OrderLine':u" }

      WHEN "OutstandingEmb":u OR WHEN "NoMatsLines":u  THEN
          {psobject/dac/processrequest.i &xcDBTableList = "'Order,OrderLine':u" }

    when "":u then
      {psobject/dac/processrequest.i}  

    otherwise
      throwError(substitute("No process request branch for [&1].", pcRequestName)). 

  end case.


  def var cArEntity      as char no-undo.
  def var iOrderNumber   as int  no-undo.
  def var cItemCode      as char no-undo.
  DEF VAR cInEntity      AS CHAR NO-UNDO.
  DEF VAR cWarehouseCode AS CHAR NO-UNDO.
  DEF VAR cApEntity      AS CHAR NO-UNDO.
  DEF VAR cPoNumber      AS CHAR NO-UNDO.
  DEF VAR cReleaseNumber AS CHAR NO-UNDO.
  DEF VAR cPoLineNumber  AS CHAR NO-UNDO.
  DEF VAR cCustomerCode  AS CHAR NO-UNDO.
  DEF VAR cEntityWip     AS CHAR NO-UNDO.
  DEF VAR cWoNumber      AS CHAR NO-UNDO.
  DEF VAR cMarketSegmentCode AS CHAR NO-UNDO.

  {psobject/dac/fetchhdr.i}

      when "all":u then
      do:
        assign cArEntity      = trim(getParamValue(pcFetchParams,"ArEntity":u)).
        
        hQry:QUERY-PREPARE("for each Orderline no-lock where Orderline.ArEntity = ":u + "'":u + cArEntity +  "'":u +
                            (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " AND ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).
      end.
      when "OrderNumber":u then
      do:
          run getCustomQuery1(input-output hQry, input pcFetchParams, input cFilterExpr4GL, input cSearchExpr4GL, input cFilterSort4GL).
      end.
      when "NoMatsLines":u then
      do:
          run getCustomQueryNoMatsLines(input-output hQry, input pcFetchParams, input cFilterExpr4GL, input cSearchExpr4GL, input cFilterSort4GL).
      end.


      when "OrderNumberSC":u then
      do:
          run getCustomQuery2(input-output hQry, input pcFetchParams, input cFilterExpr4GL, input cSearchExpr4GL, input cFilterSort4GL).
      end.

      when "OrderNumberForAlloc":u then
      do:
          run getCustomQuery3(input-output hQry, input pcFetchParams, input cFilterExpr4GL, input cSearchExpr4GL, input cFilterSort4GL).
      end.
      WHEN "OpenOrderNumber":U THEN
      DO:
          run getCustomQuery5(input-output hQry, input pcFetchParams, input cFilterExpr4GL, input cSearchExpr4GL, input cFilterSort4GL).
      END.

      WHEN "SingleOrderLine":u then
      do:
          run getCustomQuery6(input-output hQry, input pcFetchParams, input cFilterExpr4GL, input cSearchExpr4GL, input cFilterSort4GL).
      end.

      when "customer":u then
      do:

        assign ccustomercode      = trim(getParamValue(pcFetchParams,"customercode":u))
                       cArEntity   = GetGlobalChar({&xcModEntPrefix} + STRING({&xiModOrderProcessing})).
        hQry:QUERY-PREPARE("for each Order no-lock where order.arentity = '":u + cArEntity + "'" +
                            (IF ccustomercode <> "all" THEN (" and order.customercode = '" + ccustomercode + "'") ELSE "") + 
                               ",each orderline where orderline.arEntity = order.ArEntity and OrderLine.OrderNumber = order.ordernumber no-lock 
                               ,each uom no-lock where uom.uomcode = orderline.uomcode"
                           
                           + (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " and ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).
      end.

      when "ValidOrderLine":u OR WHEN "CreateCPM":u then
      do:

        assign cArEntity      = trim(getParamValue(pcFetchParams,"ArEntity":u)).

        hQry:QUERY-PREPARE("for each Orderline no-lock where Orderline.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u +
                            " and OrderLine.QuantityOpenOrdered > 0 ":u + 
                            (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " and ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).
      end.

      when "OrderLineForWoSalesOrder":u then
      do:

        assign cArEntity = trim(getParamValue(pcFetchParams,"ArEntity":u))
               cItemCode = trim(getParamValue(pcFetchParams,"ItemCode":u)).

        hQry:QUERY-PREPARE("for each Orderline no-lock where Orderline.ArEntity = ":u + "'":u + cArEntity +  "'":u +
                            " and OrderLine.ItemCode = ":u +  "'":u + cItemCode +  "'":u + 
                            " and OrderLine.QuantityOpenOrdered > 0 ":u + 
                       /*   " and OrderLine.GenerateWorkOrder = true ":u +   */ 
                             (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " and ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).
      end.

      WHEN "OrderImpact":u THEN
      DO:

        ASSIGN cInEntity      = TRIM(GetParamValue(pcFetchParams,"InEntity":u))
               cItemCode      = TRIM(GetParamValue(pcFetchParams,"ItemCode":u))
               cWarehouseCode = TRIM(GetParamValue(pcFetchParams,"WarehouseCode":u)).

        hQry:QUERY-PREPARE("for each Orderline no-lock ":u +
                           " where Orderline.ArEntity = ":u + "'":u + cAREntity + "'":u +
                           " and OrderLine.ItemCode = ":u +  "'":u + cItemCode + "'":u +
                           " and OrderLine.WarehouseCode = ":u + "'":u + cWarehouseCode + "'":u +
                           " and OrderLine.QuantityOpenOrdered > 0 ":u + 
                            (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " and ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).
      end.

      WHEN "Reserve":u THEN
      DO:

        ASSIGN cArEntity = GetGlobalChar({&xcModEntPrefix} + STRING({&xiModOrderProcessing}))
               cInEntity = GetGlobalChar({&xcModEntPrefix} + STRING({&xiModInventory})).
                hQry:QUERY-PREPARE("for each orderline no-lock where orderline.ArEntity = ":U + "'":u + cArEntity + "'":u +
                            " and (OrderLine.QuantityOpenOrdered - OrderLine.QuantityAllocated - OrderLine.QuantityOnPps) > 0 ":u +
                            (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " and ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).
      END.
      
      WHEN "PoReservation":u THEN
      DO:

        ASSIGN cArEntity      = GetParamValue(pcFetchParams,"ArEntity":u)
               cInEntity      = GetParamValue(pcFetchParams,"InEntity":u)
               cItemCode      = GetParamValue(pcFetchParams,"ItemCode":u)
               cWarehouseCode = GetParamValue(pcFetchParams,"WarehouseCode":u)
               cApEntity      = GetParamValue(pcFetchParams,"ApEntity":u)
               cPoNumber      = GetParamValue(pcFetchParams,"PoNumber":u)
               cReleaseNumber = GetParamValue(pcFetchParams,"ReleaseNumber":u)
               cPoLineNumber  = GetParamValue(pcFetchParams,"LineNumber":u).

        hQry:QUERY-PREPARE("for each OrderLine no-lock":u +
                           " where OrderLine.InEntity = ":u      + "'":u + cInEntity      + "'":u +
                           " and   OrderLine.ItemCode = ":u      + "'":u + cItemCode      + "'":u +
                           " and   OrderLine.WarehouseCode = ":u + "'":u + cWarehouseCode + "'":u +
                           " and   OrderLine.ArEntity = ":u      + "'":u + cArEntity      + "'":u +
                           " and  (OrderLine.QuantityOpenOrdered - OrderLine.QuantityAllocated - OrderLine.QuantityOnPps) > 0 ":u + 
                            (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " and ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " by Priority by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).

      END.
      WHEN "WoReservation":u THEN
      DO:

        ASSIGN cArEntity          = GetParamValue(pcFetchParams,"ArEntity":u)
               cInEntity          = GetParamValue(pcFetchParams,"InEntity":u)
               cItemCode          = GetParamValue(pcFetchParams,"ItemCode":u)
               cEntityWip         = GetParamValue(pcFetchParams,"EntityWip":u)
               cWoNumber          = GetParamValue(pcFetchParams,"WoNumber":u)
               cMarketSegmentCode = GetParamValue(pcFetchParams,"MarketSegmentCode":u).

        IF cMarketSegmentCode = "":u THEN ASSIGN cMarketSegmentCode = "*":u.

        hQry:QUERY-PREPARE("for each OrderLine no-lock":u +
                           " where OrderLine.InEntity = ":u      + "'":u + cInEntity      + "'":u +
                           " and   OrderLine.ItemCode = ":u      + "'":u + cItemCode      + "'":u +
                           " and   OrderLine.ArEntity = ":u      + "'":u + cArEntity      + "'":u +
                           " and  (OrderLine.QuantityOpenOrdered - OrderLine.QuantityAllocated - OrderLine.QuantityOnPps) > 0 ":u + 
                            (if cFilterExpr4GL <> "":u then 
                             " and ":u + cFilterExpr4GL 
                             else 
                               "":u) + 
                            (if cFilterExpr4GL <> "":u and cSearchExpr4GL <> "":u then 
                               " and ":u + cSearchExpr4GL 
                             else 
                               if cFilterExpr4GL = "":u and cSearchExpr4GL <> "":u then 
                                 " and ":u + cSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if cFilterSort4GL = "":u then 
                               " by Priority by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               cFilterSort4GL)  +
                            " indexed-reposition ":u).
      END.

      WHEN "TransferAlloc":u THEN
      DO:
          RUN GetCustomQuery4(INPUT-OUTPUT hQry, INPUT pcFetchParams, INPUT cFilterExpr4GL, INPUT cSearchExpr4GL, INPUT cFilterSort4GL).
      END.

      WHEN "OutstandingEmb":u THEN
      DO:
          RUN GetCustomQuery7(INPUT-OUTPUT hQry, INPUT pcFetchParams, INPUT cFilterExpr4GL, INPUT cSearchExpr4GL, INPUT cFilterSort4GL).
      END.

  {psobject/dac/fetchbody.i}        

    when "all":u or when "OrderNumberSC":u or when "OrderLineForWoSalesOrder":u or when "ValidOrderLine":u 
    OR WHEN "OrderNumberForAlloc":u OR WHEN "OrderImpact":u  OR WHEN "OrderNumber":u OR WHEN "SingleOrderLine":u
    OR WHEN "TransferAlloc":u OR WHEN "OpenOrderNumber":U OR WHEN "NoMatsLines":u THEN
    do:
   
        if avail Orderline then
        do:
            create gttOrderLineV1.
            loadView((buffer gttOrderLineV1:handle),
                     (buffer OrderLine:handle),
                      "":u, iRowNum, "":u).
            assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum). 
  
            FIND FIRST Order NO-LOCK WHERE Order.ArEntity    = OrderLine.ArEntity
                                       AND Order.OrderNumber = OrderLine.OrderNumber
                                        NO-ERROR.
            IF AVAILABLE Order THEN 
            DO:
                ASSIGN gttOrderLineV1.CustomerCode = Order.CustomerCode.
                FIND FIRST Customer NO-LOCK WHERE Customer.CustomerCode = Order.CustomerCode NO-ERROR.
                IF AVAILABLE Customer THEN 
                    ASSIGN gttOrderLineV1.CustomerCodeKDesc = Customer.NAME.
            END.
      end.
      else
        leave.
    end.

    WHEN "Reserve" THEN
    DO:

        if avail Orderline then
        do:
            FIND FIRST Order NO-LOCK WHERE Order.ArEntity    = OrderLine.ArEntity
                                       AND Order.OrderNumber = OrderLine.OrderNumber
                                       NO-ERROR.
            IF AVAILABLE Order THEN 
            DO:
                create gttOrderLineV1.
                loadView((buffer gttOrderLineV1:handle),
                     (buffer OrderLine:handle),
                      "":u, iRowNum, "":u).
                assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum).
                ASSIGN gttOrderLineV1.CustomerCode = Order.CustomerCode.
                FIND FIRST Customer NO-LOCK WHERE Customer.CustomerCode = Order.CustomerCode NO-ERROR.
                IF AVAILABLE Customer THEN 
                    ASSIGN gttOrderLineV1.CustomerCodeKDesc = Customer.NAME.
            END.
      end.
      else
        leave.


    END.

    WHEN "customer" then
    do:
      if avail OrderLine then
      do:

        create gttOrderLineV1.
         loadView((buffer gttOrderLineV1:handle),
               (buffer OrderLine:handle),
               "":u, iRowNum, "":u).
        assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum). 
        IF AVAIL uom THEN
        gttOrderLineV1.quantityopenordered = orderline.quantityopenordered / uom.unit.
        gttOrderLineV1.tag = order.customercode.
      end.
      else
        leave.
    end.

    when "PoReservation":u then
    do:
      if avail OrderLine then
      do:

         FIND FIRST PoReservation NO-LOCK
              WHERE PoReservation.ApEntity      = cApEntity
              AND   PoReservation.PoNumber      = cPoNumber
              AND   PoReservation.ReleaseNumber = INTEGER(cReleaseNumber)
              AND   PoReservation.PoLineNumber  = INTEGER(cPoLineNumber)
              AND   PoReservation.ArEntity      = OrderLine.ArEntity
              AND   PoReservation.SoNumber      = OrderLine.OrderNumber
              AND   PoReservation.SoLineNumber  = OrderLine.LineNumber
              NO-ERROR.

         IF AVAILABLE PoReservation
         OR OrderLine.QuantityReserved < (OrderLine.QuantityOpenOrdered -
                                          OrderLine.QuantityAllocated -
                                          OrderLine.QuantityOnPps)
         THEN DO:

              create gttOrderLineV1.
              loadView((buffer gttOrderLineV1:handle),
                    (buffer OrderLine:handle),
                    "":u, iRowNum, "":u).

             FIND FIRST Order NO-LOCK
                  WHERE Order.ArEntity    = OrderLine.ArEntity
                  AND   Order.OrderNumber = OrderLine.OrderNumber
                  NO-ERROR.
             IF AVAILABLE Order 
             THEN DO:
                  ASSIGN gttOrderLineV1.CustomerCode = Order.CustomerCode.
                  FIND FIRST Customer NO-LOCK
                       WHERE Customer.CustomerCode = Order.CustomerCode
                       NO-ERROR.
                  IF AVAILABLE Customer THEN ASSIGN gttOrderLineV1.CustomerCodeKDesc = Customer.NAME.
             END.

             /* Exclude current Purchase Order Line from Quantity Reserved */
             IF AVAILABLE PoReservation
             THEN ASSIGN gttOrderLineV1.QuantityReserved = gttOrderLineV1.QuantityReserved
                                                         - PoReservation.QuantityReserved.

             assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum).

         END.

      end.
      else
        leave.
    end.

    when "WoReservation":u then
    do:
      if avail OrderLine then
      do:
         FIND Order NO-LOCK
              WHERE Order.ArEntity    = OrderLine.ArEntity
              AND   Order.OrderNumber = OrderLine.OrderNumber
              NO-ERROR.

         IF AVAILABLE Order AND Order.MarketSegmentCode MATCHES cMarketSegmentCode
         THEN DO:
              FIND FIRST WoReservation NO-LOCK
                   WHERE WoReservation.EntityWip     = cEntityWip
                   AND   WoReservation.WoNumber      = cWoNumber
                   AND   WoReservation.ArEntity      = OrderLine.ArEntity
                   AND   WoReservation.SoNumber      = OrderLine.OrderNumber
                   AND   WoReservation.SoLineNumber  = OrderLine.LineNumber
                   NO-ERROR.
              
              IF AVAILABLE WoReservation
              OR OrderLine.QuantityReserved < (OrderLine.QuantityOpenOrdered - OrderLine.QuantityAllocated - OrderLine.QuantityOnPps)
              THEN DO:
                   create gttOrderLineV1.
                   loadView((buffer gttOrderLineV1:handle),
                         (buffer OrderLine:handle),
                         "":u, iRowNum, "":u).
                   ASSIGN gttOrderLineV1.CustomerCode = Order.CustomerCode.
                   FIND FIRST Customer NO-LOCK
                        WHERE Customer.CustomerCode = Order.CustomerCode
                        NO-ERROR.
                   IF AVAILABLE Customer THEN ASSIGN gttOrderLineV1.CustomerCodeKDesc = Customer.NAME.

                  /* Exclude current Works Order from Quantity Reserved */
                  IF AVAILABLE WoReservation
                  THEN ASSIGN gttOrderLineV1.QuantityReserved = gttOrderLineV1.QuantityReserved - WoReservation.QuantityReserved.

                  assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum).

              END. /* IF AVAILABLE WoReservation */

         END. /* IF AVAILABLE Order */

      end.
      else
        leave.
    end.
                       
    WHEN "OutstandingEmb":u THEN
    do:
        if avail Orderline then
        do:
            create gttOrderLineV1.
            loadView((buffer gttOrderLineV1:handle),
                     (buffer OrderLine:handle),
                      "":u, iRowNum, "":u).
            assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum). 
  
            FIND FIRST Order NO-LOCK WHERE Order.ArEntity    = OrderLine.ArEntity
                                       AND Order.OrderNumber = OrderLine.OrderNumber
                                     NO-ERROR.
            IF AVAILABLE Order THEN 
            DO:
                ASSIGN gttOrderLineV1.CustomerCode = Order.CustomerCode
                       gttOrderLineV1.MiscData1 = Order.StatusCode
                       gttOrderLineV1.MiscData2 = STRING(Order.Embroidery)
                       .
                FIND FIRST Customer NO-LOCK WHERE Customer.CustomerCode = Order.CustomerCode NO-ERROR.
                IF AVAILABLE Customer THEN 
                    ASSIGN gttOrderLineV1.CustomerCodeKDesc = Customer.NAME.
            END.
      end.
      else
        leave.
    end.
                       

  {psobject/dac/fetchend.i}  

&undefine xViewName

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetCurrencyCode a 
PROCEDURE GetCurrencyCode :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT PARAMETER pcCurrencyCode AS CHARACTER NO-UNDO.
    DEF OUTPUT PARAMETER pdExchangeRate AS DECIMAL NO-UNDO.

    FIND FIRST CurrencyTr NO-LOCK WHERE CurrencyTr.FromCurrencyCode = pcCurrencyCode NO-ERROR.
    IF AVAILABLE CurrencyTr THEN
    DO:
        IF pcCurrencyCode <> "GBP":u THEN
            ASSIGN pdExchangeRate = CurrencyTr.ApRate.
        ELSE
            ASSIGN pdExchangeRate = 1.
END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetCustomerItemCode a 
PROCEDURE GetCustomerItemCode :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  DEFINE INPUT  PARAMETER pcInEntity                AS CHARACTER  NO-UNDO.
  DEFINE INPUT  PARAMETER pcCustomerItemCode        AS CHARACTER  NO-UNDO.
  DEFINE INPUT  PARAMETER pcCustomerCode            AS CHARACTER  NO-UNDO.
  DEFINE OUTPUT PARAMETER pcItemCode                AS CHARACTER  NO-UNDO.
  DEFINE OUTPUT PARAMETER pcCustomerItemDescription AS CHARACTER  NO-UNDO.

  DEFINE        VARIABLE  cArEntity                 AS CHARACTER  NO-UNDO.
  DEFINE        VARIABLE  cPricingSequence          AS CHARACTER  NO-UNDO.
  DEFINE        VARIABLE  cItemCode                 AS CHARACTER  NO-UNDO.
  DEFINE        VARIABLE  cPricingGroup             AS CHARACTER  NO-UNDO.
  DEFINE        VARIABLE  cCustomerType             AS CHARACTER  NO-UNDO.
  DEFINE        VARIABLE  cCustomerCode             AS CHARACTER  NO-UNDO.
  DEFINE        VARIABLE  cGenericItemCode             AS CHARACTER  NO-UNDO.
  DEFINE        VARIABLE  iSeqCount                 AS INTEGER    NO-UNDO.

  ASSIGN cArEntity = GetGlobalChar({&xcModEntPrefix} + STRING({&xiModOrderProcessing})).

  FIND OpControl WHERE OpControl.ArEntity = cArEntity NO-LOCK NO-ERROR.
  
  IF AVAILABLE OpControl 
  THEN cPricingSequence = opControl.pricingSequence.
  ELSE cPricingSequence = "".
  
  FIND ITEM 
  WHERE ITEM.InEntity = pcInEntity
    AND ITEM.ItemCode = pcCustomerItemCode
        NO-LOCK NO-ERROR.
    
  IF AVAILABLE ITEM 
  THEN DO:
      IF ITEM.GenericItem
      THEN DO:
        FIND ProductGroup WHERE ProductGroup.ProdGroup = ITEM.ProdGroup NO-LOCK NO-ERROR.
        assertNoError().

        ASSIGN cGenericItemCode = SUBSTRING(Item.ItemCode, 1,ProductGroup.AttributeLength).
      END.

      ASSIGN cItemCode = pcCustomerItemCode
             cPricingGroup = ITEM.PricingGroup.
  END.
  ELSE ASSIGN cItemCode = pcCustomerItemCode
              cGenericItemCode = "":u
              cPricingGroup = "".
  
  FIND Customer 
  WHERE Customer.customerCode = pcCustomerCode 
        NO-LOCK NO-ERROR.
    
  IF AVAILABLE Customer
  THEN ASSIGN cCustomerCode = Customer.CustomerCode
              cCustomerType = Customer.CustomerType.
  ELSE ASSIGN cCustomerCode = Customer.CustomerCode
              cCustomerType = "".
       
  PRICE-LOOP : DO iSeqCount = 1 TO 5:

      IF iSeqCount > 5
      THEN LEAVE price-loop.

      IF LENGTH(cPricingSequence) LT iSeqCount
      THEN LEAVE price-loop.

      IF SUBSTRING ( cPricingSequence , iSeqCount , 1 ) LT "1" OR
         SUBSTRING ( cpricingSequence , iSeqCount , 1 ) GT "5" 
      THEN NEXT price-loop.
          /* If PRICING  is directly from Customer File */
      IF SUBSTRING ( cpricingSequence , iSeqCount , 1 ) EQ "5" 
      THEN  ASSIGN ccustomerCode = pcCustomerCode
                   cItemCode = pcCustomerItemCode.
      ELSE DO:      
          /* Customer Pricing: CustomerCode / Item CODE */
          IF SUBSTRING ( cPricingSequence , iSeqCount , 1 ) EQ "1"
          THEN ASSIGN cCustomerCode = pcCustomerCode
                      cItemCode     = pcCustomerItemCode.
        ELSE DO: /* customer pricing: CustomerCode / PRICING-GRP */
          IF SUBSTRING ( CPricingSequence , iSeqCount , 1 ) EQ "2"
          THEN ASSIGN cCustomerCode = pcCustomerCode
                      cItemCode     = cPricingGroup.

          ELSE DO: /* customer pricing: CustType / Item CODE */
            IF SUBSTRING ( cPricingSequence , iSeqCount , 1 ) EQ "3"
            THEN ASSIGN cCustomerCode = cCustomerType
                        cItemCode     = pcCustomerItemCode.

            ELSE DO: /* customer pricing: CustType / PRICING-GRP */
              IF SUBSTRING ( cPricingSequence , iSeqCount , 1 ) EQ "4"
              THEN ASSIGN cCustomerCode = cCustomerType
                          cItemCode     = cPricingGroup.
            END. /* end: CustType / PRICING-GRP */
          END. /* end: CustType / Item CODE */
        END. /* end: CustType / Item CODE */
     
        FIND CustomerPricing WHERE CustomerPricing.CustomerCode     = cCustomerCode
                               AND CustomerPricing.ArEntity         = cArEntity
                               AND CustomerPricing.CustomerItemCode = cItemCode  
                               AND CustomerPricing.Active           = yes
                               AND CustomerPricing.EffectiveDate    LE TODAY
                               AND CustomerPricing.ExpiryDate       GE TODAY
            NO-LOCK NO-ERROR.
        
        IF NOT AVAIL(CustomerPricing) THEN
        FIND CustomerPricing WHERE CustomerPricing.CustomerCode     = cCustomerCode
                               AND CustomerPricing.ArEntity         = cArEntity
                               AND CustomerPricing.CustomerItemCode = cGenericItemCode   
                               AND CustomerPricing.Active           = yes
                               AND CustomerPricing.EffectiveDate    LE TODAY 
                               AND CustomerPricing.ExpiryDate       GE TODAY
            NO-LOCK NO-ERROR.
                
        IF NOT AVAIL(CustomerPricing) THEN
        FIND CustomerPricing WHERE CustomerPricing.CustomerCode     = pcCustomerCode
                         AND CustomerPricing.ArEntity               = cArEntity
                         AND CustomerPricing.CustomerItemCode = pcCustomerItemCode  
                         AND CustomerPricing.Active           = YES
                         AND CustomerPricing.EffectiveDate    <= TODAY 
                         AND CustomerPricing.ExpiryDate       >= TODAY   NO-LOCK NO-ERROR.
      
  
        IF AVAIL CustomerPricing AND customerpricing.pricebypricegroup = NO
        THEN DO:
            ASSIGN pcItemCode                = CustomerPricing.ItemCode
                   pcCustomerItemDescription = CustomerPricing.CustomerItemDescription.
            LEAVE price-loop.
        END.
        ELSE DO: 
            ASSIGN pcItemCode                = pcCustomerItemCode
                   pcCustomerItemDescription = "":u.
        END.

      END. /*not 5*/
  END. /*price-loop*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCustomQuery1 a 
PROCEDURE getCustomQuery1 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input-output Parameter  phQuery         as handle no-undo.
  def input        Parameter  pcfetchParams   as char   no-undo.
  def input        Parameter  pcFilterExpr4GL as char   no-undo.
  def input        Parameter  pcSearchExpr4GL as char   no-undo.
  def input        Parameter  pcFilterSort4GL as char   no-undo.

  DEFINE VARIABLE cArEntity    AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE iOrderNumber AS INTEGER    NO-UNDO.
  DEFINE VARIABLE cCustomerCode AS CHARACTER  NO-UNDO.

  assign cArEntity      = trim(getParamValue(pcFetchParams,"ArEntity":u))
         iOrderNumber   = integer(getParamValue(pcFetchParams,"OrderNumber":u)) 
         cCustomerCode  = getParamValue(pcFetchParams,"CustomerCode":u) no-error.

  IF iOrderNumber = ? THEN 
      iOrderNumber = 0.
  
  IF cCustomerCode = "" THEN

  phQuery:QUERY-PREPARE("for each Orderline where Orderline.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u +
                        " and OrderLine.OrderNumber = ":u + string(iOrderNumber) + 
                        (if pcFilterExpr4GL <> "":u then 
                         " and ":u + pcFilterExpr4GL 
                         else 
                           "":u) + 
                        (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                           " and ":u + pcSearchExpr4GL 
                         else 
                           if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                             " and ":u + pcSearchExpr4GL 
                           else 
                             "":u) + " no-lock ":u + 
                        (if pcFilterSort4GL = "":u then 
                           " by ArEntity by OrderNumber by LineNumber ":u
                         else 
                           pcFilterSort4GL)  +
                        " indexed-reposition ":u).
               
  ELSE 
  DO: /* All lines for customer*/

      phQuery:QUERY-PREPARE("for each Order where Order.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u + 
                            " and Order.CustomerCode = " + "'" + cCustomerCode + "'" + " no-lock, each orderline of order no-lock":u + 
                            (if pcFilterExpr4GL <> "":u then 
                             " and ":u + pcFilterExpr4GL 
                             else 
                               "":u) + 
                            (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                               " and ":u + pcSearchExpr4GL 
                             else 
                               if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                 " and ":u + pcSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if pcFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               pcFilterSort4GL)  +
                            " indexed-reposition ":u).    

    END.



END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCustomQuery2 a 
PROCEDURE getCustomQuery2 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input-output Parameter  phQuery         as handle no-undo.
  def input        Parameter  pcfetchParams   as char   no-undo.
  def input        Parameter  pcFilterExpr4GL as char   no-undo.
  def input        Parameter  pcSearchExpr4GL as char   no-undo.
  def input        Parameter  pcFilterSort4GL as char   no-undo.

  DEFINE VARIABLE cArEntity     AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE iOrderNumber  AS INTEGER    NO-UNDO.
  DEFINE VARIABLE cCustomerCode AS CHARACTER  NO-UNDO.

  assign cArEntity      = trim(getParamValue(pcFetchParams,"ArEntity":u))
         iOrderNumber   = integer(getParamValue(pcFetchParams,"OrderNumber":u)) 
         cCustomerCode  = getParamValue(pcFetchParams,"CustomerCode":u) no-error.

  IF iOrderNumber = ? THEN 
      iOrderNumber = 0.
  
  IF cCustomerCode = "" THEN 
  DO: 
      /*select lines for single order only*/
      phQuery:QUERY-PREPARE("for each Orderline where Orderline.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u +
                        " and OrderLine.OrderNumber = ":u + string(iOrderNumber) + 
                        (if pcFilterExpr4GL <> "":u then 
                         " and ":u + pcFilterExpr4GL 
                         else 
                           "":u) + 
                        (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                           " and ":u + pcSearchExpr4GL 
                         else 
                           if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                             " and ":u + pcSearchExpr4GL 
                           else 
                             "":u) + " no-lock ":u + 
                        (if pcFilterSort4GL = "":u then 
                           " by ArEntity by OrderNumber by LineNumber ":u
                         else 
                           pcFilterSort4GL)  +
                        " indexed-reposition ":u).    
  END.
  ELSE 
  DO: /* All lines for customer*/
      phQuery:QUERY-PREPARE("for each Order where Order.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u + 
                            " and Order.CustomerCode = " + "'" + cCustomerCode + "'" + " no-lock, each orderline of order no-lock":u + 
                            (if pcFilterExpr4GL <> "":u then 
                             " and ":u + pcFilterExpr4GL 
                             else 
                               "":u) + 
                            (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                               " and ":u + pcSearchExpr4GL 
                             else 
                               if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                 " and ":u + pcSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if pcFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               pcFilterSort4GL)  +
                            " indexed-reposition ":u).    

    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCustomQuery3 a 
PROCEDURE getCustomQuery3 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input-output Parameter  phQuery         as handle no-undo.
  def input        Parameter  pcfetchParams   as char   no-undo.
  def input        Parameter  pcFilterExpr4GL as char   no-undo.
  def input        Parameter  pcSearchExpr4GL as char   no-undo.
  def input        Parameter  pcFilterSort4GL as char   no-undo.

  DEFINE VARIABLE cArEntity    AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE iOrderNumber AS INTEGER    NO-UNDO.


      assign cArEntity      = trim(getParamValue(pcFetchParams,"ArEntity":u))
             iOrderNumber   = integer(getParamValue(pcFetchParams,"OrderNumber":u)) no-error.

      phQuery:QUERY-PREPARE("for each Orderline where Orderline.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u +
                            " and OrderLine.OrderNumber = ":u + string(iOrderNumber) + 
                            " and OrderLine.QuantityOnPPs lt OrderLine.QuantityopenOrdered":u +                           
                            " no-lock ":u + 
                            (if pcFilterExpr4GL <> "":u then 
                             " and ":u + pcFilterExpr4GL 
                             else 
                               "":u) + 
                            (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                               " and ":u + pcSearchExpr4GL 
                             else 
                               if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                 " and ":u + pcSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if pcFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               pcFilterSort4GL)  +
                            " indexed-reposition ":u).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetCustomQuery4 a 
PROCEDURE GetCustomQuery4 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input-output Parameter  phQuery         as handle no-undo.
  def input        Parameter  pcfetchParams   as char   no-undo.
  def input        Parameter  pcFilterExpr4GL as char   no-undo.
  def input        Parameter  pcSearchExpr4GL as char   no-undo.
  def input        Parameter  pcFilterSort4GL as char   no-undo.

  DEFINE VARIABLE cArEntity     AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cCustomerCode AS CHARACTER NO-UNDO.

      ASSIGN cArEntity     = TRIM(GetParamValue(pcFetchParams,"ArEntity":u))
             cCustomerCode = TRIM(GetParamValue(pcFetchParams,"CustomerCode":u))
             NO-ERROR.

      phQuery:QUERY-PREPARE("for each  Order no-lock ":u +
                            "    where Order.ArEntity     = ":u + "'":u + cArEntity     + "'":u +
                            "    and   Order.CustomerCode = ":u + "'":u + cCustomerCode + "'":u +
                            "  , each  OrderLine no-lock ":u +
                            "    where OrderLine.ArEntity = Order.ArEntity ":u +
                            "    and   OrderLine.OrderNumber = Order.OrderNumber ":u + 
                            "    and   OrderLine.QuantityOnPps = 0 ":u +
                            "    and   OrderLine.QuantityOpenOrdered > OrderLine.QuantityAllocated ":u +
                            (if pcFilterExpr4GL <> "":u then 
                             " and ":u + pcFilterExpr4GL 
                             else 
                               "":u) + 
                            (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                               " and ":u + pcSearchExpr4GL 
                             else 
                               if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                 " and ":u + pcSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if pcFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               pcFilterSort4GL)  +
                            " indexed-reposition ":u).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCustomQuery5 a 
PROCEDURE getCustomQuery5 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input-output Parameter  phQuery         as handle no-undo.
  def input        Parameter  pcfetchParams   as char   no-undo.
  def input        Parameter  pcFilterExpr4GL as char   no-undo.
  def input        Parameter  pcSearchExpr4GL as char   no-undo.
  def input        Parameter  pcFilterSort4GL as char   no-undo.

  DEFINE VARIABLE cArEntity    AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE iOrderNumber AS INTEGER    NO-UNDO.

    assign cArEntity      = trim(getParamValue(pcFetchParams,"ArEntity":u))
           iOrderNumber   = integer(getParamValue(pcFetchParams,"OrderNumber":u)) no-error.

           IF iOrderNumber = ? THEN iOrderNumber = 0.

    phQuery:QUERY-PREPARE("for each Orderline where Orderline.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u +
                        " and OrderLine.OrderNumber = ":u + string(iOrderNumber) + 
                        " AND (orderline.QuantityOpenOrdered >= 1 OR orderline.QuantityAllocated >= 1 OR orderline.QuantityOnPPS >= 1) ":U +
                        (if pcFilterExpr4GL <> "":u then 
                         " and ":u + pcFilterExpr4GL 
                         else 
                           "":u) + 
                        (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                           " and ":u + pcSearchExpr4GL 
                         else 
                           if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                             " and ":u + pcSearchExpr4GL 
                           else 
                             "":u) + " no-lock ":u + 
                        (if pcFilterSort4GL = "":u then 
                           " by ArEntity by OrderNumber by LineNumber ":u
                         else 
                           pcFilterSort4GL)  +
                        " indexed-reposition ":u).



END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCustomQuery6 a 
PROCEDURE getCustomQuery6 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input-output Parameter  phQuery         as handle no-undo.
  def input        Parameter  pcfetchParams   as char   no-undo.
  def input        Parameter  pcFilterExpr4GL as char   no-undo.
  def input        Parameter  pcSearchExpr4GL as char   no-undo.
  def input        Parameter  pcFilterSort4GL as char   no-undo.

  DEFINE VARIABLE cArEntity    AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE cOrderNumber AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE cLineNumber  AS CHARACTER   NO-UNDO.


      ASSIGN cArEntity      = TRIM(getParamValue(pcFetchParams,"ArEntity":u))
             cOrderNumber   = TRIM(getParamValue(pcFetchParams,"OrderNumber":u))
             cLineNumber    = TRIM(getParamValue(pcFetchParams,"LineNumber":u)).


      phQuery:QUERY-PREPARE("for each Orderline where Orderline.ArEntity = ":u + "'":u + TRIM(cArEntity) +  "'":u +
                            " and OrderLine.OrderNumber = ":u + cOrderNumber + 
                            " and OrderLine.LineNumber = ":u + cLineNumber + 
                            " no-lock ":u + 
                            (if pcFilterExpr4GL <> "":u then 
                             " and ":u + pcFilterExpr4GL 
                             else 
                               "":u) + 
                            (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                               " and ":u + pcSearchExpr4GL 
                             else 
                               if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                 " and ":u + pcSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if pcFilterSort4GL = "":u then 
                               " by ArEntity by OrderNumber by LineNumber ":u
                             else 
                               pcFilterSort4GL)  +
                            " indexed-reposition ":u).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCustomQuery7 a 
PROCEDURE getCustomQuery7 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
def input-output Parameter  phQuery         as handle no-undo.
def input        Parameter  pcfetchParams   as char   no-undo.
def input        Parameter  pcFilterExpr4GL as char   no-undo.
def input        Parameter  pcSearchExpr4GL as char   no-undo.
def input        Parameter  pcFilterSort4GL as char   no-undo.

DEFINE VARIABLE cArEntity       AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cOrderNumber    AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cLineNumber     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lEmbOnly        AS LOGICAL     NO-UNDO.

    ASSIGN  cArEntity       = TRIM(getParamValue(pcFetchParams,"ArEntity":u))
            lEmbOnly        = (TRIM(getParamValue(pcFetchParams,"EmbOnly":u)) = "yes")
            .

    IF lEmbOnly THEN 
        phQuery:QUERY-PREPARE("for each  Order no-lock ":u +
                              "    where Order.ArEntity     = ":u + "'":u + cArEntity     + "'":u +
                              "    and   Order.Embroidery   = yes ":u +
                              "  , each  OrderLine no-lock ":u +
                              "    where OrderLine.ArEntity = Order.ArEntity ":u +
                              "    and   OrderLine.OrderNumber = Order.OrderNumber ":u + 
                              "    and   OrderLine.QuantityOpenOrdered > 0 ":u +
                               (if pcFilterExpr4GL <> "":u then 
                                 " and ":u + pcFilterExpr4GL 
                               else 
                                   "":u) + 
                               (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                                   " and ":u + pcSearchExpr4GL 
                                else 
                                if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                     " and ":u + pcSearchExpr4GL 
                                else 
                                     "":u) + 
                                (if pcFilterSort4GL = "":u then 
                                   " by ArEntity by OrderNumber by LineNumber ":u
                                 else 
                                   pcFilterSort4GL)  +
                                " indexed-reposition ":u).
    ELSE
        phQuery:QUERY-PREPARE("for each  Order no-lock ":u +
                              "    where Order.ArEntity     = ":u + "'":u + cArEntity     + "'":u +
                              "  , each  OrderLine no-lock ":u +
                              "    where OrderLine.ArEntity = Order.ArEntity ":u +
                              "    and   OrderLine.OrderNumber = Order.OrderNumber ":u + 
                              "    and   OrderLine.QuantityOpenOrdered > 0 ":u +
                               (if pcFilterExpr4GL <> "":u then 
                                 " and ":u + pcFilterExpr4GL 
                               else 
                                   "":u) + 
                               (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                                   " and ":u + pcSearchExpr4GL 
                                else 
                                if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                     " and ":u + pcSearchExpr4GL 
                                else 
                                     "":u) + 
                                (if pcFilterSort4GL = "":u then 
                                   " by ArEntity by OrderNumber by LineNumber ":u
                                 else 
                                   pcFilterSort4GL)  +
                                " indexed-reposition ":u).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCustomQueryNoMatsLines a 
PROCEDURE getCustomQueryNoMatsLines :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input-output Parameter  phQuery         as handle no-undo.
  def input        Parameter  pcfetchParams   as char   no-undo.
  def input        Parameter  pcFilterExpr4GL as char   no-undo.
  def input        Parameter  pcSearchExpr4GL as char   no-undo.
  def input        Parameter  pcFilterSort4GL as char   no-undo.

  DEFINE VARIABLE cArEntity      AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cFromOrderCode AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cToOrderCode   AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cFromOrderNo   AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cToOrderNo     AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cFromLineNo    AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cToLineNo      AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cFromItemCode  AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cToItemCode    AS CHARACTER   NO-UNDO.
                                 
      ASSIGN cArEntity       = TRIM(getParamValue(pcFetchParams,"ArEntity":u))
             cFromOrderCode  = TRIM(getParamValue(pcFetchParams,"FromOrderCode":u))
             cToOrderCode    = TRIM(getParamValue(pcFetchParams,"ToOrderCode":u))
             cFromOrderNo    = TRIM(getParamValue(pcFetchParams,"FromOrderNo":u)) 
             cToOrderNo      = TRIM(getParamValue(pcFetchParams,"ToOrderNo":u))   
             cFromLineNo     = TRIM(getParamValue(pcFetchParams,"FromLineNo":u)) 
             cToLineNo       = TRIM(getParamValue(pcFetchParams,"ToLineNo":u))   
             cFromItemCode   = TRIM(getParamValue(pcFetchParams,"FromItemCode":u)) 
             cToItemCode     = TRIM(getParamValue(pcFetchParams,"ToItemCode":u)).   
                            
      phQuery:QUERY-PREPARE("for each  Order no-lock ":u +
                            "    where Order.ArEntity     = ":u + "'":u + cArEntity     + "'":u +
                            "    and   Order.OrderNumber GE ":u + "'":u + cFromOrderNo + "'":u +
                            "    and   Order.OrderNumber LE ":u + "'":u + cToOrderNo + "'":u +
                            "    and   Order.OrderCode GE ":u + "'":u + cFromOrderCode + "'":u +
                            "    and   Order.OrderCode LE ":u + "'":u + cToOrderCode + "'":u +
                            "    and   Order.StatusCode = ":u + "'R'" + 
                            "  , each  OrderLine no-lock ":u +
                            "    where OrderLine.ArEntity = Order.ArEntity ":u +
                            "    and   OrderLine.OrderNumber = Order.OrderNumber ":u + 
                            "    and   OrderLine.LineNumber GE ":u + "'":u + cFromLineNo + "'":u + 
                            "    and   OrderLine.LineNumber LE ":u + "'":u + cToLineNo + "'":u + 
                            "    and   OrderLine.ItemCode GE ":u + "'":u + cFromItemCode + "'":u + 
                            "    and   OrderLine.ItemCode LE ":u + "'":u + cToItemCode + "'":u + 
                            "    and   OrderLine.QuantityOpenOrdered > 0  ":u +
                            (if pcFilterExpr4GL <> "":u then 
                             " and ":u + pcFilterExpr4GL 
                             else 
                               "":u) + 
                            (if pcFilterExpr4GL <> "":u and pcSearchExpr4GL <> "":u then 
                               " and ":u + pcSearchExpr4GL 
                             else 
                               if pcFilterExpr4GL = "":u and pcSearchExpr4GL <> "":u then 
                                 " and ":u + pcSearchExpr4GL 
                               else 
                                 "":u) + 
                            (if pcFilterSort4GL = "":u then 
                               " by OrderNumber ":u
                             else 
                               pcFilterSort4GL)  +
                            " indexed-reposition ":u).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetItemTaxLevel a 
PROCEDURE GetItemTaxLevel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  DEFINE INPUT  PARAMETER pcItemCode      AS CHARACTER  NO-UNDO.
  DEFINE INPUT  PARAMETER pcWarehouseCode AS CHARACTER  NO-UNDO.
  DEFINE INPUT  PARAMETER pcInEntity      AS CHARACTER  NO-UNDO.
  DEFINE OUTPUT PARAMETER pcTaxable       AS CHARACTER  NO-UNDO.

  FIND FIRST ItemWhs
      WHERE ItemWhs.ItemCode = pcItemCode
      AND   ItemWhs.InEntity = pcInEntity
      AND   ItemWhs.WarehouseCode = pcWarehouseCode NO-LOCK NO-ERROR.

  IF AVAIL(ItemWhs) THEN

  ASSIGN pcTaxable = ItemWhs.Taxable.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getLogoCost a 
PROCEDURE getLogoCost :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 DEFINE INPUT  PARAMETER pcArEntity      AS CHARACTER   NO-UNDO.
 DEFINE INPUT  PARAMETER piOrderNumber   AS INTEGER     NO-UNDO.
 DEFINE INPUT  PARAMETER piLineNumber    AS INTEGER     NO-UNDO.
 DEFINE INPUT  PARAMETER pcCustomerCode  AS CHARACTER   NO-UNDO.
 DEFINE INPUT  PARAMETER pcItemCode      AS CHARACTER   NO-UNDO.
 DEFINE OUTPUT PARAMETER pdLineLogoCost  AS DECIMAL     NO-UNDO.
 
 DEFINE VARIABLE lContinue               AS LOGICAL NO-UNDO INIT FALSE.                                           
 DEFINE VARIABLE cInEntity               AS CHARACTER   NO-UNDO.
 DEFINE VARIABLE cGenericItemCode        AS CHARACTER   NO-UNDO.

 cInEntity = getGlobalChar({&xcModEntPrefix} + STRING({&xiModInventory })).
 pdLineLogoCost = 0.

 /*Find any OrderLogo records*/
 FOR EACH OrderLogo
     WHERE OrderLogo.ArEntity       = pcArEntity
       AND OrderLogo.OrderNumber    = piOrderNumber
       AND OrderLogo.LineNumber     = piLineNumber
     NO-LOCK:

     ASSIGN pdLineLogoCost = pdLineLogoCost + OrderLogo.LogoCost.
            lContinue = TRUE.
 END.
 IF NOT lContinue THEN 
 DO:
     /*find any CustomerLogo Primary Default records for the itemcode*/
     FOR EACH CustomerItemLogo
         WHERE CustomerItemLogo.ArEntity     = pcArEntity
           AND CustomerItemLogo.CustomerCode = pcCustomerCode
           AND CustomerItemLogo.Itemcode     = pcItemCode
         NO-LOCK:

         FIND CustomerLogo
         WHERE CustomerLogo.ArEntity     = CustomerItemLogo.ArEntity
           AND CustomerLogo.CustomerCode = CustomerItemLogo.CustomerCode
           AND CustomerLogo.LogoCode     = CustomerItemLogo.LogoCode
           AND CustomerLogo.PositionCode = CustomerItemLogo.PositionCode
           AND Customerlogo.PrimaryDefault = TRUE
         NO-LOCK NO-ERROR.

         IF AVAILABLE CustomerLogo 
         THEN ASSIGN pdLineLogoCost = pdLineLogoCost + CustomerLogo.LogoCost
                     lContinue = TRUE.
     END.
 END.
 IF NOT lContinue THEN
 DO:
     /*find any CustomerLogo Primary Default records for the generic*/
     FIND ITEM
          WHERE ITEM.InEntity = cInEntity
            AND ITEM.ItemCode = pcItemCode
          NO-LOCK NO-ERROR.
     ASSIGN cGenericItemCode = "":u.
      
     IF AVAILABLE ITEM 
         AND Item.ItemCode <> Item.GenericItemCode
     THEN ASSIGN cGenericItemCode = ITEM.GenericItemCode.
      
     IF cGenericItemCode <> "":u THEN 
     DO:
         FOR EACH CustomerItemLogo
         WHERE CustomerItemLogo.ArEntity     = pcArEntity
           AND CustomerItemLogo.CustomerCode = pcCustomerCode
           AND CustomerItemLogo.Itemcode     = cGenericItemCode
         NO-LOCK:

             FIND CustomerLogo
             WHERE CustomerLogo.ArEntity     = CustomerItemLogo.ArEntity
               AND CustomerLogo.CustomerCode = CustomerItemLogo.CustomerCode
               AND CustomerLogo.LogoCode     = CustomerItemLogo.LogoCode
               AND CustomerLogo.PositionCode = CustomerItemLogo.PositionCode
               AND Customerlogo.PrimaryDefault = TRUE
             NO-LOCK NO-ERROR.
    
             IF AVAILABLE CustomerLogo 
             THEN ASSIGN pdLineLogoCost = pdLineLogoCost + CustomerLogo.LogoCost
                         lContinue = TRUE.
         END.
     END.
 END.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetPpsLineDetailTable a 
PROCEDURE GetPpsLineDetailTable :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input  parameter pcInEntity        as  char no-undo.
  def input  parameter pcWarehouseCode   as  char no-undo. 
  def input  parameter pcArEntity        as  char no-undo. 
  def input  parameter piOrderNumber     as  int  no-undo.
  def output parameter table       for gttOrderAllocLineDetailV1.

  def var iRowNum       as int no-undo.
  def var dConversionFactor as decimal decimals 6 no-undo.

  empty temp-table gttOrderAllocLineDetailV1.

  iRowNum = 0.

  for each OrderAllocLineDetail where OrderAllocLineDetail.ArEntity    = pcArEntity
                                  and OrderAllocLineDetail.OrderNumber = piOrderNumber no-lock:

    create gttOrderAllocLineDetailV1.
    buffer-copy OrderAllocLineDetail to gttOrderAllocLineDetailV1.
    assign gttOrderAllocLineDetailV1.OldQuantityReserved          = OrderAllocLineDetail.QuantityReserved
           gttOrderAllocLineDetailV1.OldQuantityOnPps             = OrderAllocLineDetail.QuantityOnPps
           gttOrderAllocLineDetailV1.OldQuantityAllocated         = OrderAllocLineDetail.QuantityAllocated
           gttOrderAllocLineDetailV1.OldCustomerQuantityAllocated = OrderAllocLineDetail.CustomerQuantityAllocated
           gttOrderAllocLineDetailV1.RowNum                       = iRowNum.
         

    find first uom where uom.uomCode = OrderAllocLineDetail.UomCode no-lock no-error.

    find first Item where Item.InEntity = pcInEntity
                      and Item.ItemCode = OrderAllocLineDetail.ItemCode no-lock no-error.
    if avail(Item) then
      gttOrderAllocLineDetailV1.BaseUomCode = Item.UomCode.

    gttOrderAllocLineDetailV1.cCustomerQuantityAllocated = 
                       decimal(BaseToUomQty(gttOrderAllocLineDetailV1.CustomerQuantityAllocated,
                                                                          Uom.ExpDecimal, 
                                                                          Uom.Unit, 
                                                                          Uom.Mask)).  
    getUomConversionFactor(input  gttOrderAllocLineDetailV1.BaseUomCode,
                           input  gttOrderAllocLineDetailV1.UomCode,
                           output dConversionFactor).

    ConvertToCustomerUomQty(input  gttOrderAllocLineDetailV1.QuantityAllocated,  
                            input  gttOrderAllocLineDetailV1.BaseUomCode,
                            input  gttOrderAllocLineDetailV1.UomCode,
                            input  dConversionFactor,
                            output gttOrderAllocLineDetailV1.cQuantityAllocated).
    assign iRowNum = iRowNum + 1.
  end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getPriceBreakAmtPer a 
PROCEDURE getPriceBreakAmtPer :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input param pcInEntity       as char no-undo.
  def input param pcItemCode       as char no-undo.
  def input param pcWhsCode        as char no-undo.
  def output param pcAmountPercent as char no-undo.

  find ItemWhs 
       where ItemWhs.InEntity      = pcInEntity
       and   ItemWhs.ItemCode      = pcItemCode 
       and   ItemWhs.WarehouseCode = pcWhsCode
       no-lock no-error.
  if avail(ItemWhs) then
  do:
    find PriceBreak where PriceBreak.BreakCode eq ItemWhs.BreakCode no-lock no-error.

    if PriceBreak.type eq "1" or PriceBreak.type eq "3" then 
      pcAmountPercent = "no":u.
    else if PriceBreak.type eq "2" or PriceBreak.type eq "4" then 
      pcAmountPercent = "yes":u.
  end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetQuantityOpenOrdered a 
PROCEDURE GetQuantityOpenOrdered :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER pcArEntity      AS CHARACTER    NO-UNDO.
    DEFINE INPUT  PARAMETER piOrderNumber   AS INTEGER      NO-UNDO.
    DEFINE INPUT  PARAMETER piLineNumber    AS INTEGER      NO-UNDO.
    DEFINE OUTPUT PARAMETER piQuantityOpen  AS INTEGER      NO-UNDO.
    
    FIND OrderLine
        WHERE OrderLine.ArEntity    = pcArEntity
          AND OrderLine.OrderNumber = piOrderNumber
          AND OrderLine.LineNumber  = piLineNumber
        NO-LOCK NO-ERROR.
    IF AVAILABLE OrderLine 
        THEN piQuantityOpen = OrderLine.QuantityOpenOrder.
        ELSE piQuantityOpen = 0.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getsalesorders a 
PROCEDURE getsalesorders :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
   DEFINE INPUT PARAMETER cArEntity AS CHARACTER NO-UNDO.
   DEFINE INPUT PARAMETER cCustomerCode AS CHARACTER NO-UNDO.
   DEFINE INPUT PARAMETER TABLE FOR gttItemV1.
   DEFINE OUTPUT PARAMETER TABLE FOR gttOrderLineV1.

   DEFINE BUFFER bOrder FOR Order.

   DEFINE VARIABLE iRowNum      AS INTEGER    NO-UNDO.
   DEFINE VARIABLE cCustCode    AS CHARACTER  NO-UNDO.

    EMPTY TEMP-TABLE gttOrderLineV1.

    IF cCustomerCode = "All":u THEN DO:
        FOR EACH gttItemV1 NO-LOCK:

            FOR EACH ItemStock 
                WHERE ItemStock.InEntity = gttItemV1.InEntity
                AND   ItemStock.ItemCode = gttItemV1.ItemCode
                NO-LOCK:
            

                FOR EACH OrderLine 
                    WHERE OrderLine.InEntity = ItemStock.InEntity
                    AND   OrderLine.ItemCode = ItemStock.Itemcode
                    AND   OrderLine.WarehouseCode = ItemStock.WarehouseCode
                    AND   OrderLine.ArEntity = cArEntity
                    AND   OrderLine.JobNumber = " ":u
                    AND   OrderLine.WoNumber = "":u
                    AND   OrderLine.QuantityOpenOrdered > 0
                    AND   NOT OrderLine.FromSalesOrder
                    AND   NOT OrderLine.GeneratedFromSo
                    AND   NOT OrderLine.GenerateWorkOrder
                    NO-LOCK:


                    FIND FIRST bOrder NO-LOCK
                         WHERE bOrder.ArEntity    = OrderLine.ArEntity
                         AND   bOrder.OrderNumber = OrderLine.OrderNumber
                         NO-ERROR.
                    IF AVAILABLE bOrder THEN ASSIGN cCustCode = bOrder.CustomerCode.

                    CREATE gttOrderLineV1.
                    BUFFER-COPY OrderLine TO gttOrderLineV1 NO-ERROR.
                    ASSIGN gttOrderLineV1.CustomerCode = cCustCode
                           gttOrderLineV1.RowNum = iRowNum
                           iRowNum = iRowNum + 1
                           .                        
                    assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum). 
                END.              
            END.
        END.    
    END.

    ELSE DO:
        FOR EACH gttItemV1 NO-LOCK:

            FOR EACH order 
                WHERE Order.ArEntity     = cArEntity
                AND   Order.CustomerCode = cCustomerCode
                AND   Order.OpenValue > 0 
                NO-LOCK:

                FOR EACH OrderLine 
                    WHERE Orderline.ArEntity = Order.ArEntity
                    AND   OrderLine.InEntity = Order.InEntity
                    AND   OrderLine.ItemCode = gttItemV1.Itemcode
                    AND   OrderLine.JobNumber = " ":u
                    AND   OrderLine.WoNumber = "":u
                    AND   OrderLine.QuantityOpenOrdered > 0
                    AND   NOT OrderLine.FromSalesOrder
                    AND   NOT OrderLine.GeneratedFromSo
                    AND   NOT OrderLine.GenerateWorkOrder
                    NO-LOCK:

                    CREATE gttOrderLineV1.
                    BUFFER-COPY OrderLine TO gttOrderLineV1 NO-ERROR.
                    ASSIGN gttOrderLineV1.CustomerCode = cCustomerCode
                           gttOrderLineV1.RowNum = iRowNum
                           iRowNum = iRowNum + 1
                           .                        
                    assignOrderLineV1(buffer gttOrderLineV1, buffer OrderLine, iRowNum). 
                END.
            END.
        END.            
    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getSystemSpecific a 
PROCEDURE getSystemSpecific :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF INPUT PARAM cInpSItemCode AS CHAR NO-UNDO.
DEF OUTPUT PARAM cOutSDescription AS CHAR NO-UNDO.

cOutSDescription="".
FIND FIRST SystemSpecific WHERE
                SystemSpecific.ItemCode=cInpSItemCode
                NO-LOCK NO-ERROR.
IF AVAILABLE SystemSpecific THEN
    cOutSDescription=SystemSpecific.DESCRIPTION.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetUomUnit a 
PROCEDURE GetUomUnit :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF INPUT PARAMETER pcUomCode AS CHARACTER NO-UNDO.
DEF OUTPUT PARAMETER piUomUnit AS INTEGER NO-UNDO.

FIND FIRST Uom NO-LOCK WHERE Uom.UomCode = pcUomCode NO-ERROR.
IF AVAILABLE Uom THEN
    ASSIGN piUomUnit = Uom.Unit.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE GetXDWarehouse a 
PROCEDURE GetXDWarehouse :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

  DEFINE INPUT  PARAMETER pcInEntity      AS CHARACTER   NO-UNDO.
  DEFINE INPUT  PARAMETER pcItemCode      AS CHARACTER   NO-UNDO.
  DEFINE INPUT  PARAMETER pcwarehousecode AS CHARACTER   NO-UNDO.
  DEFINE OUTPUT PARAMETER pcXDWarehouse   AS CHARACTER   NO-UNDO.
  DEFINE OUTPUT PARAMETER pcUOM           AS CHARACTER   NO-UNDO.

  FIND FIRST ITEM NO-LOCK
      WHERE ITEM.inentity = pcinentity
      AND   ITEM.itemcode = pcitemcode {&xNoError}.

  FIND uom NO-LOCK WHERE uom.uomcode = ITEM.uomcode {&xNoError}.
  pcUOM = uom.DESCRIPTION + ",":u + uom.uomcode.

  FIND itemwhs NO-LOCK
      WHERE itemwhs.inentity = pcinentity
      AND   itemwhs.itemcode = pcitemcode
      AND   itemwhs.warehousecode = pcwarehousecode NO-ERROR.

  IF AVAILABLE itemwhs THEN DO:
      FIND warehouse NO-LOCK
           WHERE warehouse.warehousecode = itemwhs.CrossDockWarehouse NO-ERROR.
  END.
  IF AVAIL warehouse THEN
          pcxdwarehouse = SUBST("&1,&2":u, warehouse.Description, warehouse.WarehouseCode).
  

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE InterCompany a 
PROCEDURE InterCompany :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    DEFINE INPUT  PARAMETER pcCustomerCode      AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER plInterCompany      AS LOGICAL     NO-UNDO.
    DEFINE OUTPUT PARAMETER pcBase1CurrencyCode AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcBase2CurrencyCode AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcBase1Desc         AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcBase2Desc         AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER pdCreditLimit       AS DECIMAL     NO-UNDO.

    FIND FIRST Customer NO-LOCK
        WHERE Customer.CustomerCode = pcCustomerCode NO-ERROR.

    IF AVAIL Customer THEN DO:
        plInterCompany = Customer.InterCompany.
        IF plInterCompany THEN DO:

            FIND  ControlEntity WHERE  ControlEntity.entitycode = Customer.InterCompanyEntity
                                  AND   ControlEntity.moduleid = {&xiModGeneralLedger} NO-LOCK NO-ERROR.

            IF AVAIL ControlEntity THEN
                FIND GlControl NO-LOCK WHERE GlControl.GlEntity = ControlEntity.ControlEntityCode NO-ERROR.

            IF AVAIL GlControl THEN DO:
                ASSIGN
                pcBase1CurrencyCode = GlControl.Base1Currency
                pcBase2CurrencyCode = GlControl.Base2Currency.
                FIND Currency NO-LOCK WHERE Currency.CurrencyCode = GlControl.Base1Currency NO-ERROR.
                IF AVAIL Currency THEN pcBase1Desc = Currency.Description.
                FIND Currency NO-LOCK WHERE Currency.CurrencyCode = GlControl.Base2Currency NO-ERROR.
                IF AVAIL Currency THEN pcBase2Desc = Currency.Description.

                SetGlobalChar("Base1Currency":u,pcBase1CurrencyCode).
                SetGlobalChar("Base2Currency":u,pcBase2CurrencyCode).
                SetGlobalChar("Base1Description":u,pcBase1Desc).
                SetGlobalChar("Base2Description":u,pcBase2Desc).

                RETURN {&xcsuccess}.
            END.
            ELSE RETURN "Customer set as Inter Company but entities not correctly set up":u.


        END.


    END.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE isSOPLeadTime a 
PROCEDURE isSOPLeadTime :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF INPUT PARAMETER cSOPLeadTimeItemCode AS CHARACTER NO-UNDO.
DEF OUTPUT PARAMETER lSOPLeadTIme        AS LOGICAL   NO-UNDO.

ASSIGN lSOPLeadTime = FALSE.

FIND FIRST SystemSpecific WHERE
                SystemSpecific.ItemCode = cSOPLeadTimeItemCode
                NO-LOCK NO-ERROR.

IF AVAILABLE SystemSpecific THEN
DO:
   ASSIGN lSOPLeadTime = TRUE.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE LogoStockItemValue a 
PROCEDURE LogoStockItemValue :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT PARAMETER TABLE FOR gttOrderLogoV1.
DEFINE INPUT PARAMETER iQuantity AS INT NO-UNDO.
DEFINE INPUT PARAMETER cWarehouseCode AS CHAR NO-UNDO.
DEFINE OUTPUT PARAMETER lExceeded AS LOGICAL NO-UNDO.

DEFINE VAR cInEntity AS CHAR NO-UNDO.


  lExceeded = FALSE.
  cInEntity = getGlobalChar({&xcModEntPrefix} + string({&xiModInventory })).
  
  EMPTY TEMP-TABLE ttLogoStockItems.

  FOR EACH gttOrderLogoV1.
            
        FIND FIRST CustomerLogo WHERE CustomerLogo.ArEntity     = gttOrderLogoV1.ArEntity AND
                                      CustomerLogo.CustomerCode = gttOrderLogoV1.CustomerCode AND
                                      CustomerLogo.LogoCode     = gttOrderLogoV1.LogoCode AND
                                      CustomerLogo.PositionCode = gttOrderLogoV1.PositionCode AND
                                      CustomerLogo.ItemCode     <> "" NO-LOCK NO-ERROR.

        IF AVAIL CustomerLogo THEN
        DO.
            FIND ttLogoStockItems WHERE ttLogoStockItems.InEntity      = cInEntity AND
                                        ttLogoStockItems.ItemCode      = CustomerLogo.ItemCode AND
                                        ttLogoStockItems.WarehouseCode = cWarehouseCode NO-ERROR.

            IF NOT AVAIL ttLogoStockItems THEN
                CREATE ttLogoStockItems.

            ASSIGN ttLogoStockItems.Inentity       = cInEntity
                   ttLogoStockItems.ItemCode       = CustomerLogo.ItemCode 
                   ttLogoStockItems.WarehouseCode  = cWarehouseCode.

            ttLogoStockItems.Quantity = ttLogoStockItems.Quantity + iQuantity.

           
        END.

  END.

  FOR EACH ttLogoStockItems.

      FIND ItemStock WHERE ItemStock.InEntity      = ttLogoStockItems.Inentity AND
                           ItemStock.ItemCode      = ttLogoStockItems.ItemCode AND
                           ItemStock.WarehouseCode = ttLogoStockItems.WarehouseCode NO-LOCK NO-ERROR.

      IF AVAIL ItemStock THEN
      DO.
           IF ItemStock.Quantityonhand < ttLogoStockItems.Quantity THEN
               lExceeded = TRUE.

      END.

  END.
 

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE MaxAllowedQuantity a 
PROCEDURE MaxAllowedQuantity :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input  parameter pcInEntity        as  char no-undo.
  def input  parameter pcItemCode        as  char no-undo.
  def input  parameter pcWarehouseCode   as  char no-undo. 
  def output parameter piMaxAllowedQty   as  int  no-undo.
  def output parameter pcClassStorageLabels as char no-undo.
  def output parameter pcError           as  char no-undo.  

  def var iItemClass as int no-undo.

  pcError = "":u.

  find itemStock where ItemStock.ItemCode      = pcItemCode
                   and ItemStock.InEntity      = pcInEntity 
                   and ItemStock.WarehouseCode = pcWarehouseCode no-lock no-error.
  if not avail(itemStock) then
  do:
    pcError = "ItemStockDoesNotExists":u.
    return.
  end.

  piMaxAllowedQty = ItemStock.QuantityOnHand - ItemStock.QuantityAlloc 
                  - ItemStock.QuantityOnPps  - ItemStock.DespatchNoteQty
                  - ItemStock.QuantityReserved.

  find Item where Item.InEntity eq pcInEntity 
              and Item.itemcode eq pcItemCode no-lock no-error.
  if avail(Item) then
    iItemClass = Item.ItemClass.

  pcClassStorageLabels = "":u.

  find ItemClass where ItemClass.ItemCLass = iItemClass no-lock no-error.
  if avail(ItemClass) then 
  do:
    /*Identifier Info*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"IdentifierLabel":u, ItemCLass.IdentifierLabel).
    pcClassStorageLabels = putParam(pcClassStorageLabels,"UseIdentifier":u, string(ItemCLass.UseIdentifier)).

    /*Identifier Info*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"SubIdentifierLabel":u, ItemCLass.SubIdentifierLabel).
    pcClassStorageLabels = putParam(pcClassStorageLabels,"UseSubIdentifier":u, string(ItemCLass.UseSubIdentifier)).

    /*ItemClass*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"ItemClass":u, string(ItemCLass.ItemClass)).

    /*Generic Field1 Info*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"GenericField1Label":u, ItemCLass.GenericField1Label).
    pcClassStorageLabels = putParam(pcClassStorageLabels,"UseGenericField1":u, string(ItemCLass.UseGenericField1)).

    /*Generic Field2 Info*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"GenericField2Label":u, ItemCLass.GenericField2Label).
    pcClassStorageLabels = putParam(pcClassStorageLabels,"UseGenericField2":u, string(ItemCLass.UseGenericField2)).


    /*Generic Field3 Info*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"GenericField3Label":u, ItemCLass.GenericField3Label).
    pcClassStorageLabels = putParam(pcClassStorageLabels,"UseGenericField3":u, string(ItemCLass.UseGenericField3)).

    /*Generic Field4 Info*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"GenericField4Label":u, ItemCLass.GenericField4Label).
    pcClassStorageLabels = putParam(pcClassStorageLabels,"UseGenericField4":u, string(ItemCLass.UseGenericField4)).


    /*Generic LineQuantity Info*/
    pcClassStorageLabels = putParam(pcClassStorageLabels,"LabelForQuantity":u, ItemCLass.LabelForQuantity).

    /*Storage and SubStorage Prompt*/
    find Warehouse where Warehouse.WarehouseCode = pcWarehouseCode no-lock no-error.
    if avail(Warehouse) then
    do:
      /*Storage Prompt*/
      pcClassStorageLabels = putParam(pcClassStorageLabels,"StoragePrompt":u, Warehouse.StoragePrompt).
      pcClassStorageLabels = putParam(pcClassStorageLabels,"StorageReq":u, string(Warehouse.StorageReq)).

      /*Sub Storage Prompt*/
      pcClassStorageLabels = putParam(pcClassStorageLabels,"SubStoragePrompt":u, Warehouse.SubStoragePrompt).
      pcClassStorageLabels = putParam(pcClassStorageLabels,"SubStorageReq":u, string(Warehouse.SubStorageReq)).
    end.
  end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE ppsDetailsExist a 
PROCEDURE ppsDetailsExist :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT PARAMETER pcArEntity AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piOrderNumber AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piOrderLineNumber AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMsg AS CHARACTER NO-UNDO.
DEFINE VARIABLE hOrder AS HANDLE NO-UNDO.
DEFINE VARIABLE lXDLinesExist AS LOGICAL NO-UNDO.
DEFINE VARIABLE cErrorList AS CHARACTER NO-UNDO.

  pcMsg = "":u.

  IF CAN-FIND(FIRST ppsline WHERE ppsline.ArEntity = pcArEntity
                              AND ppsline.OrderNumber = piOrderNumber
                              AND ppsline.OrderLineNumber = piOrderLineNumber)
  THEN
      pcMsg = "CannotDeletePPSExists".
  
  /*do not allow deletes for allocations either*/
  FIND OrderLine
      WHERE OrderLine.ArEntity          = pcArEntity
      AND   OrderLine.OrderNumber       = piOrderNumber
      AND   OrderLine.LineNumber        = piOrderLineNumber
      AND   OrderLine.QuantityAllocated > 0
      NO-LOCK NO-ERROR.
  
  IF AVAILABLE OrderLine THEN DO:
        /* Check for cross dock order line allocation is only on the originating entity and at start of the cycle */
        hOrder = requestService("Order":u, this-procedure, "":u) NO-ERROR.
        IF VALID-HANDLE (hOrder) THEN
        DO:
            FIND ItemWhs WHERE ItemWhs.InEntity = OrderLine.InEntity 
                           AND ItemWhs.ItemCode = OrderLine.ItemCode
                           AND ItemWhs.WarehouseCode = OrderLine.WarehouseCode 
                           AND ItemWhs.CrossDock = TRUE 
                           NO-LOCK NO-ERROR.
            IF AVAILABLE ItemWhs THEN
            DO:
                ASSIGN lXDLinesExist = FALSE.
                RUN CheckXDLines in hOrder(INPUT piOrderNumber, pcArEntity, 
                                           OUTPUT cErrorList, 
                                           OUTPUT lXDLinesExist) NO-ERROR.
                IF cErrorList <> "":u THEN /* not allowed to delete XD line */
                    pcMsg = ("CannotDeleteRecord" + {&xcMsgArgDelim} + "Orderline":u 
                        + {&xcMsgArgDelim} + "For Order ":u + STRING(piOrderNumber)  
                        + " Line ":u + STRING(piOrderLineNumber) +  " Cross Dock line has been processed beyond the start of the cross dock cycle":u ).  
            END.
            ELSE /* Not XD So Error */
                pcMsg = ("CannotDeleteRecord" + {&xcMsgArgDelim} + "Orderline":u 
                    + {&xcMsgArgDelim} + "For Order ":u + STRING(piOrderNumber)  
                    + " Line ":u + STRING(piOrderLineNumber) +  " Quantity is still allocated. Please deallocate line, save globally and then try to delete again":u ).  

        END.
        ELSE /* Error */
            pcMsg = ("CannotDeleteRecord" + {&xcMsgArgDelim} + "Orderline":u 
                + {&xcMsgArgDelim} + "For Order ":u + STRING(piOrderNumber)  
                + " Line ":u + STRING(piOrderLineNumber) +  " Quantity is still allocated. Please deallocate line, save globally and then try to delete again":u ).  
  END. 



END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE refreshOrderLineV1 a 
PROCEDURE refreshOrderLineV1 :
/*------------------------------------------------------------------------------
 Entry point for refreshing the rows in 'gttOrderLineV1'.
------------------------------------------------------------------------------*/
&scop xViewName gttOrderLineV1

  {psobject/dac/refreshview.i &xBuffer-1 = "OrderLine"}

&undefine xViewName

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE SetOrigBaseCurrencies a 
PROCEDURE SetOrigBaseCurrencies :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    DEFINE INPUT  PARAMETER pcOrigBase1     AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pcOrigBase2     AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pcOrigBase1Desc AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pcOrigBase2Desc AS CHARACTER   NO-UNDO.

    SetGlobalChar("Base1Currency":u,pcOrigBase1).
    SetGlobalChar("Base2Currency":u,pcOrigBase2).
    SetGlobalChar("Base1Description":u,pcOrigBase1Desc).
    SetGlobalChar("Base2Description":u,pcOrigBase2Desc).

    

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE SOPLeadTime a 
PROCEDURE SOPLeadTime :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE VARIABLE lIsSOPLeadTime  AS LOGICAL     NO-UNDO.
DEFINE VARIABLE iLeadTimeDays   AS INTEGER     NO-UNDO. 
DEFINE VARIABLE cItemCode       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cWarehouseCode  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iAdditionalDays AS INTEGER     NO-UNDO.
DEFINE VARIABLE iOrderNumber    AS INTEGER     NO-UNDO.
DEFINE VARIABLE cArEntity       AS CHARACTER   NO-UNDO.

  
  RUN isSOPLeadTime (INPUT "SOP-leadtime":U, OUTPUT lIsSOPLeadTime).
  
  IF lIsSOPLeadTime = TRUE THEN
  DO:
     ASSIGN cWarehouseCode = gttOrderLineV1.WarehouseCode
            cItemCode      = gttOrderLineV1.ItemCode.

     FIND ItemWhs NO-LOCK
          WHERE ItemWhs.ItemCode      = cItemCode
            AND ItemWhs.WarehouseCode = cWarehouseCode NO-ERROR.

     IF AVAILABLE ItemWhs THEN
         ASSIGN iLeadTimeDays = ItemWhs.LeadTime.
     ELSE
         ASSIGN iLeadTimeDays = 0.

     DYNAMIC-FUNCTION ("returnShopCalendarDays", INPUT iLeadTimeDays,
                                                 OUTPUT iAdditionalDays).
     ASSIGN gttOrderLineV1.PromiseDate        = (TODAY) + iAdditionalDays.

     IF gttOrderLineV1.RevisedPromiseDate = ? THEN
     DO:
        ASSIGN gttOrderLineV1.RevisedPromiseDate = gttOrderLineV1.PromiseDate.
     END.

       /*FOR EACH OrderLine WHERE OrderLine.ArEntity    = pcArEntity
                         AND OrderLine.OrderNumber = piOrderNumber NO-LOCK:
       IF OrderLine.RevisedPromiseDate > dLatestPromDate THEN
           ASSIGN dLatestPromDate = OrderLine.RevisedPromiseDate.
       END.*/

     /*RUN assignOrderPromDate (INPUT cArEntity,
                              INPUT iOrderNumber).*/

  END.
  

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE UpdateBlanketOrderRelease a 
PROCEDURE UpdateBlanketOrderRelease :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  def input parameter table for gttOrderLineV1.
  def input parameter tdOrderDate as date no-undo.
  def input parameter pcArEntity as char no-undo.
  def input parameter piBlanketNumber as int no-undo.
  def input parameter piReleaseNumber as int no-undo.

  def var iLastReleaseQty as int no-undo.
  def var iBuyerQtyToRelease as int no-undo.
  def var iSupplierQtyToRelease as int no-undo.
  def var iBuyerQtyReleased     as int no-undo.
  def var iSupplierQtyReleased  as int no-undo. 

  def var dOpenValue  as dec no-undo. 
  def var dBase1Amount  as dec no-undo. 
  def var dBase2Amount  as dec no-undo. 

  def var dLineVATAmount  as dec no-undo. 
  def var dVATAmount  as dec no-undo. 
  def var cErrorMsg  as CHAR no-undo. 

  for each gttOrderLineV1:
    find BlanketOrderRelease where BlanketOrderRelease.ArEntity      = gttOrderLineV1.ArEntity
                               and BlanketOrderRelease.BlanketNumber = piBlanketNumber
                               and BlanketOrderRelease.ReleaseNumber = piReleaseNumber
                               and BlanketOrderRelease.LineNumber    = gttOrderLineV1.LineNumber
                               no-lock no-error.
    if not avail(BlanketOrderRelease) then
    do:
      create BlanketOrderRelease.
      assign BlanketOrderRelease.ArEntity                 = gttOrderLineV1.ArEntity
             BlanketOrderRelease.BlanketNumber            = piBlanketNumber
             BlanketOrderRelease.LineNumber               = gttOrderLineV1.LineNumber
             BlanketOrderRelease.ReleaseNumber            = piReleaseNumber
             BlanketOrderRelease.OrderDate                = tdOrderDate
             BlanketOrderRelease.CustomerQuantityReleased = gttOrderLineV1.CustomerQuantityOnOrder
             BlanketOrderRelease.psMemoId                 = gttOrderLineV1.psMemoId.
    end.              

    find first BlanketOrderLine where BlanketOrderLine.ArEntity      eq gttOrderLineV1.ArEntity
                                  and BlanketOrderLine.BlanketNumber eq piBlanketNumber
                                  and BlanketOrderLine.LineNumber    eq gttOrderLineV1.BlanketLine
                                  exclusive-lock no-error.
    if avail(BlanketOrderLine) then
    do:
      assign BlanketOrderLine.LastReleaseDate              = tdOrderDate
             BlanketOrderLine.LastReleaseNumber            = gttOrderLineV1.ReleaseNumber
             BlanketOrderLine.CustomerQuantityOnOrder      = BlanketOrderLine.CustomerQuantityOnOrder - gttOrderLineV1.CustomerQuantityOnOrder
             BlanketOrderLine.LastReleaseQuantity          = BlanketOrderLine.LastReleaseQuantity + gttOrderLineV1.CustomerQuantityOnOrder.

      find BlanketOrder where BlanketOrder.ArEntity      eq pcArEntity
                          and BlanketOrder.BlanketNumber eq piBlanketNumber exclusive-lock no-error.

   run TaxCalc (input BlanketOrder.InEntity ,
                                   input BlanketOrderLine.ItemCode,
                                   input BlanketOrder.WarehouseCode,
                                   input yes,
                                   input BlanketOrder.TaxCode,
                                   input BlanketOrder.BlanketDate,
                                   input no,
                                   input YES,
                                   input-output BlanketOrderLine.Taxable,
                                   output cErrorMsg).
     
   run OpenValueCalculation (input  (BlanketOrderLine.CustomerQuantityOnOrder + gttOrderLineV1.CustomerQuantityOnOrder), 
                                input  BlanketOrderLine.BookingAmount,
                                input  BlanketOrderLine.CustomerQuantityOnOrder, 
                                input  BlanketOrderLine.BookingAmount,
                                input  BlanketOrderLine.UomCode,         
                                input  BlanketOrder.BlanketDate, 
                                input  BlanketOrder.CurrencyCode,
                                input  BlanketOrder.CustomerCode,
                                input  BlanketOrder.ExchangeRate1,
                                input  BlanketOrder.ExchangeRate2,
                                input  BlanketOrderLine.PriceConversionFactor,
                                output dOpenValue,  
                                output dBase1Amount,
                                output dBase2Amount).

     

    run VATAmountCalculation (INPUT  BlanketOrderLine.ArEntity,
                              input  BlanketOrder.TaxCode, 
                              input  BlanketOrder.BlanketDate,
                              input  dOpenValue,
                              input  BlanketOrderLine.Taxable,
                              input  BlanketOrderLine.UomCode,
                              input  BlanketOrderLine.PriceConversionFactor,
                              output dLineVATAmount,
                              output dVATAmount,
                              output cErrorMsg).

  
    assign BlanketOrder.Base1OpenValue = BlanketOrder.Base1OpenValue + dBase1Amount
             BlanketOrder.Base2OpenValue = BlanketOrder.Base2OpenValue + dBase2Amount
             BlanketOrder.OpenValue      = BlanketOrder.OpenValue + dOpenValue
             BlanketOrder.VATAmount      = BlanketOrder.VATAmount + dVATAmount.


      if BlanketOrderLine.CustomerQuantityOnOrder le 0 then
        BlanketOrderLine.CustomerQuantityOnOrder = 0.

      if BlanketOrderLine.CustomerQuantityOnOrder eq 0 then
        BlanketOrderLine.StatusCode = "C":u.     
    end.
  end.

  find BlanketOrder where BlanketOrder.ArEntity      eq pcArEntity
                      and BlanketOrder.BlanketNumber eq piBlanketNumber
                      exclusive-lock no-error.
  if avail(BlanketOrder) then  
  do:
    assign BlanketOrder.LastReleaseNumber = piReleaseNumber
           BlanketOrder.LastReleaseDate   = tdOrderDate.

    if not can-find(first BlanketOrderLine where BlanketOrderLine.ArEntity      eq pcArEntity
                                             and BlanketOrderLine.BlanketNumber eq piBlanketNumber
                                             and BlanketOrderLine.StatusCode    ne "C":u) then
      assign BlanketOrder.StatusCode = "C":u.
  end.

  release BlanketOrderLine.
  release BlanketOrder.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE UpdateNoMats a 
PROCEDURE UpdateNoMats :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT PARAMETER TABLE FOR gttOrderLineV1.

    FOR EACH gttOrderLineV1 NO-LOCK
        BREAK BY gttOrderLineV1.OrderNumber :

        /* set all the no mats on orderline */
        FIND OrderLine
            WHERE OrderLine.ArEntity    = gttOrderLineV1.ArEntity
            AND   OrderLine.OrderNumber = gttOrderLineV1.OrderNumber
            AND   OrderLine.LineNumber  = gttOrderLineV1.LineNumber
            EXCLUSIVE NO-ERROR.


        IF AVAILABLE (OrderLine) THEN
        DO:
            IF gttOrderLineV1.BuyersOrderLineReference = "Set":u THEN
                ASSIGN OrderLine.PromotionCode = "NM":u. 

            IF gttOrderLineV1.BuyersOrderLineReference = "CLEAR":u THEN
                ASSIGN OrderLine.PromotionCode = "":u. 
        END.

        /* update the no materials flag on the order */
        IF LAST-OF (gttOrderLineV1.OrderNumber) THEN
        DO:
            FIND Order
                WHERE Order.ArEntity    = gttOrderLineV1.ArEntity
                AND   Order.OrderNumber = gttOrderLineV1.OrderNumber
                EXCLUSIVE NO-ERROR.
            IF AVAILABLE (Order) THEN
            DO:

                FIND FIRST OrderLine
                    WHERE OrderLine.ArEntity    = Order.ArEntity
                    AND   OrderLine.OrderNumber = Order.OrderNumber
                    AND   OrderLine.PromotionCode = "NM":u
                    NO-LOCK NO-ERROR.

                IF AVAILABLE OrderLine THEN
                    ASSIGN Order.NoMaterial = TRUE.
                ELSE ASSIGN Order.NoMaterial = FALSE.
            END.
        END.
    END.
    RELEASE OrderLine.
    RELEASE Order.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE updateOrderLineV1 a 
PROCEDURE updateOrderLineV1 :
/*------------------------------------------------------------------------------
 Entry point for updating the database table 'OrderLine' based on view 
 'gttOrderLineV1'.

 xcDBTableList is a comma separated list of the tables that are updated with 
 values from gttOrderLineV1. There must be one instance of processtable.i included 
 for each table in the list.
------------------------------------------------------------------------------*/
&scop xViewName gttOrderLineV1
&scop xcDBTableList "OrderLine":u

  {psobject/dac/updatehdr.i}
  
DEFINE VARIABLE lIsSOPLeadTime  AS LOGICAL     NO-UNDO.
DEFINE VARIABLE iLeadTimeDays   AS INTEGER     NO-UNDO. 
DEFINE VARIABLE cItemCode       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cWarehouseCode  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iAdditionalDays AS INTEGER     NO-UNDO.
DEFINE VARIABLE iOrderNumber    AS INTEGER     NO-UNDO.
DEFINE VARIABLE cArEntity       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iLocMemoID      AS INTEGER     NO-UNDO.

ASSIGN cArEntity    = getGlobalChar({&xcModEntPrefix} + STRING({&xiModAccountReceivable}))
       iOrderNumber = gttOrderLineV1.OrderNumber.
  
  IF AVAILABLE gttOrderLineV1
  THEN DO:
  
       FIND ITEM NO-LOCK
            WHERE ITEM.InEntity = gttOrderLineV1.InEntity
            AND   ITEM.ItemCode = gttOrderLineV1.ItemCode
            NO-ERROR.
       IF AVAILABLE ITEM THEN ASSIGN gttOrderLineV1.EcServiceItem = ITEM.EcServiceItem.
       
       RUN isSopLeadTime (INPUT "SOP-Leadtime":u, OUTPUT lIsSopLeadTime).
       
       IF lIsSopLeadTime THEN
       DO:
          IF gttOrderLineV1.RevisedPromiseDate = ? THEN
          DO:
             ASSIGN gttOrderLineV1.RevisedPromiseDate = gttOrderLineV1.PromiseDate.
          END.
          IF gttOrderLineV1.RevisedPromiseDate < gttOrderLineV1.Promisedate THEN
          DO: 
              ASSIGN gttOrderLineV1.RevisedPromiseDate = gttOrderLineV1.PromiseDate.
          END.

       END.
     
      /* 660141 Prevent CustomerItem Code Being Same as Generic */
      IF gttOrderLineV1.CustomerItemCode = ITEM.GenericItemCode THEN
      DO:
           ASSIGN gttOrderLineV1.CustomerItemCode        = ITEM.Itemcode
                  gttOrderLineV1.CustomerItemDescription = ITEM.DESCRIPTION.
      END.

  END.
    
  {psobject/dac/processtable.i &xDBTable = "OrderLine"}
  
  {psobject/dac/updateend.i}


&undefine xViewName
&undefine xcDBTableList

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE ValidateDacTable a 
PROCEDURE ValidateDacTable :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

  &scop xViewName gttOrderLineV1

  {psobject/dac/validatedactable.i}
  
  
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

/* ************************  Function Implementations ***************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION assignOrderLineV1 a 
FUNCTION assignOrderLineV1 returns logical
  ( buffer pbgttOrderLineV1 for gttOrderLineV1, 
    buffer pbOrderLine for OrderLine, 
    piRowNum as int ) :
/*--------------------------------------------------------------
 Populate the view gttOrderLineV1. 
--------------------------------------------------------------*/
  def buffer bgttOrderLineV1 for OrderLine.

  def var cBaseUomCode      as char no-undo.
  def var cUomQty           as char no-undo.
  def var dConversionFactor as decimal decimals 6 no-undo.

  def var iGenericCustomerQuantityOnOrder as int no-undo.
  def var cTempCustomerQuantityOnOrder    as char no-undo.
  def var cTempOriginalQuantityOnOrder    as char no-undo.
  def var cTempQuantityAllocated          as char no-undo.
  def var cTempQuantityReserved           as char no-undo.
  def var cTempQuantityOnPps              as char no-undo.
  def var cTempQuantityShipped            as char no-undo.
  
  def var lgeneric as logical no-undo. 
  def var lfoundvariant as logical no-undo.
  
  lfoundvariant = FALSE. 
  if not available order then
  find first Order where Order.ArEntity    = pbgttOrderLineV1.ArEntity
                     and Order.OrderNumber = pbgttOrderLineV1.OrderNumber no-lock no-error.
  if avail(Order) then
    pbgttOrderLineV1.OrderDate = Order.OrderDate.
  
  assign pbgttOrderLineV1.OldBookingAmount            = pbgttOrderLineV1.BookingAmount
         pbgttOrderLineV1.OldQuantityOpenOrdered      = pbgttOrderLineV1.CustomerQuantityOnOrder
         pbgttOrderLineV1.OldPromiseDate              = pbgttOrderLineV1.PromiseDate
         pbgttOrderLineV1.OldRevisedPromiseDate       = pbgttOrderLineV1.RevisedPromiseDate
         pbgttOrderLineV1.OldRevisedDateCount         = pbgttOrderLineV1.RevisedDateCount
         pbgttOrderLineV1.OldQuantityAllocated        = pbgttOrderLineV1.QuantityAllocated
         pbgttOrderLineV1.OldCustomerQuantityAlloc   = pbgttOrderLineV1.CustomerQuantityAllocated
         pbgttOrderLineV1.OldQuantityOnPps            = pbgttOrderLineV1.QuantityOnPps
         pbgttOrderLineV1.OldCustomerQuantityOnOrder   = pbgttOrderLineV1.CustomerQuantityOnOrder
         pbgttOrderLineV1.OldQuantityReserved         = pbgttOrderLineV1.QuantityReserved
         pbgttOrderLineV1.OriginalItemCode            = pbgttOrderLineV1.ItemCode
         pbgttOrderLineV1.OriginalQuantityOpenOrdered = pbgttOrderLineV1.CustomerQuantityOnOrder.

  if pbgttOrderLineV1.LineNumber = pbgttOrderLineV1.GenericLine then
  do:
  
  if can-find(first item no-lock where item.inentity = pbgttOrderLineV1.InEntity
  and item.itemcode = pbgttOrderLineV1.ItemCode
and item.genericitem = true) then assign lgeneric = true. 

  if lgeneric = true then
    if can-find(first bgttOrderLineV1 where bgttOrderLineV1.ArEntity    =  pbgttOrderLineV1.ArEntity
                                        and bgttOrderLineV1.OrderNumber =  pbgttOrderLineV1.OrderNumber
                                        and bgttOrderLineV1.LineNumber  <> pbgttOrderLineV1.LineNumber
                                        and bgttOrderLineV1.GenericLine =  pbgttOrderLineV1.GenericLine) then
                                        
    do:
    assign lfoundvariant = true. 
      find item where item.InEntity = pbgttOrderLineV1.InEntity
                  and item.ItemCode = pbgttOrderLineV1.ItemCode no-lock no-error.
      assertNoError().

      find itemClass where ItemClass.ItemClass = Item.ItemClass no-lock no-error.
      if avail(ItemClass) then
      do:
        assign pbgttOrderLineV1.UseIdentifier = ItemClass.UseIdentifier
               pbgttOrderLineV1.UseSubIdentifier = ItemClass.UseSubIdentifier.
      end.

      find Warehouse where Warehouse.WarehouseCode = pbgttOrderLineV1.WarehouseCode no-lock no-error.
      if avail(Warehouse) then
      do:
        assign pbgttOrderLineV1.UseStorage = Warehouse.StorageReq
               pbgttOrderLineV1.UseSubStorage = Warehouse.SubStorageReq.
      end.

      find ProductGroup where ProductGroup.ProdGroup = item.ProdGroup no-lock no-error.
      assertNoError().

      assign pbgttOrderLineV1.OriginalItemCode = substring(pbgttOrderLineV1.ItemCode, 1,ProductGroup.AttributeLength).
      assign pbgttOrderLineV1.BaseUomCode = Item.Uom
             pbgttOrderLineV1.GenericItemLine = yes.
    end.
    else lfoundvariant = false. 
    
    if lfoundvariant = false then do:
      find item where item.InEntity = pbgttOrderLineV1.InEntity
                  and item.ItemCode = pbgttOrderLineV1.ItemCode no-lock no-error.
      assertNoError().

      assign pbgttOrderLineV1.BaseUomCode = Item.Uom.

      find itemClass where ItemClass.ItemClass = Item.ItemClass no-lock no-error.
      if avail(ItemClass) then
      do:
        assign pbgttOrderLineV1.UseIdentifier = ItemClass.UseIdentifier
               pbgttOrderLineV1.UseSubIdentifier = ItemClass.UseSubIdentifier.
      end.

      find Warehouse where Warehouse.WarehouseCode = pbgttOrderLineV1.WarehouseCode no-lock no-error.
      if avail(Warehouse) then
      do:
        assign pbgttOrderLineV1.UseStorage = Warehouse.StorageReq
               pbgttOrderLineV1.UseSubStorage = Warehouse.SubStorageReq.
      end.
    end.      
  end.

  find item where item.InEntity = pbgttOrderLineV1.InEntity
              and item.ItemCode = pbgttOrderLineV1.ItemCode no-lock no-error.
  assertNoError().
  
      find first ItemStock where ItemStock.InEntity = pbgttOrderLineV1.InEntity
                      and ItemStock.ItemCode = pbgttOrderLineV1.ItemCode 
                      and ItemStock.WarehouseCode = pbgttOrderLineV1.WarehouseCode 
                    no-lock no-error. 

  /* 16/11/2005 MAB 640247 */
  ASSIGN pbgttOrderLineV1.BaseUomCode = ITEM.Uom.

  ConvertToUomQty(input  pbgttOrderLineV1.CustomerQuantityOnOrder,
                  input  pbgttOrderLineV1.uomCode,
                  output cTempCustomerQuantityOnOrder).

  ConvertToUomQty(input  pbgttOrderLineV1.OrderQtyOriginal,
                  input  pbgttOrderLineV1.uomCode,
                  output cTempOriginalQuantityOnOrder). 

  ConvertToUomQty(input  pbgttOrderLineV1.QuantityOpenOrdered,
                  input  Item.UomCode,
                  output pbgttOrderLineV1.cQuantityOpenOrdered).    

  ConvertToUomQty(input  pbgttOrderLineV1.QuantityOnPps,
                  input  Item.UomCode,
                  output cTempQuantityOnPps).

  assign pbgttOrderLineV1.cQuantityOnPps = dec(cTempQuantityOnPps).

  ConvertToUomQty(input  pbgttOrderLineV1.QuantityAllocated,
                  input  Item.UomCode,
                  output cTempQuantityAllocated).    

  ConvertToUomQty(input  pbgttOrderLineV1.QuantityReserved,
                  input  Item.UomCode,
                  output pbgttOrderLineV1.cQuantityReserved).    

  ConvertToUomQty(input  pbgttOrderLineV1.QuantityShipped,
                  input  Item.UomCode,
                  output cTempQuantityShipped).   

  assign pbgttOrderLineV1.cCustomerQuantityOnOrder = decimal(cTempCustomerQuantityOnOrder)
         pbgttOrderLineV1.cOriginalQuantityOpenOrdered = decimal(cTempOriginalQuantityOnOrder)
         pbgttOrderLineV1.cPacQuantityOpenOrder = decimal(pbgttOrderLineV1.cQuantityOpenOrdered)
         pbgttOrderLineV1.cQuantityAllocated = decimal(cTempQuantityAllocated)
         pbgttOrderLineV1.cQuantityShipped = decimal(cTempQuantityShipped)
      .

  pbgttOrderLineV1.AllowUpdateDescription = Item.AllowUpdateDescription.   

  find first OrderAllocLineDetail where OrderAllocLineDetail.ArEntity = pbgttOrderLineV1.ArEntity
                             and OrderAllocLineDetail.OrderNumber = pbgttOrderLineV1.OrderNumber
                             and OrderAllocLineDetail.OrderlineNumber = pbgttOrderLineV1.LineNumber 
                             and OrderAllocLineDetail.CustomerQuantityAllocated > 0 no-lock no-error.
  if avail(OrderAllocLineDetail) then
    pbgttOrderLineV1.AllocationIndicator = yes.
                       

  /* To Check Item  Type is Kit Or Option Type */
  IF AVAIL ItemStock THEN
  if ItemStock.ItemOrigin = "k":u then
  do:
    find first order where order.ArEntity    = pbgttOrderLineV1.ArEntity                     
                       and order.OrderNumber = pbgttOrderLineV1.OrderNumber no-lock no-error.
    if avail(Order) then
    do:       
      find last revision where revision.InEntity  = pbgttOrderLineV1.InEntity                     
                           and revision.ItemCode  = pbgttOrderLineV1.ItemCode                       
                           and revision.Effective le Order.OrderDate
                           and revision.Expiry    gt Order.OrderDate no-lock no-error.                        
      if avail(revision) then                     
        assign pbgttOrderLineV1.KitOptItem = revision.Type.
    end.    
  end.

  return true.

end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION CheckOrderStock a 
FUNCTION CheckOrderStock RETURNS LOGICAL
  (   INPUT TABLE FOR ttchkorderlinev1,
      OUTPUT pcmessage AS CHARACTER ) :
/*------------------------------------------------------------------------------
  Purpose:  check stock levels for ordered items
            check local warehouse stock
            cross docking warehouse stock
            planned work orders
    Notes:  
------------------------------------------------------------------------------*/

    DEFINE VARIABLE linsufficientstock AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE ilocalstock        AS INTEGER     NO-UNDO.
    DEFINE VARIABLE ixdstock           AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iwostock           AS INTEGER     NO-UNDO.
    
    DEFINE BUFFER xditemstock FOR itemstock.
    
    FOR EACH ttchkorderlinev1 BREAK BY ttchkorderlinev1.itemcode:

        FIND ITEM
            WHERE ITEM.InEntity = ttChkOrderLineV1.InEntity
            AND   ITEM.ItemCode = ttChkOrderLineV1.ItemCode
            NO-LOCK NO-ERROR.

        IF AVAILABLE (ITEM) AND ITEM.NonStock THEN
            NEXT.

        FIND itemstock NO-LOCK
            WHERE itemstock.inentity = ttchkorderlinev1.inentity
            AND   itemstock.itemcode = ttchkorderlinev1.itemcode
            AND   itemstock.warehousecode = ttchkorderlinev1.warehousecode {&xNoError}.
    
        FIND itemwhs NO-LOCK
            WHERE itemwhs.inentity = ttchkorderlinev1.inentity
            AND   itemwhs.itemcode = ttchkorderlinev1.itemcode
            AND   itemwhs.warehousecode = ttchkorderlinev1.warehousecode {&xNoError}.
    
        linsufficientstock = FALSE.
        
        IF AVAIL itemstock THEN
            ilocalstock =  itemstock.QuantityOnHand -
                           itemstock.QuantityOnPps  -
                           itemstock.QuantityAlloc.
        ELSE
            iLocalStock = 0.

        IF AVAILABLE itemwhs THEN DO:
            IF itemwhs.CrossDock THEN DO:
                FIND xditemstock NO-LOCK
                    WHERE xditemstock.inentity      = itemwhs.inentity
                    AND   xditemstock.itemcode      = itemwhs.itemcode
                    AND   xditemstock.warehousecode = itemwhs.CrossDockWarehouse {&xNoError}.

                IF AVAILABLE xdItemStock THEN
                    ixdstock =  xditemstock.QuantityOnHand -
                                xditemstock.QuantityOnPps  -
                                xditemstock.QuantityAlloc.
                ELSE
                    ixdstock = 0.

                iWoStock = (IF AVAIL ItemStock THEN ItemStock.QuantityOnWo ELSE 0).
                 /*
                  FOR EACH workorder NO-LOCK
                        WHERE workorder.EntityWip = itemstock.inentity
                        AND   workorder.ItemCode  = itemstock.itemcode
                        AND   workorder.ScheduledStatus <> "closed":u
                        AND   workorder.ScheduledStart >= TODAY:
                        iwostock = iwostock + WorkOrder.QuantityComplScheduled.
                   END.    */

            END.
        END.
          
        IF LAST-OF(ttchkorderlinev1.itemcode) THEN DO:

            IF ilocalstock + ixdstock + iwostock < ttchkorderlinev1.quantityopenordered THEN DO:

                pcmessage = pcmessage + (IF pcmessage = "":u THEN "":u ELSE CHR(10))
                          + SUBST("No stock available or due for orderline number &1 item &2":u,
                                ttchkorderlinev1.linenumber,
                                ttchkorderlinev1.itemcode).

                linsufficientstock = TRUE.

            END.

            ASSIGN ilocalstock = 0
                   iwostock    = 0
                   ixdstock    = 0.
        END.
    END.
    RETURN linsufficientstock = FALSE.   

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION deleteAllowed a 
FUNCTION deleteAllowed returns logical PRIVATE
  ( input phBuf as handle, pcOptions as char, output pcMsg as char ) :
/*------------------------------------------------------------------------------
 Used to check that we are allowed to delete the record pointed to by phBuf.
 It returns true if the delete is permitted and false if it is not. In the
 latter case pcMsg will contain the identifier of the message explaining
 why the delete could not be carried out.

 pcOptions contains modifiers to the function in the format 
 modifier1=value1,modifier2=value2 and can used to alter the behaviour of this
 routine for particular circumstances.
------------------------------------------------------------------------------*/

DEFINE VARIABLE hArEntity        AS HANDLE     NO-UNDO.
DEFINE VARIABLE hOrderNumber     AS HANDLE     NO-UNDO.
DEFINE VARIABLE hOrderLineNumber AS HANDLE     NO-UNDO.

  assign hArEntity        = phBuf:buffer-field("ArEntity":u)
         hOrderNumber     = phBuf:buffer-field("OrderNumber":u)
         hOrderLineNumber = phBuf:buffer-field("LineNumber":u).

  RUN ppsDetailsExist(INPUT hArEntity:BUFFER-VALUE,
                      INPUT hOrderNumber:BUFFER-VALUE,
                      INPUT hOrderLineNumber:BUFFER-VALUE,
                      OUTPUT pcMsg).

                                                                       
  IF pcMsg <> "":u THEN
      RETURN FALSE.

  return true.

end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION getCustMemo a 
FUNCTION getCustMemo RETURNS CHARACTER
  ( pcCustomerCode AS CHAR, pcInEntity AS CHAR, pcItemCode AS CHAR, pcGenericItemCode AS CHAR ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

    DEFINE VARIABLE cCustomerMemo AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE cArEntity AS CHARACTER  NO-UNDO.
   ASSIGN cArEntity = GetGlobalChar({&xcModEntPrefix} + STRING({&xiModAccountReceivable})).

    cCustomerMemo = "":u.

    FIND CustomerPricing WHERE CustomerPricing.CustomerCode  = pcCustomerCode
                         AND   CustomerPricing.ArEntity      = cArEntity
                         AND   CustomerPricing.ItemCode      = pcItemCode  
                         AND   CustomerPricing.Active        = YES 
                         AND   CustomerPricing.EffectiveDate LE TODAY  
                         AND   CustomerPricing.ExpiryDate    GE TODAY 
                         NO-LOCK NO-ERROR.

    IF NOT AVAIL(customerPricing) THEN 
      FIND CustomerPricing WHERE CustomerPricing.CustomerCode  = pcCustomerCode
                           AND   CustomerPricing.ArEntity      = cArEntity
                           AND   CustomerPricing.ItemCode      = pcGenericItemCode 
                           AND   CustomerPricing.Active        = YES 
                           AND   CustomerPricing.EffectiveDate LE TODAY  
                           AND   CustomerPricing.ExpiryDate    GE TODAY    
                           NO-LOCK NO-ERROR.
 

    IF AVAILABLE CustomerPricing THEN DO:
          FIND psMemo WHERE psmemo.psMemoId = CustomerPricing.psMemoId NO-LOCK NO-ERROR.
          IF AVAILABLE psmemo THEN cCustomerMemo = psMemo.MemoText. 
    END.

    RETURN cCustomerMemo.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION getNumAttributesForItem a 
FUNCTION getNumAttributesForItem RETURNS INTEGER
  ( pcItemCode AS CHAR , pcInEntity AS CHAR) :
/*------------------------------------------------------------------------------
  Purpose: find the number of attributes for an item 
    Notes:  
------------------------------------------------------------------------------*/

    DEFINE VARIABLE iCount AS INTEGER    NO-UNDO.

    FIND FIRST ITEM 
        WHERE ITEM.itemcode = pcItemCode 
        AND ITEM.InEntity   = pcInEntity 
        NO-LOCK NO-ERROR.

    IF NOT AVAIL ITEM THEN RETURN 0.

    FIND FIRST productgroup
        WHERE productgroup.prodgroup = ITEM.prodgroup NO-LOCK NO-ERROR.

    IF NOT AVAIL productgroup THEN RETURN 0.
                                  

    FOR EACH attribute NO-LOCK
        WHERE attribute.prodgroup = productgroup.prodgroup:
        icount = icount + 1.
    END.

    RETURN iCount.

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION HasLogoStockItem a 
FUNCTION HasLogoStockItem RETURNS LOGICAL
  ( cArEntity AS CHAR, iOrderNumber AS INT, iLineNumber AS INT ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

FOR EACH orderlogo WHERE orderlogo.arentity    = cArEntity AND
                         orderlogo.ordernumber = iOrderNumber AND
                         orderlogo.linenumber  = iLinenumber NO-LOCK.

    
        FIND FIRST CustomerLogo WHERE CustomerLogo.ArEntity     = OrderLogo.ArEntity AND
                                      CustomerLogo.CustomerCode = OrderLogo.CustomerCode AND
                                      CustomerLogo.LogoCode     = OrderLogo.LogoCode AND
                                      CustomerLogo.PositionCode = OrderLogo.PositionCode AND
                                      CustomerLogo.ItemCode     <> "" NO-LOCK NO-ERROR.

        IF AVAIL CustomerLogo THEN
            RETURN TRUE.
END.

RETURN FALSE.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION OrderEntryCustItemLookup a 
FUNCTION OrderEntryCustItemLookup RETURNS CHARACTER
  ( /* parameter-definitions */ ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

  FIND systemspecific NO-LOCK
      WHERE systemspecific.itemcode = "OrderEntryCustItemLookup" NO-ERROR.

  IF AVAIL systemspecific THEN
      RETURN systemspecific.Description.

  RETURN "".   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION populateKeyDesc a 
FUNCTION populateKeyDesc returns logical
  ( input phBuf as handle ) :
/*------------------------------------------------------------------------------
 Is passed the handle to a 'view' buffer (temp-table) to load the descriptions
 associated with foreign keys into the appropriate {&xcKeyDescSuffix} fields.
------------------------------------------------------------------------------*/
  {psobject/dac/getkeydscvar.i}


  {psobject/dac/getkeydesc.i &xViewField   = itemcode
                             &xLookupTable = ITEM
                             &xLookupField = itemcode
                             &xDescField   = description
                             &xEntityLookup = "and Item.InEntity = OrderLine.InEntity"} /* Optional */





  /* 29/07/2004 MAB */
  {psobject/dac/getkeydesc.i &xViewField   = WarehouseCode
                             &xLookupTable = Warehouse
                             &xLookupField = WarehouseCode
                             &xDescField   = DESCRIPTION}

/*  def buffer bItem for Item.
 *
 *   def var hItemDesc        as handle no-undo.
 *   def var hItemCode        as handle no-undo.
 *   def var hInEntity        as handle no-undo.
 *   def var hGenericItemLine as handle no-undo.
 *
 *   assign hItemCode        = phBuf:buffer-field("ItemCode":u)
 *          hInEntity        = phBuf:buffer-field("InEntity":u)
 * /*         hGenericItemLine = phBuf:buffer-field("GenericItemLine":u)*/
 *          hItemDesc        = phBuf:buffer-field("Description":u).
 *
 *   find first bItem where bItem.ItemCode = hItemCode:buffer-value
 *                      and bItem.InEntity = hInEntity:buffer-value
 *                      no-lock no-error.
 *   if avail(bItem) then
 *     assign  hItemDesc:buffer-value        = bItem.Description.
 * /*            hGenericItemLine:buffer-value = bItem.GenericItem.*/*/

  return true.

end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION PreDBUpdate a 
FUNCTION PreDBUpdate RETURNS LOGICAL
  ( /* parameter-definitions */ ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

  /* To increment RevisedDateCount on Value change of PromiseDate or requestDate */
    if gttOrderLineV1.PromiseDate <> OrderLine.PromiseDate or 
       gttOrderLineV1.RequestDate <> OrderLine.RequestDate then
       gttOrderLineV1.RevisedDateCount = gttOrderLineV1.RevisedDateCount + 1.

    /* assignment of Original Order Quantity to open Ordered */

    IF gttOrderLineV1.OriginalQuantityOpenOrdered = 0 THEN
       gttOrderLineV1.OriginalQuantityOpenOrdered = gttOrderLineV1.QuantityOpenOrdered.

  RETURN FALSE.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION ReturnShopCalendarDays a 
FUNCTION ReturnShopCalendarDays RETURNS INTEGER
      ( INPUT piLeadTimeDays AS INT,
        OUTPUT piNumberOfDays AS INT ) :
    /*------------------------------------------------------------------------------
      Purpose:  
        Notes:  
    ------------------------------------------------------------------------------*/

      /* DEFINE VARIABLE iLeadTimeDays     AS INTEGER NO-UNDO. */
      DEFINE VARIABLE tLeadTimePromDate AS DATE    NO-UNDO.
      DEFINE VARIABLE lNewRecord        AS LOGICAL NO-UNDO.
      DEFINE VARIABLE v-holidays        AS INTEGER NO-UNDO.
      DEFINE VARIABLE tdate             AS DATE    NO-UNDO.
      DEFINE VARIABLE i                 AS INT     NO-UNDO.
      DEFINE VARIABLE lWorkSaturday     AS LOGICAL NO-UNDO INITIAL TRUE.
      DEFINE VARIABLE lWorkSunday       AS LOGICAL NO-UNDO INITIAL TRUE.
      DEFINE VARIABLE lWorkMon          AS LOGICAL NO-UNDO INITIAL TRUE.
      DEFINE VARIABLE lWorkTue          AS LOGICAL NO-UNDO INITIAL TRUE.
      DEFINE VARIABLE lWorkWed          AS LOGICAL NO-UNDO INITIAL TRUE.
      DEFINE VARIABLE lWorkThur         AS LOGICAL NO-UNDO INITIAL TRUE.
      DEFINE VARIABLE lWorkFri          AS LOGICAL NO-UNDO INITIAL TRUE.
      DEFINE VARIABLE lholiday          AS LOGICAL NO-UNDO INITIAL FALSE.
      DEFINE VARIABLE iNumberOfDays     AS INT     NO-UNDO.

      DEFINE VARIABLE cArEntity         AS CHARACTER   NO-UNDO.
      DEFINE VARIABLE cEntityWIP        AS CHARACTER   NO-UNDO.

 cEntityWIP = getGlobalChar({&xcModEntPrefix} + string({&xiModPac})).
 cArEntity  = getGlobalChar({&xcModEntPrefix} + string({&xiModAccountReceivable})).


 FIND FIRST OpControl WHERE OpControl.ArEntity = cArEntity NO-LOCK NO-ERROR.
  IF AVAILABLE (OpControl) THEN
  DO.
     iNumberOfDays = INTEGER(piLeadTimeDays).
     IF OpControl.UseShopCalendar  THEN
     DO.
         /*
          *  Take into account weekends and add extra days for weekends
          */
         FIND FIRST WorkWeek WHERE WorkWeek.EntityWIP = cEntityWIP  NO-LOCK NO-ERROR.
         IF AVAIL WorkWeek THEN
             ASSIGN lWorkSunday   = WorkWeek.WorkDay1
                    lWorkSaturday = WorkWeek.WorkDay7
                    lWorkMon      = WorkWeek.WorkDay2
                    lWorkTue      = WorkWeek.WorkDay3
                    lWorkWed      = WorkWeek.WorkDay4
                    lWorkThur     = WorkWeek.WorkDay5
                    lWorkFri      = WorkWeek.WorkDay6.

         IF 
         NOT lWorkSunday   AND    
         NOT lWorkSaturday AND   
         NOT lWorkMon      AND   
         NOT lWorkTue      AND   
         NOT lWorkWed      AND   
         NOT lWorkThur     AND   
         NOT lWorkFri      THEN RETURN 0.

         tdate = (TODAY).
         iNumberOfDays = integer(piLeadTimeDays).
         i = integer(piLeadTimeDays).
         DO WHILE i > 0.   

             tdate = tdate + 1.

             FIND Holiday WHERE Holiday.EntityWip =  cEntityWIP AND Holiday.Holiday = tDate NO-LOCK NO-ERROR.
             IF AVAIL Holiday THEN
                 lHoliday = TRUE.
             ELSE
                 lHoliday = FALSE.

             IF ((WEEKDAY(tDate) = 1) AND NOT lWorkSunday) OR 
                ((WEEKDAY(tDate) = 7) AND NOT lWorkSaturday) OR
                ((WEEKDAY(tDate) = 2) AND NOT lWorkMon) OR
                ((WEEKDAY(tDate) = 3) AND NOT lWorkTue) OR
                ((WEEKDAY(tDate) = 4) AND NOT lWorkWed) OR
                ((WEEKDAY(tDate) = 5) AND NOT lWorkThur) OR
                ((WEEKDAY(tDate) = 6) AND NOT lWorkFri) OR
                 lholiday THEN do:

                 i = i + 1.

               iNumberOfDays = iNumberOfDays + 1.
             end.
             i = i - 1.

         END.
     END.
     ASSIGN piNumberOfDays = iNumberOfDays.
     RETURN piNumberOfDays.
   END.
   ELSE RETURN 0.   /* Function return value. */

 END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION valDaysToShip a 
FUNCTION valDaysToShip RETURNS CHARACTER
  ( input phDaysToShip as handle, 
    input plAddMode    as logical, 
    input pcMsg        as char ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
  if phDaysToShip:buffer-value le 0  then
    return "MustbeGreaterthan0":u.
  if phDaysToShip:buffer-value > 1000 then  
    return "MustbeLessthan1000":u.


end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION validateRow a 
FUNCTION validateRow returns character PRIVATE
  ( input phBuf as handle, plAdding as log, pcOptions as char ) :
/*------------------------------------------------------------------------------
 This is called to perform the inter-field validation on the row currently
 being processed by this DAC. It is called after all the individual field
 validation routines have been called.

 phBuf is the handle to the row we are validating.

 This function can also be used to change the values of fields in the buffer
 (using the field's buffer-value attribute).

 plAdding will be true if this routine is being called to validate a new row 
 that is to be added to the database and false if validating an existing row
 that is being modified.

 pcOptions contains modifiers to the function in the format 
 modifier1=value1,modifier2=value2 and can used to alter the behaviour of this
 routine for particular circumstances.

 It will return an identifier for a message describing any problems that are
 found or {&xcSuccess} if everything is OK.
------------------------------------------------------------------------------*/
  def var hItemCode      as handle no-undo.
  def var hWarehouseCode as handle no-undo.
  def var hInEntity      as handle no-undo.
  def var hOrderNumber   as handle no-undo.
  def var hKitCode       as handle no-undo.
  def var hUomCode       as handle no-undo.
  def var hBaseUomCode   as handle no-undo.
  def var hOrderDate     as handle no-undo.
  def var hGrossPrice    as handle no-undo.
  def var hPriceUomCode  as handle no-undo.
  def var hCustQtyOnOrder as handle no-undo.

  def var dNetPrice         as decimal no-undo.
  def var dBookingAmount    as decimal no-undo.
  def var dConversionFactor as decimal no-undo.
  def var cErrorlist        as char no-undo.
  def var lActiveCheck      as log  no-undo.

  DEFINE VARIABLE hRequestDate AS HANDLE     NO-UNDO.
  DEFINE VARIABLE hPromiseDate AS HANDLE     NO-UNDO.
  DEFINE VARIABLE hRevisedDate AS HANDLE     NO-UNDO.
  DEFINE VARIABLE hAREntity AS HANDLE  NO-UNDO.

  cErrorlist = "":u.

  DEFINE BUFFER xditemstock FOR itemstock.

  assign hItemCode         = phBuf:buffer-field("ItemCode":u)
         hAREntity         = phBuf:buffer-field("ArEntity":u)
         hInEntity         = phBuf:buffer-field("InEntity":u)
         hWarehouseCode    = phBuf:buffer-field("warehouseCode":u)
         hOrderNumber      = phBuf:buffer-field("OrderNumber":u)
         hKitCode          = phBuf:buffer-field("KitCode":u)
         hPriceUomCode     = phBuf:buffer-field("PriceUomCode":u)
         hUOMCode          = phBuf:buffer-field("UomCode":u)
         hBaseUomCode      = phBuf:buffer-field("BaseUomCode":u)
         hGrossPrice       = phBuf:buffer-field("GrossPrice":u)
         hOrderDate        = phBuf:buffer-field("OrderDate":u)
         hCustQtyOnOrder   = phBuf:buffer-field("CustomerQuantityOnOrder":u)
         hRequestDate      = phBuf:buffer-field("RequestDate":u)    
         hPromiseDate      = phBuf:buffer-field("PromiseDate":u)    
         hRevisedDate      = phBuf:buffer-field("RevisedPromiseDate":u).   

  find item where item.InEntity = hInEntity:buffer-value 
              and item.itemCode = hItemCode:buffer-value no-lock no-error.

  find Warehouse where Warehouse.Warehouse = hWarehouseCode:buffer-value no-lock no-error.


  IF hArEntity:BUFFER-VALUE <> warehouse.EntityInv THEN RETURN "CurrenciesMisMatchEntityInv":u. /*GW*/


  find Uom where Uom.UomCode = hUomCode:buffer-value no-lock no-error.

  if plAdding then 
  do:     
    IF NOT ITEM.GenericItem THEN
    DO:
        if hCustQtyOnOrder:buffer-value LE 0 then
        cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                     "PositiveQuantityOnly":u + {&xcMsgDelimiter} + hCustQtyOnOrder:name.

    END.
    if hItemCode:buffer-value eq "":u then
        cErrorList  = cErrorList + (if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                      "MustEnter":u + {&xcMsgArgDelim} + "an Item code" + {&xcMsgDelimiter} + hItemCode:name.

    if hItemCode:buffer-value = ? or hItemCode:buffer-value = "?":u then 
        cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                      "Invalid":u + {&xcMsgArgDelim} + "Item code":u + {&xcMsgDelimiter} + hItemCode:name.

    if not avail(item) and cErrorList = "":u then
    do:
      cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                   "InvalidItemCode":u + {&xcMsgArgDelim} + hItemCode:buffer-value + {&xcMsgDelimiter} + hItemCode:name.
    end.

    if avail(item) then
    do:
        FIND ItemStock NO-LOCK
            WHERE ItemStock.InEntity = ITEM.InEntity
              AND ItemStock.ItemCode = ITEM.ItemCode
              AND ItemStock.WarehouseCode = Warehouse.Warehousecode
            NO-ERROR.
      lActiveCheck = false.      
      IF AVAILABLE itemstock THEN DO:      
          if ItemStock.Active = no THEN DO:
            assign
                cErrorlist   = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +            
                             "InactiveItemCode":u + {&xcMsgArgDelim} + itemstock.itemcode
                lActiveCheck = true.                                            
          END.

          /*DM-if XD is in use then check the xdwarehouse record*/
          IF DYNAMIC-FUNCTION("XdInUse":U) THEN DO:
              FIND itemwhs NO-LOCK WHERE itemwhs.inentity = ITEM.inentity
                  AND itemwhs.itemcode = ITEM.itemcode
                  AND itemwhs.warehousecode = itemstock.warehousecode NO-ERROR.

              IF itemwhs.CrossDock THEN DO:
                  FIND xditemstock NO-LOCK WHERE xditemstock.inentity = ITEM.inentity
                      AND xditemstock.itemcode = ITEM.itemcode
                      AND xditemstock.warehousecode = itemwhs.crossdockwarehouse NO-ERROR.
                  IF xditemstock.ACTIVE = NO THEN DO:
                     if lActiveCheck = false then
                         cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                             "InactiveItemCodeXDWarehouse":u + {&xcMsgArgDelim} + itemwhs.crossdockwarehouse.
                  END.
              END.
          END.
    
            if AVAILABLE ItemStock AND ItemStock.Effective > hRequestDate:BUFFER-VALUE THEN
                cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                              "ItemEffectiveGTRequestDate":u + {&xcMsgArgDelim} 
                              + hItemCode:buffer-value + {&xcMsgArgDelim} 
                              + string(ItemStock.Effective) + {&xcMsgArgDelim}  
                              + hRequestDate:BUFFER-VALUE + {&xcMsgDelimiter} + hItemCode:name.
    
             if AVAILABLE ItemStock AND ItemStock.Effective > hPromiseDate:BUFFER-VALUE THEN
                 cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                               "ItemEffectiveGTPromiseDate":u + {&xcMsgArgDelim} 
                               + hItemCode:buffer-value + {&xcMsgArgDelim} 
                               + string(ItemStock.Effective) + {&xcMsgArgDelim}  
                               + hPromiseDate:BUFFER-VALUE + {&xcMsgDelimiter} + hItemCode:name.
    
              if AVAILABLE ItemStock AND ItemStock.Effective > hRevisedDate:BUFFER-VALUE THEN
                  cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                                "ItemEffectiveGTPromiseDate":u + {&xcMsgArgDelim} 
                                + hItemCode:buffer-value + {&xcMsgArgDelim} 
                                + string(ItemStock.Effective) + {&xcMsgArgDelim}  
                                + hRevisedDate:BUFFER-VALUE + {&xcMsgDelimiter} + hItemCode:name.
    
            if AVAILABLE ItemStock AND ItemStock.Expiry < hRequestDate:BUFFER-VALUE THEN
                cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                              "ItemExpiryLTRequestDate":u + {&xcMsgArgDelim} 
                              + hItemCode:buffer-value + {&xcMsgArgDelim} 
                              + string(ItemStock.Expiry) + {&xcMsgArgDelim}  
                              + hRequestDate:BUFFER-VALUE + {&xcMsgDelimiter} + hItemCode:name.
    
             if AVAILABLE ItemStock AND ItemStock.Expiry < hPromiseDate:BUFFER-VALUE THEN
                 cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                               "ItemExpiryLTPromiseDate":u + {&xcMsgArgDelim} 
                               + hItemCode:buffer-value + {&xcMsgArgDelim} 
                               + string(ItemStock.Expiry) + {&xcMsgArgDelim}  
                               + hPromiseDate:BUFFER-VALUE + {&xcMsgDelimiter} + hItemCode:name.
    
              if AVAILABLE ItemStock AND ItemStock.Expiry < hRevisedDate:BUFFER-VALUE THEN
                  cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                                "ItemExpiryLTRevisedDate":u + {&xcMsgArgDelim} 
                                + hItemCode:buffer-value + {&xcMsgArgDelim} 
                                + string(ItemStock.Expiry) + {&xcMsgArgDelim}  
                                + hRevisedDate:BUFFER-VALUE + {&xcMsgDelimiter} + hItemCode:name.
      END.
    end.
  end.

  if hGrossPrice:buffer-value < 0.00 then              /*nsMods*/
    cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                "GrossPriceLTZero":u + {&xcMsgDelimiter} + hGrossPrice:name.

  if hUomCode:buffer-value eq "":u then
      cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                   "UomsellingCannotbeBlank":u + {&xcMsgDelimiter} + hUomCode:name.

  if hUomCode:buffer-value = ? or hUomCode:buffer-value = "?":u then 
      cErrorList =  cErrorList + ( if cErrorList = "":u then "":u else {&xcMsgDelimiter}) + 
                    "Invalid":u + {&xcMsgArgDelim} + "selling uom code":u + {&xcMsgDelimiter} + hUomCode:name.

  if avail(uom) and avail(item) then
  do:
    if Uom.Active = no then
      cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                   "InactiveUomSelling":u + {&xcMsgDelimiter} + hUomCode:name.

    /* To Conversion Factor Exists or not */
    if hBaseUomCode:buffer-value ne ? and hBaseUomCode:buffer-value ne "":u then
    do:
      if hUomCode:buffer-value ne hBaseUomCode:buffer-value then
      do:
        dConversionFactor = ValidateUomConversion( input hBaseUomCode:buffer-value ,
                                                   input hUomCode:buffer-value ).       /*ns0512*/

        if dConversionFactor = ? then
          cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                       "NoConversionRecord":u + {&xcMsgArgDelim} + "customer uom " + caps(hBaseUomCode:buffer-value) 
                        + {&xcMsgArgDelim} + "item uom " + caps(hUomCode:buffer-value)  
                        + {&xcMsgDelimiter} + hUomCode:name.        
      end.    
    end. 

    if hPriceUomCode:buffer-value ne ? and hPriceUomCode:buffer-value ne "":u then
    do:
      if hUomCode:buffer-value ne hPriceUomCode:buffer-value then
      do:
        dConversionFactor = ValidateUomConversion( input hPriceUomCode:buffer-value ,
                                                   input hUomCode:buffer-value ).       /*ns0512*/

        if dConversionFactor = ? then
          cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                       "NoConversionRecord":u + {&xcMsgArgDelim} + "price uom " + caps(hPriceUomCode:buffer-value) 
                       + {&xcMsgArgDelim} + "item uom " + caps(hUomCode:buffer-value)  
                       + {&xcMsgDelimiter} + hUomCode:name.        
      end.    
    end. 
  end.

  /* If Item Type is "Kit" or "Opt" then check components exists or not */
  if avail(Item) and avail(Warehouse) then
  do:
    FIND FIRST ItemStock 
        WHERE ItemStock.InEntity      = hInEntity:buffer-value                
        AND   ItemStock.ItemCode      = hItemCode:buffer-value                      
        AND   ItemStock.WarehouseCode = hWarehouseCode:BUFFER-VALUE 
        NO-LOCK NO-ERROR.
    IF NOT AVAILABLE ItemStock THEN
      cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                   "InValidItemForWhsCode":u + {&xcMsgArgDelim} + hItemCode:buffer-value + {&xcMsgArgDelim} + hWarehouseCode:buffer-value + {&xcMsgDelimiter} + hItemCode:name.


    IF AVAILABLE ItemStock THEN DO:
        FIND FIRST ItemWhs 
            WHERE ItemWhs.InEntity      = hInEntity:buffer-value                
            AND   ItemWhs.ItemCode      = hItemCode:buffer-value                      
            AND   ItemWhs.WarehouseCode = hWarehouseCode:BUFFER-VALUE 
            NO-LOCK NO-ERROR.
        IF NOT AVAILABLE ItemWhs THEN
          cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                       "InValidItemForWhsCode":u + {&xcMsgArgDelim} + hItemCode:buffer-value + {&xcMsgArgDelim} + hWarehouseCode:buffer-value + {&xcMsgDelimiter} + hItemCode:name.

    END.

    if ItemStock.ItemOrigin = "k":u then
    do:
      find last revision where revision.InEntity  = hInEntity:buffer-value                     
                           and revision.ItemCode  = hItemCode:buffer-value                       
                           and revision.Effective le hRequestDate:buffer-value
                           and revision.Expiry    gt hRequestDate:buffer-value no-lock no-error.
      if not avail(revision) then       
        cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                     "RevisionDoesNotExists":u + {&xcMsgDelimiter} + hItemCode:name.                   

      for each component where component.InEntity  = revision.Inentity         
                           and component.ItemCode  = revision.ItemCode           
                           and component.Type      = revision.Type              
                           and component.Effective = revision.Effective no-lock:

          if not can-find ( first itemWhs where itemWhs.InEntity      = hInEntity:buffer-value
                                            and itemWhs.ItemCode      = component.Component
                                            and itemWhs.warehouseCode = hWarehouseCode:buffer-value) then
            cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                         "ComponentDoesNotExistInWhs":u + {&xcMsgArgDelim} + component.Component + {&xcMsgArgDelim} + hWarehouseCode:buffer-value + {&xcMsgDelimiter} + hItemCode:name.

          if not can-find(first ItemStock where ItemStock.InEntity      = hInEntity:buffer-value                
                                            and ItemStock.ItemCode      = component.ItemCode                      
                                            and ItemStock.WarehouseCode = hWarehouseCode:buffer-value) then                                          
            cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                         "InValidItemForWhsCode":u + {&xcMsgArgDelim} + component.ItemCode + {&xcMsgArgDelim} + hWarehouseCode:buffer-value + {&xcMsgDelimiter} + hItemCode:name.
      end.  
    end.
  end.

  if hCustQtyOnOrder:buffer-value LT 0 then
    cErrorlist = cErrorlist + (if cErrorlist = "":u then "":u else {&xcMsgDelimiter}) +
                 "NegativeQuantityOnOrder":u + {&xcMsgDelimiter} + hCustQtyOnOrder:name.

  if cErrorlist <> "":u then
    return cErrorlist.
  else
    return {&xcSuccess}.

end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION validItem a 
FUNCTION validItem RETURNS CHARACTER
  ( input  pcInEntity    as char,
    input  pcItemCode    as char,
    output pcMsg         as char) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

  find first item where item.ItemCode = pcItemCode 
                    and item.InEntity = pcInEntity no-lock no-error.

  if not avail(item) then
    return "InvalidItemForEntity":u.
  ELSE RETURN ?.

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION valPromiseDate a 
FUNCTION valPromiseDate RETURNS CHARACTER
  ( input phPromiseDate as handle, 
    input plAddMode    as logical, 
    input pcMsg        as char ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

  if phPromiseDate:buffer-value eq "":u or phPromiseDate:buffer-value eq ? then
    return "InvalidPromiseDate":u.


end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION valRequestDate a 
FUNCTION valRequestDate RETURNS CHARACTER
  ( input phRequestDate as handle, 
    input plAddMode    as logical, 
    input pcMsg        as char ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
  if phRequestDate:buffer-value eq "":u or phRequestDate:buffer-value eq ? then
    return "InvalidRequestDate":u.

end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION valVolumeDiscount a 
FUNCTION valVolumeDiscount RETURNS CHARACTER
  ( input phVolumeDiscount as handle, 
    input plAddMode  as logical, 
    input pcMsg      as char ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

  if phVolumeDiscount:buffer-value lt 0 or phVolumeDiscount:buffer-value eq ? then
    return "InvalidVolumeDiscount":u.

end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION valWarehouseCode a 
FUNCTION valWarehouseCode RETURNS CHARACTER
  ( input phWarehouseCode as handle, 
    input plAddMode       as logical, 
    input pcMsg           as char ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
  DEFINE VARIABLE cLoggedEntity AS CHARACTER   NO-UNDO.
  if plAddMode then
  do:
    if phWarehouseCode:buffer-value eq "":u then
      return "WarehouseCodecannotbeBlank":u.

    find Warehouse where Warehouse.WarehouseCode = phWarehouseCode:buffer-value no-lock no-error. 

    if not avail(Warehouse) then
      return "InvalidWarehouse":u.

    if not Warehouse.Active then
      return "InactiveWarehouseCode":u.        

    if Warehouse.WhsType = {&xcWhsTypeInspect} then 
      return "InspectionWarehouse":u.

    if  Warehouse.WhsType = {&xcWhsTypeTransit} then 
      return "TransitWarehouse":u.
  end.

/*  /*V7 Mods*/
  ASSIGN cLoggedEntity = GetGlobalChar('CurrentEntityCode').
  FIND Entity 
     WHERE Entity.EntityCode = cLoggedEntity
     NO-LOCK NO-ERROR.
  IF AVAILABLE entity THEN DO: 
     IF Entity.DefaultBaseCurrCode <> Warehouse.DefaultBaseCurrCode THEN
        RETURN "CurrenciesMisMatchEntityInv":u.
  END. */
end function.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION XDInUse a 
FUNCTION XDInUse RETURNS LOGICAL
  ( /* parameter-definitions */ ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

  FIND SystemSpecific NO-LOCK
      WHERE SystemSpecific.ItemCode = "CrossDockingInUse":u NO-ERROR.

  IF AVAIL SystemSpecific THEN
      IF SystemSpecific.DESCRIPTION = "YES":u THEN
          RETURN TRUE.

  RETURN FALSE.

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

