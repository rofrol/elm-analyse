module Analyser.Messages.Types exposing (..)

import AST.Ranges exposing (Range)
import AST.Types as AST


type alias MessageId =
    Int


type alias Sha1 =
    String


type alias FileName =
    String


type alias Message =
    { id : MessageId
    , status : MessageStatus
    , files : List ( Sha1, FileName )
    , data : MessageData
    }


newMessage : List ( Sha1, FileName ) -> MessageData -> Message
newMessage =
    Message 0 Applicable


type MessageStatus
    = Outdated
    | Blocked
    | Fixing
    | Applicable


type MessageData
    = UnreadableSourceFile FileName
    | UnusedVariable FileName String Range
    | UnusedTopLevel FileName String Range
    | UnusedImportedVariable FileName String Range
    | UnusedPatternVariable FileName String Range
    | ExposeAll FileName Range
    | ImportAll FileName AST.ModuleName Range
    | NoTopLevelSignature FileName String Range
    | UnnecessaryParens FileName Range
    | DebugLog FileName Range
    | DebugCrash FileName Range
    | UnformattedFile FileName
    | FileLoadFailed FileName String
    | DuplicateImport FileName AST.ModuleName (List Range)
    | UnusedTypeAlias FileName String Range
    | RedefineVariable FileName String Range Range
    | NoUncurriedPrefix FileName String Range
    | UnusedImportAlias FileName AST.ModuleName Range
    | UnusedImport FileName AST.ModuleName Range
    | UseConsOverConcat FileName Range
    | DropConcatOfLists FileName Range
    | DropConsOfItemAndList FileName Range
    | UnnecessaryListConcat FileName Range
    | LineLengthExceeded FileName (List Range)
    | MultiLineRecordFormatting FileName Range
    | UnnecessaryPortModule FileName
    | NonStaticRegex FileName Range
    | CoreArrayUsage FileName Range
    | FunctionInLet FileName Range


type alias GetFiles =
    MessageData -> List FileName
