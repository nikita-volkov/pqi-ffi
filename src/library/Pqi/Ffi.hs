-- | The FFI adapter, backed by @postgresql-libpq@.
--
-- 'Connection' wraps the C-backed @PGconn@.
--
-- Each method is a near-mechanical delegation to the matching
-- @Database.PostgreSQL.LibPQ@ function, with the only work being the
-- conversion between this family's portable types (OIDs as 'Word32', indices
-- as 'Int32', the shared enums) and @postgresql-libpq@'s C-specific newtypes.
module Pqi.Ffi
  ( Connection,
  )
where

import qualified Database.PostgreSQL.LibPQ as Pq
import qualified Pqi
import Pqi.Ffi.Prelude

-- | A handle to a PostgreSQL connection backed by the C @libpq@ library.
newtype Connection = Connection Pq.Connection

-- | A result handle backed by a C @PGresult@.
newtype Result = Result Pq.Result

-- | A cancellation handle backed by a C @PGcancel@.
newtype Cancel = Cancel Pq.Cancel

instance Pqi.IsResult Result where
  resultStatus (Result r) = fromExecStatus <$> Pq.resultStatus r
  resultErrorMessage (Result r) = Pq.resultErrorMessage r
  resultErrorField (Result r) field = Pq.resultErrorField r (toFieldCode field)
  unsafeFreeResult (Result r) = Pq.unsafeFreeResult r
  ntuples (Result r) = fromRow <$> Pq.ntuples r
  nfields (Result r) = fromColumn <$> Pq.nfields r
  fname (Result r) column = Pq.fname r (toColumn column)
  fnumber (Result r) name = fmap fromColumn <$> Pq.fnumber r name
  ftable (Result r) column = fromOid <$> Pq.ftable r (toColumn column)
  ftablecol (Result r) column = fromColumn <$> Pq.ftablecol r (toColumn column)
  fformat (Result r) column = fromFormat <$> Pq.fformat r (toColumn column)
  ftype (Result r) column = fromOid <$> Pq.ftype r (toColumn column)
  fmod (Result r) column = Pq.fmod r (toColumn column)
  fsize (Result r) column = Pq.fsize r (toColumn column)
  getvalue (Result r) row column = Pq.getvalue r (toRow row) (toColumn column)
  getvalue' (Result r) row column = Pq.getvalue' r (toRow row) (toColumn column)
  getisnull (Result r) row column = Pq.getisnull r (toRow row) (toColumn column)
  getlength (Result r) row column = Pq.getlength r (toRow row) (toColumn column)
  nparams (Result r) = fromIntegral <$> Pq.nparams r
  paramtype (Result r) index = fromOid <$> Pq.paramtype r (fromIntegral index)
  cmdStatus (Result r) = Pq.cmdStatus r
  cmdTuples (Result r) = Pq.cmdTuples r

instance Pqi.IsCancel Cancel where
  cancel (Cancel handle) = Pq.cancel handle

instance Pqi.IsConnection Connection where
  type ResultOf Connection = Result
  type CancelOf Connection = Cancel

  connectdb conninfo = Connection <$> Pq.connectdb conninfo
  connectStart conninfo = Connection <$> Pq.connectStart conninfo
  connectPoll (Connection c) = fromPollingStatus <$> Pq.connectPoll c
  newNullConnection = Connection <$> Pq.newNullConnection
  isNullConnection (Connection c) = Pq.isNullConnection c
  finish (Connection c) = Pq.finish c
  reset (Connection c) = Pq.reset c
  resetStart (Connection c) = Pq.resetStart c
  resetPoll (Connection c) = fromPollingStatus <$> Pq.resetPoll c
  db (Connection c) = Pq.db c
  user (Connection c) = Pq.user c
  pass (Connection c) = Pq.pass c
  host (Connection c) = Pq.host c
  port (Connection c) = Pq.port c
  options (Connection c) = Pq.options c
  status (Connection c) = fromConnStatus <$> Pq.status c
  transactionStatus (Connection c) = fromTransactionStatus <$> Pq.transactionStatus c
  parameterStatus (Connection c) name = Pq.parameterStatus c name
  protocolVersion (Connection c) = Pq.protocolVersion c
  serverVersion (Connection c) = Pq.serverVersion c
  errorMessage (Connection c) = Pq.errorMessage c
  socket (Connection c) = Pq.socket c
  backendPID (Connection c) = fromIntegral <$> Pq.backendPID c
  connectionNeedsPassword (Connection c) = Pq.connectionNeedsPassword c
  connectionUsedPassword (Connection c) = Pq.connectionUsedPassword c

  exec (Connection c) sql =
    fmap Result <$> Pq.exec c sql
  execParams (Connection c) sql params resultFormat =
    fmap Result <$> Pq.execParams c sql (fmap (fmap toParam) params) (toFormat resultFormat)
  prepare (Connection c) name sql paramTypes =
    fmap Result <$> Pq.prepare c name sql (fmap (fmap toOid) paramTypes)
  execPrepared (Connection c) name params resultFormat =
    fmap Result <$> Pq.execPrepared c name (fmap (fmap toBoundParam) params) (toFormat resultFormat)
  describePrepared (Connection c) name =
    fmap Result <$> Pq.describePrepared c name
  describePortal (Connection c) name =
    fmap Result <$> Pq.describePortal c name

  escapeStringConn (Connection c) = Pq.escapeStringConn c
  escapeByteaConn (Connection c) = Pq.escapeByteaConn c
  escapeIdentifier (Connection c) = Pq.escapeIdentifier c

  sendQuery (Connection c) sql = Pq.sendQuery c sql
  sendQueryParams (Connection c) sql params resultFormat =
    Pq.sendQueryParams c sql (fmap (fmap toParam) params) (toFormat resultFormat)
  sendPrepare (Connection c) name sql paramTypes =
    Pq.sendPrepare c name sql (fmap (fmap toOid) paramTypes)
  sendQueryPrepared (Connection c) name params resultFormat =
    Pq.sendQueryPrepared c name (fmap (fmap toBoundParam) params) (toFormat resultFormat)
  sendDescribePrepared (Connection c) name = Pq.sendDescribePrepared c name
  sendDescribePortal (Connection c) name = Pq.sendDescribePortal c name
  getResult (Connection c) = fmap Result <$> Pq.getResult c
  consumeInput (Connection c) = Pq.consumeInput c
  isBusy (Connection c) = Pq.isBusy c
  setnonblocking (Connection c) nonBlocking = Pq.setnonblocking c nonBlocking
  isnonblocking (Connection c) = Pq.isnonblocking c
  setSingleRowMode (Connection c) = Pq.setSingleRowMode c
  flush (Connection c) = fromFlushStatus <$> Pq.flush c

  pipelineStatus (Connection c) = fromPipelineStatus <$> Pq.pipelineStatus c
  enterPipelineMode (Connection c) = Pq.enterPipelineMode c
  exitPipelineMode (Connection c) = Pq.exitPipelineMode c
  pipelineSync (Connection c) = Pq.pipelineSync c
  sendFlushRequest (Connection c) = Pq.sendFlushRequest c

  getCancel (Connection c) = fmap Cancel <$> Pq.getCancel c

  notifies (Connection c) = fmap fromNotify <$> Pq.notifies c
  disableNoticeReporting (Connection c) = Pq.disableNoticeReporting c
  enableNoticeReporting (Connection c) = Pq.enableNoticeReporting c
  getNotice (Connection c) = Pq.getNotice c

  putCopyData (Connection c) value = fromCopyInResult <$> Pq.putCopyData c value
  putCopyEnd (Connection c) reason = fromCopyInResult <$> Pq.putCopyEnd c reason
  getCopyData (Connection c) nonBlocking = fromCopyOutResult <$> Pq.getCopyData c nonBlocking

  loCreat (Connection c) = fmap fromOid <$> Pq.loCreat c
  loCreate (Connection c) oid = fmap fromOid <$> Pq.loCreate c (toOid oid)
  loImport (Connection c) path = fmap fromOid <$> Pq.loImport c path
  loImportWithOid (Connection c) path oid = fmap fromOid <$> Pq.loImportWithOid c path (toOid oid)
  loExport (Connection c) oid path = Pq.loExport c (toOid oid) path
  loOpen (Connection c) oid mode = fmap fromLibPQLoFd <$> Pq.loOpen c (toOid oid) mode
  loWrite (Connection c) fd value = Pq.loWrite c (toLibPQLoFd fd) value
  loRead (Connection c) fd len = Pq.loRead c (toLibPQLoFd fd) len
  loSeek (Connection c) fd mode offset = Pq.loSeek c (toLibPQLoFd fd) mode offset
  loTell (Connection c) fd = Pq.loTell c (toLibPQLoFd fd)
  loTruncate (Connection c) fd len = Pq.loTruncate c (toLibPQLoFd fd) len
  loClose (Connection c) fd = Pq.loClose c (toLibPQLoFd fd)
  loUnlink (Connection c) oid = Pq.loUnlink c (toOid oid)

  clientEncoding (Connection c) = Pq.clientEncoding c
  setClientEncoding (Connection c) encoding = Pq.setClientEncoding c encoding
  setErrorVerbosity (Connection c) verbosity =
    fromVerbosity <$> Pq.setErrorVerbosity c (toVerbosity verbosity)

-- * Type conversions

toParam :: (Word32, ByteString, Pqi.Format) -> (Pq.Oid, ByteString, Pq.Format)
toParam (oid, value, format) = (toOid oid, value, toFormat format)

toBoundParam :: (ByteString, Pqi.Format) -> (ByteString, Pq.Format)
toBoundParam (value, format) = (value, toFormat format)

toOid :: Word32 -> Pq.Oid
toOid = Pq.Oid . fromIntegral

fromOid :: Pq.Oid -> Word32
fromOid (Pq.Oid value) = fromIntegral value

toRow :: Int32 -> Pq.Row
toRow = Pq.toRow

fromRow :: Pq.Row -> Int32
fromRow = fromIntegral . fromEnum

toColumn :: Int32 -> Pq.Column
toColumn = Pq.toColumn

fromColumn :: Pq.Column -> Int32
fromColumn = fromIntegral . fromEnum

toLibPQLoFd :: Int32 -> Pq.LoFd
toLibPQLoFd = Pq.LoFd . fromIntegral

fromLibPQLoFd :: Pq.LoFd -> Int32
fromLibPQLoFd (Pq.LoFd fd) = fromIntegral fd

fromNotify :: Pq.Notify -> Pqi.Notify
fromNotify notification =
  Pqi.Notify
    { Pqi.relname = Pq.notifyRelname notification,
      Pqi.bePid = fromIntegral (Pq.notifyBePid notification),
      Pqi.extra = Pq.notifyExtra notification
    }

toFormat :: Pqi.Format -> Pq.Format
toFormat = \case
  Pqi.Text -> Pq.Text
  Pqi.Binary -> Pq.Binary

fromFormat :: Pq.Format -> Pqi.Format
fromFormat = \case
  Pq.Text -> Pqi.Text
  Pq.Binary -> Pqi.Binary

fromExecStatus :: Pq.ExecStatus -> Pqi.ExecStatus
fromExecStatus = \case
  Pq.EmptyQuery -> Pqi.EmptyQuery
  Pq.CommandOk -> Pqi.CommandOk
  Pq.TuplesOk -> Pqi.TuplesOk
  Pq.CopyOut -> Pqi.CopyOut
  Pq.CopyIn -> Pqi.CopyIn
  Pq.CopyBoth -> Pqi.CopyBoth
  Pq.BadResponse -> Pqi.BadResponse
  Pq.NonfatalError -> Pqi.NonfatalError
  Pq.FatalError -> Pqi.FatalError
  Pq.SingleTuple -> Pqi.SingleTuple
  Pq.PipelineSync -> Pqi.PipelineSync
  Pq.PipelineAbort -> Pqi.PipelineAbort

fromConnStatus :: Pq.ConnStatus -> Pqi.ConnStatus
fromConnStatus = \case
  Pq.ConnectionOk -> Pqi.ConnectionOk
  Pq.ConnectionBad -> Pqi.ConnectionBad
  Pq.ConnectionStarted -> Pqi.ConnectionStarted
  Pq.ConnectionMade -> Pqi.ConnectionMade
  Pq.ConnectionAwaitingResponse -> Pqi.ConnectionAwaitingResponse
  Pq.ConnectionAuthOk -> Pqi.ConnectionAuthOk
  Pq.ConnectionSetEnv -> Pqi.ConnectionSetEnv
  Pq.ConnectionSSLStartup -> Pqi.ConnectionSSLStartup

fromTransactionStatus :: Pq.TransactionStatus -> Pqi.TransactionStatus
fromTransactionStatus = \case
  Pq.TransIdle -> Pqi.TransIdle
  Pq.TransActive -> Pqi.TransActive
  Pq.TransInTrans -> Pqi.TransInTrans
  Pq.TransInError -> Pqi.TransInError
  Pq.TransUnknown -> Pqi.TransUnknown

fromPollingStatus :: Pq.PollingStatus -> Pqi.PollingStatus
fromPollingStatus = \case
  Pq.PollingFailed -> Pqi.PollingFailed
  Pq.PollingReading -> Pqi.PollingReading
  Pq.PollingWriting -> Pqi.PollingWriting
  Pq.PollingOk -> Pqi.PollingOk

fromPipelineStatus :: Pq.PipelineStatus -> Pqi.PipelineStatus
fromPipelineStatus = \case
  Pq.PipelineOn -> Pqi.PipelineOn
  Pq.PipelineOff -> Pqi.PipelineOff
  Pq.PipelineAborted -> Pqi.PipelineAborted

fromFlushStatus :: Pq.FlushStatus -> Pqi.FlushStatus
fromFlushStatus = \case
  Pq.FlushOk -> Pqi.FlushOk
  Pq.FlushFailed -> Pqi.FlushFailed
  Pq.FlushWriting -> Pqi.FlushWriting

fromCopyInResult :: Pq.CopyInResult -> Pqi.CopyInResult
fromCopyInResult = \case
  Pq.CopyInOk -> Pqi.CopyInOk
  Pq.CopyInError -> Pqi.CopyInError
  Pq.CopyInWouldBlock -> Pqi.CopyInWouldBlock

fromCopyOutResult :: Pq.CopyOutResult -> Pqi.CopyOutResult
fromCopyOutResult = \case
  Pq.CopyOutRow value -> Pqi.CopyOutRow value
  Pq.CopyOutWouldBlock -> Pqi.CopyOutWouldBlock
  Pq.CopyOutDone -> Pqi.CopyOutDone
  Pq.CopyOutError -> Pqi.CopyOutError

toVerbosity :: Pqi.Verbosity -> Pq.Verbosity
toVerbosity = \case
  Pqi.ErrorsTerse -> Pq.ErrorsTerse
  Pqi.ErrorsDefault -> Pq.ErrorsDefault
  Pqi.ErrorsVerbose -> Pq.ErrorsVerbose

fromVerbosity :: Pq.Verbosity -> Pqi.Verbosity
fromVerbosity = \case
  Pq.ErrorsTerse -> Pqi.ErrorsTerse
  Pq.ErrorsDefault -> Pqi.ErrorsDefault
  Pq.ErrorsVerbose -> Pqi.ErrorsVerbose

toFieldCode :: Pqi.FieldCode -> Pq.FieldCode
toFieldCode = \case
  Pqi.DiagSeverity -> Pq.DiagSeverity
  Pqi.DiagSqlstate -> Pq.DiagSqlstate
  Pqi.DiagMessagePrimary -> Pq.DiagMessagePrimary
  Pqi.DiagMessageDetail -> Pq.DiagMessageDetail
  Pqi.DiagMessageHint -> Pq.DiagMessageHint
  Pqi.DiagStatementPosition -> Pq.DiagStatementPosition
  Pqi.DiagInternalPosition -> Pq.DiagInternalPosition
  Pqi.DiagInternalQuery -> Pq.DiagInternalQuery
  Pqi.DiagContext -> Pq.DiagContext
  Pqi.DiagSourceFile -> Pq.DiagSourceFile
  Pqi.DiagSourceLine -> Pq.DiagSourceLine
  Pqi.DiagSourceFunction -> Pq.DiagSourceFunction
