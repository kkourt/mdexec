-- Execute shell scripts in markdown files using pandoc.
-- Kornilios Kourtis <kornilios@gmail.com>
--

import System.Environment (getArgs)
import System.Exit (ExitCode, exitWith)
import qualified System.Process as SP
import qualified System.IO as SIO

import qualified Data.Text as T
import qualified Data.List as L
import qualified Data.Text.IO as T.IO
import qualified Text.Pandoc as P
import qualified Text.Pandoc.Options as P.Options
import qualified Text.Pandoc.Extensions as P.Extensions
import qualified Text.Pandoc.Walk as P.Walk

lookupAttrs :: String -> P.Attr -> Maybe String
lookupAttrs k (_, _, kv_attrs) = L.lookup k kv_attrs

queryCode (P.CodeBlock attrs txt) =
    case lookupAttrs "exec" attrs of
        Just x  -> [(x, txt)]
        Nothing -> []
queryCode _ = []

queryDoc :: P.Pandoc -> [(String, String)]
queryDoc = P.Walk.query queryCode

findCode :: String -> P.Pandoc -> Maybe String
findCode v d = L.lookup v $ queryDoc d

execCode :: String -> IO ExitCode
execCode txt = do
    let cp = SP.CreateProcess {
        SP.cmdspec = SP.RawCommand "/bin/sh" ["-s"],
        SP.cwd = Nothing,
        SP.env = Nothing,
        SP.std_in = SP.CreatePipe,
        SP.std_out = SP.Inherit,
        SP.std_err = SP.Inherit,
        SP.close_fds = False,
        SP.create_group = False,
        SP.delegate_ctlc = False,
        SP.detach_console = False,
        SP.create_new_console = False,
        SP.new_session = False,
        SP.child_group = Nothing,
        SP.child_user = Nothing,
        SP.use_process_jobs = False
    }

    (Just hin, Nothing, Nothing, ph) <- SP.createProcess cp

    SIO.hPutStr hin txt
    SIO.hFlush hin
    SIO.hClose hin

    SP.waitForProcess ph

main :: IO ()
main = do

    args <- getArgs
    (fname, execval) <- case args of
        [x1, x2] -> return (x1, x2)
        _ -> error "Usage: <fname> <execval>"

    txt <- T.IO.readFile fname

    res <- P.runIOorExplode $ do
        let rdOpts = P.def {
            P.Options.readerExtensions = P.Extensions.pandocExtensions
        }
        doc <- P.readMarkdown rdOpts txt
        return $ findCode execval doc
    txt <- case res of
        Just x -> return x
        Nothing -> error $ "Code with exec=" ++ execval ++ " not found"

    err <- execCode txt
    exitWith err
