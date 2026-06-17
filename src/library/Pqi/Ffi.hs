-- | The FFI adapter, backed by @postgresql-libpq@.
--
-- 'Connection' wraps the C-backed @PGconn@. Its 'FfiResult' wraps a
-- @PGresult@ and its 'FfiCancel' a @PGcancel@. Being a complete binding, it
-- provides 'IsResult', 'IsCancel', and 'IsConnection' instances for these
-- types. Each method is a near-mechanical delegation to the matching
-- @Database.PostgreSQL.LibPQ@ function, with the only work being the
-- conversion between this family's portable types (OIDs as 'Word32', indices
-- as 'Int32', the shared enums) and @postgresql-libpq@'s C-specific newtypes.
module Pqi.Ffi
  ( FfiResult (..),
    FfiCancel (..),
    Connection (..),
    libpqVersion,
  )
where

import qualified Database.PostgreSQL.LibPQ as LibPQ
import Pqi
  ( IsCancel (..),
    IsConnection (..),
    IsResult (..),
  )
import qualified Pqi
import Pqi.Ffi.Prelude

-- | A handle to a PostgreSQL connection backed by the C @libpq@ library.
newtype Connection = Connection LibPQ.Connection

-- | A result handle backed by a C @PGresult@.
newtype FfiResult = FfiResult LibPQ.Result

-- | A cancellation handle backed by a C @PGcancel@.
newtype FfiCancel = FfiCancel LibPQ.Cancel

-- | The version of the @libpq@ library in use, as an integer of the form
-- @MMmmpp@. This is inherently specific to the FFI adapter, so it lives here
-- rather than in the driver-agnostic interface.
libpqVersion :: IO Int
libpqVersion = LibPQ.libpqVersion

instance IsResult FfiResult where
  resultStatus (FfiResult r) = fromExecStatus <$> LibPQ.resultStatus r
  resultErrorMessage (FfiResult r) = LibPQ.resultErrorMessage r
  resultErrorField (FfiResult r) field = LibPQ.resultErrorField r (toFieldCode field)
  unsafeFreeResult (FfiResult r) = LibPQ.unsafeFreeResult r
  ntuples (FfiResult r) = fromRow <$> LibPQ.ntuples r
  nfields (FfiResult r) = fromColumn <$> LibPQ.nfields r
  fname (FfiResult r) column = LibPQ.fname r (toColumn column)
  fnumber (FfiResult r) name = fmap fromColumn <$> LibPQ.fnumber r name
  ftable (FfiResult r) column = fromOid <$> LibPQ.ftable r (toColumn column)
  ftablecol (FfiResult r) column = fromColumn <$> LibPQ.ftablecol r (toColumn column)
  fformat (FfiResult r) column = fromFormat <$> LibPQ.fformat r (toColumn column)
  ftype (FfiResult r) column = fromOid <$> LibPQ.ftype r (toColumn column)
  fmod (FfiResult r) column = LibPQ.fmod r (toColumn column)
  fsize (FfiResult r) column = LibPQ.fsize r (toColumn column)
  getvalue (FfiResult r) row column = LibPQ.getvalue r (toRow row) (toColumn column)
  getvalue' (FfiResult r) row column = LibPQ.getvalue' r (toRow row) (toColumn column)
  getisnull (FfiResult r) row column = LibPQ.getisnull r (toRow row) (toColumn column)
  getlength (FfiResult r) row column = LibPQ.getlength r (toRow row) (toColumn column)
  nparams (FfiResult r) = fromIntegral <$> LibPQ.nparams r
  paramtype (FfiResult r) index = fromOid <$> LibPQ.paramtype r (fromIntegral index)
  cmdStatus (FfiResult r) = LibPQ.cmdStatus r
  cmdTuples (FfiResult r) = LibPQ.cmdTuples r

instance IsCancel FfiCancel where
  cancel (FfiCancel handle) = LibPQ.cancel handle

instance IsConnection Connection where
  type ResultOf Connection = FfiResult
  type CancelOf Connection = FfiCancel

  connectdb conninfo = Connection <$> LibPQ.connectdb conninfo
  connectStart conninfo = Connection <$> LibPQ.connectStart conninfo
  connectPoll (Connection c) = fromPollingStatus <$> LibPQ.connectPoll c
  newNullConnection = Connection <$> LibPQ.newNullConnection
  isNullConnection (Connection c) = LibPQ.isNullConnection c
  finish (Connection c) = LibPQ.finish c
  reset (Connection c) = LibPQ.reset c
  resetStart (Connection c) = LibPQ.resetStart c
  resetPoll (Connection c) = fromPollingStatus <$> LibPQ.resetPoll c
  db (Connection c) = LibPQ.db c
  user (Connection c) = LibPQ.user c
  pass (Connection c) = LibPQ.pass c
  host (Connection c) = LibPQ.host c
  port (Connection c) = LibPQ.port c
  options (Connection c) = LibPQ.options c
  status (Connection c) = fromConnStatus <$> LibPQ.status c
  transactionStatus (Connection c) = fromTransactionStatus <$> LibPQ.transactionStatus c
  parameterStatus (Connection c) name = LibPQ.parameterStatus c name
  protocolVersion (Connection c) = LibPQ.protocolVersion c
  serverVersion (Connection c) = LibPQ.serverVersion c
  errorMessage (Connection c) = LibPQ.errorMessage c
  socket (Connection c) = LibPQ.socket c
  backendPID (Connection c) = fromIntegral <$> LibPQ.backendPID c
  connectionNeedsPassword (Connection c) = LibPQ.connectionNeedsPassword c
  connectionUsedPassword (Connection c) = LibPQ.connectionUsedPassword c

  exec (Connection c) sql =
    fmap FfiResult <$> LibPQ.exec c sql
  execParams (Connection c) sql params resultFormat =
    fmap FfiResult <$> LibPQ.execParams c sql (fmap (fmap toParam) params) (toFormat resultFormat)
  prepare (Connection c) name sql paramTypes =
    fmap FfiResult <$> LibPQ.prepare c name sql (fmap (fmap toOid) paramTypes)
  execPrepared (Connection c) name params resultFormat =
    fmap FfiResult <$> LibPQ.execPrepared c name (fmap (fmap toBoundParam) params) (toFormat resultFormat)
  describePrepared (Connection c) name =
    fmap FfiResult <$> LibPQ.describePrepared c name
  describePortal (Connection c) name =
    fmap FfiResult <$> LibPQ.describePortal c name

  escapeStringConn (Connection c) = LibPQ.escapeStringConn c
  escapeByteaConn (Connection c) = LibPQ.escapeByteaConn c
  escapeIdentifier (Connection c) = LibPQ.escapeIdentifier c

  sendQuery (Connection c) sql = LibPQ.sendQuery c sql
  sendQueryParams (Connection c) sql params resultFormat =
    LibPQ.sendQueryParams c sql (fmap (fmap toParam) params) (toFormat resultFormat)
  sendPrepare (Connection c) name sql paramTypes =
    LibPQ.sendPrepare c name sql (fmap (fmap toOid) paramTypes)
  sendQueryPrepared (Connection c) name params resultFormat =
    LibPQ.sendQueryPrepared c name (fmap (fmap toBoundParam) params) (toFormat resultFormat)
  sendDescribePrepared (Connection c) name = LibPQ.sendDescribePrepared c name
  sendDescribePortal (Connection c) name = LibPQ.sendDescribePortal c name
  getResult (Connection c) = fmap FfiResult <$> LibPQ.getResult c
  consumeInput (Connection c) = LibPQ.consumeInput c
  isBusy (Connection c) = LibPQ.isBusy c
  setnonblocking (Connection c) nonBlocking = LibPQ.setnonblocking c nonBlocking
  isnonblocking (Connection c) = LibPQ.isnonblocking c
  setSingleRowMode (Connection c) = LibPQ.setSingleRowMode c
  flush (Connection c) = fromFlushStatus <$> LibPQ.flush c

  pipelineStatus (Connection c) = fromPipelineStatus <$> LibPQ.pipelineStatus c
  enterPipelineMode (Connection c) = LibPQ.enterPipelineMode c
  exitPipelineMode (Connection c) = LibPQ.exitPipelineMode c
  pipelineSync (Connection c) = LibPQ.pipelineSync c
  sendFlushRequest (Connection c) = LibPQ.sendFlushRequest c

  getCancel (Connection c) = fmap FfiCancel <$> LibPQ.getCancel c

  notifies (Connection c) = fmap fromNotify <$> LibPQ.notifies c
  disableNoticeReporting (Connection c) = LibPQ.disableNoticeReporting c
  enableNoticeReporting (Connection c) = LibPQ.enableNoticeReporting c
  getNotice (Connection c) = LibPQ.getNotice c

  putCopyData (Connection c) value = fromCopyInResult <$> LibPQ.putCopyData c value
  putCopyEnd (Connection c) reason = fromCopyInResult <$> LibPQ.putCopyEnd c reason
  getCopyData (Connection c) nonBlocking = fromCopyOutResult <$> LibPQ.getCopyData c nonBlocking

  loCreat (Connection c) = fmap fromOid <$> LibPQ.loCreat c
  loCreate (Connection c) oid = fmap fromOid <$> LibPQ.loCreate c (toOid oid)
  loImport (Connection c) path = fmap fromOid <$> LibPQ.loImport c path
  loImportWithOid (Connection c) path oid = fmap fromOid <$> LibPQ.loImportWithOid c path (toOid oid)
  loExport (Connection c) oid path = LibPQ.loExport c (toOid oid) path
  loOpen (Connection c) oid mode = fmap fromLibPQLoFd <$> LibPQ.loOpen c (toOid oid) mode
  loWrite (Connection c) fd value = LibPQ.loWrite c (toLibPQLoFd fd) value
  loRead (Connection c) fd len = LibPQ.loRead c (toLibPQLoFd fd) len
  loSeek (Connection c) fd mode offset = LibPQ.loSeek c (toLibPQLoFd fd) mode offset
  loTell (Connection c) fd = LibPQ.loTell c (toLibPQLoFd fd)
  loTruncate (Connection c) fd len = LibPQ.loTruncate c (toLibPQLoFd fd) len
  loClose (Connection c) fd = LibPQ.loClose c (toLibPQLoFd fd)
  loUnlink (Connection c) oid = LibPQ.loUnlink c (toOid oid)

  clientEncoding (Connection c) = LibPQ.clientEncoding c
  setClientEncoding (Connection c) encoding = LibPQ.setClientEncoding c encoding
  setErrorVerbosity (Connection c) verbosity =
    fromVerbosity <$> LibPQ.setErrorVerbosity c (toVerbosity verbosity)

-- * Type conversions

toParam :: (Word32, ByteString, Pqi.Format) -> (LibPQ.Oid, ByteString, LibPQ.Format)
toParam (oid, value, format) = (toOid oid, value, toFormat format)

toBoundParam :: (ByteString, Pqi.Format) -> (ByteString, LibPQ.Format)
toBoundParam (value, format) = (value, toFormat format)

toOid :: Word32 -> LibPQ.Oid
toOid = LibPQ.Oid . fromIntegral

fromOid :: LibPQ.Oid -> Word32
fromOid (LibPQ.Oid value) = fromIntegral value

toRow :: Int32 -> LibPQ.Row
toRow = LibPQ.toRow

fromRow :: LibPQ.Row -> Int32
fromRow = fromIntegral . fromEnum

toColumn :: Int32 -> LibPQ.Column
toColumn = LibPQ.toColumn

fromColumn :: LibPQ.Column -> Int32
fromColumn = fromIntegral . fromEnum

toLibPQLoFd :: Int32 -> LibPQ.LoFd
toLibPQLoFd = LibPQ.LoFd . fromIntegral

fromLibPQLoFd :: LibPQ.LoFd -> Int32
fromLibPQLoFd (LibPQ.LoFd fd) = fromIntegral fd

fromNotify :: LibPQ.Notify -> Pqi.Notify
fromNotify notification =
  Pqi.Notify
    { Pqi.relname = LibPQ.notifyRelname notification,
      Pqi.bePid = fromIntegral (LibPQ.notifyBePid notification),
      Pqi.extra = LibPQ.notifyExtra notification
    }

toFormat :: Pqi.Format -> LibPQ.Format
toFormat = \case
  Pqi.Text -> LibPQ.Text
  Pqi.Binary -> LibPQ.Binary

fromFormat :: LibPQ.Format -> Pqi.Format
fromFormat = \case
  LibPQ.Text -> Pqi.Text
  LibPQ.Binary -> Pqi.Binary

fromExecStatus :: LibPQ.ExecStatus -> Pqi.ExecStatus
fromExecStatus = \case
  LibPQ.EmptyQuery -> Pqi.EmptyQuery
  LibPQ.CommandOk -> Pqi.CommandOk
  LibPQ.TuplesOk -> Pqi.TuplesOk
  LibPQ.CopyOut -> Pqi.CopyOut
  LibPQ.CopyIn -> Pqi.CopyIn
  LibPQ.CopyBoth -> Pqi.CopyBoth
  LibPQ.BadResponse -> Pqi.BadResponse
  LibPQ.NonfatalError -> Pqi.NonfatalError
  LibPQ.FatalError -> Pqi.FatalError
  LibPQ.SingleTuple -> Pqi.SingleTuple
  LibPQ.PipelineSync -> Pqi.PipelineSync
  LibPQ.PipelineAbort -> Pqi.PipelineAbort

fromConnStatus :: LibPQ.ConnStatus -> Pqi.ConnStatus
fromConnStatus = \case
  LibPQ.ConnectionOk -> Pqi.ConnectionOk
  LibPQ.ConnectionBad -> Pqi.ConnectionBad
  LibPQ.ConnectionStarted -> Pqi.ConnectionStarted
  LibPQ.ConnectionMade -> Pqi.ConnectionMade
  LibPQ.ConnectionAwaitingResponse -> Pqi.ConnectionAwaitingResponse
  LibPQ.ConnectionAuthOk -> Pqi.ConnectionAuthOk
  LibPQ.ConnectionSetEnv -> Pqi.ConnectionSetEnv
  LibPQ.ConnectionSSLStartup -> Pqi.ConnectionSSLStartup

fromTransactionStatus :: LibPQ.TransactionStatus -> Pqi.TransactionStatus
fromTransactionStatus = \case
  LibPQ.TransIdle -> Pqi.TransIdle
  LibPQ.TransActive -> Pqi.TransActive
  LibPQ.TransInTrans -> Pqi.TransInTrans
  LibPQ.TransInError -> Pqi.TransInError
  LibPQ.TransUnknown -> Pqi.TransUnknown

fromPollingStatus :: LibPQ.PollingStatus -> Pqi.PollingStatus
fromPollingStatus = \case
  LibPQ.PollingFailed -> Pqi.PollingFailed
  LibPQ.PollingReading -> Pqi.PollingReading
  LibPQ.PollingWriting -> Pqi.PollingWriting
  LibPQ.PollingOk -> Pqi.PollingOk

fromPipelineStatus :: LibPQ.PipelineStatus -> Pqi.PipelineStatus
fromPipelineStatus = \case
  LibPQ.PipelineOn -> Pqi.PipelineOn
  LibPQ.PipelineOff -> Pqi.PipelineOff
  LibPQ.PipelineAborted -> Pqi.PipelineAborted

fromFlushStatus :: LibPQ.FlushStatus -> Pqi.FlushStatus
fromFlushStatus = \case
  LibPQ.FlushOk -> Pqi.FlushOk
  LibPQ.FlushFailed -> Pqi.FlushFailed
  LibPQ.FlushWriting -> Pqi.FlushWriting

fromCopyInResult :: LibPQ.CopyInResult -> Pqi.CopyInResult
fromCopyInResult = \case
  LibPQ.CopyInOk -> Pqi.CopyInOk
  LibPQ.CopyInError -> Pqi.CopyInError
  LibPQ.CopyInWouldBlock -> Pqi.CopyInWouldBlock

fromCopyOutResult :: LibPQ.CopyOutResult -> Pqi.CopyOutResult
fromCopyOutResult = \case
  LibPQ.CopyOutRow value -> Pqi.CopyOutRow value
  LibPQ.CopyOutWouldBlock -> Pqi.CopyOutWouldBlock
  LibPQ.CopyOutDone -> Pqi.CopyOutDone
  LibPQ.CopyOutError -> Pqi.CopyOutError

toVerbosity :: Pqi.Verbosity -> LibPQ.Verbosity
toVerbosity = \case
  Pqi.ErrorsTerse -> LibPQ.ErrorsTerse
  Pqi.ErrorsDefault -> LibPQ.ErrorsDefault
  Pqi.ErrorsVerbose -> LibPQ.ErrorsVerbose

fromVerbosity :: LibPQ.Verbosity -> Pqi.Verbosity
fromVerbosity = \case
  LibPQ.ErrorsTerse -> Pqi.ErrorsTerse
  LibPQ.ErrorsDefault -> Pqi.ErrorsDefault
  LibPQ.ErrorsVerbose -> Pqi.ErrorsVerbose

toFieldCode :: Pqi.FieldCode -> LibPQ.FieldCode
toFieldCode = \case
  Pqi.DiagSeverity -> LibPQ.DiagSeverity
  Pqi.DiagSqlstate -> LibPQ.DiagSqlstate
  Pqi.DiagMessagePrimary -> LibPQ.DiagMessagePrimary
  Pqi.DiagMessageDetail -> LibPQ.DiagMessageDetail
  Pqi.DiagMessageHint -> LibPQ.DiagMessageHint
  Pqi.DiagStatementPosition -> LibPQ.DiagStatementPosition
  Pqi.DiagInternalPosition -> LibPQ.DiagInternalPosition
  Pqi.DiagInternalQuery -> LibPQ.DiagInternalQuery
  Pqi.DiagContext -> LibPQ.DiagContext
  Pqi.DiagSourceFile -> LibPQ.DiagSourceFile
  Pqi.DiagSourceLine -> LibPQ.DiagSourceLine
  Pqi.DiagSourceFunction -> LibPQ.DiagSourceFunction
